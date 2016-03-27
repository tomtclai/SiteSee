//
//  Model.swift
//  SiteSee
//
//  Created by Tom Lai on 3/22/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import Foundation
class Model : NSObject {
    typealias CompletionHandler = (result: AnyObject!, error: NSError) -> Void
    var session: NSURLSession
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    // MARK: Escape HTML Parameters
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    // MARK: Convenience
    func getDataFromUrl(url: NSURL, completion: ((data:NSData?, response: NSURLResponse?, error: NSError?) ->Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) {
            completion(data: $0, response: $1, error: $2)
            }.resume()
    }
    func downloadImage(url: String, completion:(data:NSData?, response: NSURLResponse?, error: NSError?) ->Void) {
        getDataFromUrl(NSURL(string: url)!) {
            completion(data: $0, response: $1, error: $2)
        }
    }
}