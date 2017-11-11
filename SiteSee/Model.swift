//
//  Model.swift
//  SiteSee
//
//  Created by Tom Lai on 3/22/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import Foundation
class Model : NSObject {
    typealias CompletionHandler = (_ result: AnyObject?, _ error: NSError) -> Void
    var session: URLSession
    override init() {
        session = URLSession.shared
        super.init()
    }
    // MARK: Escape HTML Parameters
    func escapedParameters(_ parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joined(separator: "&")
    }
    // MARK: Convenience
    func getDataFromUrl(_ url: URL, completion: @escaping ((_ data:Data?, _ response: URLResponse?, _ error: NSError?) ->Void)) {
        URLSession.shared.dataTask(with: url, completionHandler: {
            completion($0, $1, $2 as? NSError)
            }) .resume()
    }
    func downloadImage(_ url: String, completion:@escaping (_ data:Data?, _ response: URLResponse?, _ error: NSError?) ->Void) {
        getDataFromUrl(URL(string: url)!) {
            completion($0, $1, $2)
        }
    }
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }

}
