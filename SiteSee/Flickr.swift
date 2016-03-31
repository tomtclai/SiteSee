//
//  Flickr.swift
//  SiteSee
//
//  Created by Tom Lai on 1/31/16.
//  Copyright © 2016 Lai. All rights reserved.
//
// Input : Name of location
// Output : list of images

import Foundation

class Flickr : Model {
    // MARK: Shared Instance
    class func sharedInstance() -> Flickr {
        struct Singleton {
            static var sharedInstance = Flickr()
        }
        return Singleton.sharedInstance
    }
    
    /* Function makes first request to get a random page, then it makes a request to get an image with the random page */
    func getImageFromFlickrBySearch(methodArguments: [String : AnyObject], completionHandler: (stat:String?, photosDict:NSDictionary?, totalPages:Int?, error:NSError?) -> Void) {
        
        let session = NSURLSession.sharedSession()
        let urlString = Constants.baseUrl + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(stat: nil , photosDict:nil, totalPages: nil, error: NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: error!.localizedDescription]))
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    completionHandler(stat: nil , photosDict:nil, totalPages: nil, error: NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: response.description]))
                } else if let response = response {
                    completionHandler(stat: nil , photosDict:nil, totalPages: nil, error: NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: response.description]))
                } else {
                    completionHandler(stat: nil , photosDict:nil, totalPages: nil, error: NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Server returned an invalid response"]))
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandler(stat: nil , photosDict:nil, totalPages: nil, error: NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data was returned by the request"]))
                return
            }
            /* Parse the data! */
            let parsedResult: AnyObject!
            
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                
                completionHandler(stat: nil, photosDict: nil, totalPages: nil, error: NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]))
                return
            }
            
            /* GUARD: Did Flickr return an error? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                completionHandler(stat: nil, photosDict: nil, totalPages: nil, error: NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Flickr API returned an error. See error code and message in \(parsedResult)"]))
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find keys 'photos' in \(parsedResult)")
                completionHandler(stat: nil, photosDict: nil, totalPages: nil, error: NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot find keys 'photos' in \(parsedResult)"]))
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary["pages"] as? Int else {
                print("Cannot find key 'pages' in \(photosDictionary)")
                completionHandler(stat: nil, photosDict: nil, totalPages: nil, error: NSError(domain: "getImageFromFlickrBySearch", code: 0,  userInfo: [NSLocalizedDescriptionKey: "Cannot find key 'pages' in \(photosDictionary)"]))
                return
            }
            
            /* Pick a page! */
            completionHandler(stat: stat, photosDict: photosDictionary, totalPages: totalPages, error: nil)
            
        }
        
        task.resume()
    }
    
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: (stat: String?, photosDictionary: NSDictionary?, totalPhotosVal: Int?, error: NSError?) -> Void) {
        
        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = Constants.baseUrl + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(stat: nil, photosDictionary: nil, totalPhotosVal: nil, error: NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                    userInfo: [NSLocalizedDescriptionKey:"There was an error with your request: \(error)"]))
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    completionHandler(stat: nil, photosDictionary: nil, totalPhotosVal: nil, error: NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                        userInfo: [NSLocalizedDescriptionKey:"Your request returned an invalid response! Status code: \(response.statusCode)!"]))
                } else if let response = response {
                    
                    completionHandler(stat: nil, photosDictionary: nil, totalPhotosVal: nil, error: NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                        userInfo: [NSLocalizedDescriptionKey:"Your request returned an invalid response! Response: \(response)!"]))
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandler(stat: nil, photosDictionary: nil, totalPhotosVal: nil, error: NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                    userInfo: [NSLocalizedDescriptionKey:"No data was returned by the request!"]))
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                completionHandler(stat: nil, photosDictionary: nil, totalPhotosVal: nil, error: NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                    userInfo: [NSLocalizedDescriptionKey:"Could not parse the data as JSON: '\(data)'"]))
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                completionHandler(stat: nil, photosDictionary: nil, totalPhotosVal: nil, error: NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                    userInfo: [NSLocalizedDescriptionKey:"Flickr API returned an error. See error code and message in \(parsedResult)"]))
                
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                
                completionHandler(stat: stat, photosDictionary: nil, totalPhotosVal: nil, error: NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                    userInfo: [NSLocalizedDescriptionKey:"Cannot find key 'photos' in \(parsedResult)"]))
                return
            }
            
            /* GUARD: Is the "total" key in photosDictionary? */
            guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                completionHandler(stat: stat, photosDictionary: photosDictionary, totalPhotosVal: nil, error: NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                    userInfo: [NSLocalizedDescriptionKey:"Cannot find key 'total' in \(photosDictionary)"]))
                return
            }
            
            completionHandler(stat: stat, photosDictionary: photosDictionary, totalPhotosVal: totalPhotosVal, error: nil)
        }
        
        task.resume()
    }
    
    
}
// MARK: Convenience methods
extension Flickr {
    func getSearchMethodArgumentsConvenience(text: String, perPage:Int) -> [String:AnyObject]{
        let EXTRAS = "url_b,url_q,url_o,license"
        let SAFE_SEARCH = "1"
        let DATA_FORMAT = "json"
        let NO_JSON_CALLBACK = "1"
        let methodArguments : [String:AnyObject] = [
            "method": Flickr.Resources.search,
            "api_key": Flickr.Constants.apiKey,
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "text": text,
            "per_page": perPage,
            "license": "6,7,8"
        ]
        return methodArguments
    }
    func getImageFromFlickrWithPageConvenience(methodArguments: [String:AnyObject], pageNumber:Int, completionHandler:(thumbnailUrl: String?, imageUrl: String?, origImageUrl: String?, error: NSError?)->Void) {
        Flickr.sharedInstance().getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: pageNumber, completionHandler: { (stat, photosDictionary, totalPhotosVal, error) -> Void in
            guard error == nil else {
                print(error?.localizedDescription)
                return
            }
            
            if totalPhotosVal > 0 {
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary!["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find key 'photo' in \(photosDictionary)")
                    return
                }
                for photoDictionary in photosArray {
                    
                    /* GUARD: Does our photo have a key for 'url_m'? */
                    guard let thumbnailUrlStr = photoDictionary["url_q"] as? String else {
                        print("Cannot find key 'url_q' in \(photoDictionary)")
                        return
                    }
                    
                    
                    guard let imageUrlStr = photoDictionary["url_q"] as? String else {
                        print("Cannot find key 'url_q' in \(photoDictionary)")
                        return
                    }
                    
                    if let originalImageUrlStr = photoDictionary["url_o"] as? String {
                        completionHandler(thumbnailUrl: thumbnailUrlStr, imageUrl: imageUrlStr, origImageUrl: originalImageUrlStr, error: nil)
                    } else {
                        completionHandler(thumbnailUrl: thumbnailUrlStr, imageUrl: imageUrlStr, origImageUrl: nil, error: nil)
                    }
                    
                }
            } else {
                completionHandler(thumbnailUrl: nil, imageUrl: nil, origImageUrl: nil, error: NSError(domain: "getImageFromFlickrConvenience", code: 999, userInfo: nil))
                
            }
        })
    }
    func getCellImageConvenience(url:String, completion: ((data: NSData) -> Void)) {
        self.downloadImage(url, completion: { (data, response, error) -> Void in
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
            completion(data: data)
        })
    }
}