//
//  Wikipedia.swift
//  SiteSee
//
//  Created by Tom Lai on 3/22/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import Foundation
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
    
    func getArticleFromWikipediaBySearch(methodArguments: [String : AnyObject], completionHandler: (stat: String?, articleDict: NSDictionary?, error: NSError?) -> Void) {
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
                
                completionHandler(stat: nil, articleDict: nil , error: NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]))
                return
            }

        }
        task.resume()
    }
}