//
//  Wikipedia.swift
//  SiteSee
//
//  Created by Tom Lai on 3/22/16.
//  Copyright © 2016 Lai. All rights reserved.
//
// Input : Name of location
// Output : list of articles with title, link and description


import Foundation
import UIKit

class Wikipedia : Model {

    // MARK: Shared Instance
    class func sharedInstance() -> Wikipedia {
        struct Singleton {
            static var sharedInstance = Wikipedia()
        }
        return Singleton.sharedInstance
    }
    
    func stripHTMLTags(_ htmlString: String) -> String {
        let data = htmlString.data(using: String.Encoding.utf8)!

        let option : [String:AnyObject] = [
            NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType as AnyObject,
            NSCharacterEncodingDocumentAttribute: String.Encoding.utf8 as AnyObject
        ]
        var attr = NSAttributedString()
        do {
            try attr = NSAttributedString(data: data, options: option, documentAttributes: nil)
        } catch {
        }
        return attr.string
    }
    
    func searchWikipediaByKeywords(_ methodArguments: [String : AnyObject], completionHandler: @escaping (_ resultsDict: NSArray?, _ error: NSError?) -> Void) {
        let session = URLSession.shared
        let urlString = Constants.baseUrl + escapedParameters(methodArguments)
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(nil , NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: error!.localizedDescription]))
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? HTTPURLResponse {
                    completionHandler(nil , NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: response.description]))
                } else if let response = response {
                    completionHandler(nil , NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: response.description]))
                } else {
                    completionHandler(nil , NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Server returned an invalid response"]))
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandler(nil , NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data was returned by the request"]))
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            } catch {
                parsedResult = nil
                completionHandler(nil , NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]))
                return
            }
            
            /* GUARD: Did Wiki return query? */
            guard let queryDict = parsedResult["query"] as? NSDictionary else {
                completionHandler(nil , NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot find key 'query' in \(parsedResult)"]))
                return
            }
            
            /* GUARD: Is "search" key in the query? */
            guard let searchDictionary = queryDict["search"] as? NSArray else {
                completionHandler(nil, NSError(domain: "getArticleFromWikipediaBySearch", code: 0,  userInfo: [NSLocalizedDescriptionKey: "Cannot find key 'query.search' in \(queryDict)"]))
                return
            }
            
            completionHandler(searchDictionary, error as! NSError)

        }) 
        task.resume()
    }
}
// MARK: Convenience methods
extension Wikipedia {
    func getListOfArticles(_ methodArguments: [String : AnyObject], completionHandler: @escaping (_ title: String?, _ subtitle: String?, _ error: NSError?) -> Void) {
        searchWikipediaByKeywords(methodArguments) { (resultsDict, error) in
            guard error == nil else {
                print(error)
                completionHandler(nil, nil, NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: error!.localizedDescription]))
                return
            }
            guard let resultsDict = resultsDict else {
                print("resultsDict is nil")
                completionHandler(nil, nil, NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: error!.localizedDescription]))
                return
            }
            for resultDict in resultsDict {
                guard let title = resultDict["title"] as? String else {
                    print("no title")
                    completionHandler(nil, nil, NSError(domain: "getListOfArticles", code: 0, userInfo: [NSLocalizedDescriptionKey: "no title in \(resultDict)"]))
                    return
                }
                guard var subtitle = resultDict["snippet"] as? String else {
                    print("no subtitle")
                    completionHandler(title: title, subtitle: nil, error: NSError(domain: "getListOfArticles", code: 0, userInfo: [NSLocalizedDescriptionKey: "no subtitle in \(resultDict)"]))
                    return
                }
                subtitle = self.stripHTMLTags(subtitle)
                
                completionHandler(title: title, subtitle: subtitle, error: nil)
                
            }
        }
    }
}
