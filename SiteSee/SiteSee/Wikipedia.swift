//
//  Wikipedia.swift
//  SiteSee
//
//  Created by Tom Lai on 3/22/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import Foundation
import UIKit
// Input : coordinates
// Output : list of articles with title and link and description
class Wikipedia : Model {

    // MARK: Shared Instance
    class func sharedInstance() -> Wikipedia {
        struct Singleton {
            static var sharedInstance = Wikipedia()
        }
        return Singleton.sharedInstance
    }
    
    func stripHTMLTags(htmlString: String) -> String {
        let data = htmlString.dataUsingEncoding(NSUTF8StringEncoding)!

        let option : [String:AnyObject] = [
            NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
        ]
        var attr = NSAttributedString()
        do {
            try attr = NSAttributedString(data: data, options: option, documentAttributes: nil)
        } catch {
        }
        return attr.string
    }
    
    func searchWikipediaByKeywords(methodArguments: [String : AnyObject], completionHandler: (resultsDict: NSArray?, error: NSError?) -> Void) {
        let session = NSURLSession.sharedSession()
        let urlString = Constants.baseUrl + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                
                completionHandler(resultsDict: nil , error: NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]))
                return
            }
            
            /* GUARD: Did Wiki return query? */
            guard let queryDict = parsedResult["query"] as? NSDictionary else {
                print("Cannot find key 'query'")
                completionHandler(resultsDict: nil , error: NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot find key 'query' in \(parsedResult)"]))
                return
            }
            
            /* GUARD: Is "search" key in the query? */
            guard let searchDictionary = queryDict["search"] as? NSArray else {
                print("Cannot find key 'query.search' in \(queryDict)")
                completionHandler(resultsDict: nil, error: NSError(domain: "getArticleFromWikipediaBySearch", code: 0,  userInfo: [NSLocalizedDescriptionKey: "Cannot find key 'query.search' in \(queryDict)"]))
                return
            }
            
            completionHandler(resultsDict: searchDictionary, error: error)
            

        }
        task.resume()
    }
}
// MARK: Convenience
extension Wikipedia {
    func getListOfArticles(methodArguments: [String : AnyObject], completionHandler: (title: String?, subtitle: String?, error: NSError?) -> Void) {
        searchWikipediaByKeywords(methodArguments) { (resultsDict, error) in
            guard error == nil else {
                print(error)
                return
            }
            guard let resultsDict = resultsDict else {
                print("resultsDict is nil")
                return
            }
            for resultDict in resultsDict {
                guard let title = resultDict["title"] as? String else {
                    print("no title")
                    completionHandler(title: nil, subtitle: nil, error: NSError(domain: "getListOfArticles", code: 0, userInfo: [NSLocalizedDescriptionKey: "no title in \(resultDict)"]))
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