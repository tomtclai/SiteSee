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
  func getOwnerName(_ methodArguments: [String : AnyObject], completionHandler: @escaping (_ ownerName: String?, _ error: NSError?)-> Void) {
    let session = URLSession.shared
    let urlString = Constants.baseUrl + escapedParameters(methodArguments)
    let url = URL(string: urlString)!
    let request = URLRequest(url: url)

    let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
      guard error == nil else {
        completionHandler(nil, NSError(domain: "getOwnerName", code: 9999, userInfo: [NSLocalizedDescriptionKey:error!.localizedDescription]))
        return
      }
      /* GUARD: Did we get a successful 2XX response? */
      guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
        if let response = response as? HTTPURLResponse {
          completionHandler(nil, NSError(domain: "getOwnerName", code: 9999, userInfo: [NSLocalizedDescriptionKey: response.description]))
        } else if let response = response {
          completionHandler(nil, NSError(domain: "getOwnerName", code: 9999, userInfo: [NSLocalizedDescriptionKey: response.description]))
        } else {
          completionHandler(nil, NSError(domain: "getOwnerName", code: 9999, userInfo: [NSLocalizedDescriptionKey: "Server returned an invalid response"]))
        }
        return
      }

      /* GUARD: Was there any data returned? */
      guard let data = data else {
        completionHandler(nil, NSError(domain: "getOwnerName", code: 9999, userInfo: [NSLocalizedDescriptionKey: "No data was returned by the request"]))
        return
      }
      /* Parse the data! */
      let parsedResult: [String: Any]

      do {
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          completionHandler(nil, NSError(domain: "getOwnerName", code: 9999, userInfo: [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]))
          return
        }
        parsedResult = dictionary
      } catch {
        completionHandler(nil, NSError(domain: "getOwnerName", code: 9999, userInfo: [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]))
        return
      }


      /* GUARD: Did Flickr return an error (stat != ok)? */
      guard let stat = parsedResult["stat"] as? String, stat == "ok" else {
        completionHandler(nil, NSError(domain: "getOwnerName", code: 9999, userInfo: [NSLocalizedDescriptionKey:"Flickr API returned an error. See error code and message in \(parsedResult)"]))

        return
      }

      /* GUARD: Is the "photos" key in our result? */

      guard let personDict = parsedResult["person"] as? NSDictionary else {

        completionHandler(nil, NSError(domain: "getOwnerName", code: 9999, userInfo: [NSLocalizedDescriptionKey:"Cannot find key 'person' in \(parsedResult)"]))
        return
      }

      if let realNameDict = personDict["realname"] as? NSDictionary {
        guard let ownerName = realNameDict["_content"] as? String else {

          completionHandler(nil, NSError(domain: "getOwnerName", code: 9999, userInfo: [NSLocalizedDescriptionKey:"Cannot find key '_content' in \(realNameDict)"]))
          return
        }

        completionHandler(ownerName, nil)
        return
      } else if let userNameDict = personDict["username"] as? NSDictionary {
        guard let ownerName = userNameDict["_content"] as? String else {

          completionHandler(nil, NSError(domain: "getOwnerName", code: 9999, userInfo: [NSLocalizedDescriptionKey:"Cannot find key '_content' in \(userNameDict)"]))
          return
        }
        completionHandler(ownerName, nil)
      }


    })
    task.resume()
  }
  /* Function makes first request to get a random page, then it makes a request to get an image with the random page */
  func getImageFromFlickrBySearch(_ methodArguments: [String : AnyObject], completionHandler: @escaping (_ stat:String?, _ photosDict:NSDictionary?, _ totalPages:Int?, _ error:NSError?) -> Void) {

    let session = URLSession.shared
    let urlString = Constants.baseUrl + escapedParameters(methodArguments)
    let url = URL(string: urlString)!
    let request = URLRequest(url: url)

    let task = session.dataTask(with: request, completionHandler: { (data, response, error) in

      /* GUARD: Was there an error? */
      guard (error == nil) else {
        completionHandler(nil , nil, nil, NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: error!.localizedDescription]))
        return
      }

      /* GUARD: Did we get a successful 2XX response? */
      guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
        if let response = response as? HTTPURLResponse {
          completionHandler(nil , nil, nil, NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: response.description]))
        } else if let response = response {
          completionHandler(nil , nil, nil, NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: response.description]))
        } else {
          completionHandler(nil , nil, nil, NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Server returned an invalid response"]))
        }
        return
      }

      /* GUARD: Was there any data returned? */
      guard let data = data else {
        completionHandler(nil , nil, nil, NSError(domain: "getArticleFromWikipediaBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data was returned by the request"]))
        return
      }
      /* Parse the data! */
      let parsedResult: [String: Any]

      do {

        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          completionHandler(nil, nil, nil , NSError(domain: "getImageFromFlickrBySearch", code: 9999, userInfo: [NSLocalizedDescriptionKey: "Could not convert to dictionary '\(data)'"]))
          return
        }
        parsedResult = dictionary
      } catch {

        completionHandler(nil, nil, nil, NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]))
        return
      }

      /* GUARD: Did Flickr return an error? */
      guard let stat = parsedResult["stat"] as? String, stat == "ok" else {
        completionHandler(nil, nil, nil, NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Flickr API returned an error. See error code and message in \(parsedResult)"]))
        return
      }

      /* GUARD: Is "photos" key in our result? */
      guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
        print("Cannot find keys 'photos' in \(parsedResult)")
        completionHandler(nil, nil, nil, NSError(domain: "getImageFromFlickrBySearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot find keys 'photos' in \(parsedResult)"]))
        return
      }

      /* GUARD: Is "pages" key in the photosDictionary? */
      guard let totalPages = photosDictionary["pages"] as? Int else {
        print("Cannot find key 'pages' in \(photosDictionary)")
        completionHandler(nil, nil, nil, NSError(domain: "getImageFromFlickrBySearch", code: 0,  userInfo: [NSLocalizedDescriptionKey: "Cannot find key 'pages' in \(photosDictionary)"]))
        return
      }

      /* Pick a page! */
      completionHandler(stat, photosDictionary, totalPages, nil)

    })

    task.resume()
  }

  func getImageFromFlickrBySearchWithPage(_ methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: @escaping (_ stat: String?, _ photosDictionary: NSDictionary?, _ totalPhotosVal: Int?, _ error: NSError?) -> Void) {

    /* Add the page to the method's arguments */
    var withPageDictionary = methodArguments
    withPageDictionary["page"] = pageNumber as AnyObject

    let session = URLSession.shared
    let urlString = Constants.baseUrl + escapedParameters(withPageDictionary)
    let url = URL(string: urlString)!
    let request = URLRequest(url: url)

    let task = session.dataTask(with: request, completionHandler: { (data, response, error) in

      /* GUARD: Was there an error? */
      guard (error == nil) else {
        completionHandler(nil, nil, nil, NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                                                 userInfo: [NSLocalizedDescriptionKey:"There was an error with your request: \(String(describing: error))"]))
        return
      }

      /* GUARD: Did we get a successful 2XX response? */
      guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
        if let response = response as? HTTPURLResponse {
          completionHandler(nil, nil, nil, NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                                                   userInfo: [NSLocalizedDescriptionKey:"Your request returned an invalid response! Status code: \(response.statusCode)!"]))
        } else if let response = response {

          completionHandler(nil, nil, nil, NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                                                   userInfo: [NSLocalizedDescriptionKey:"Your request returned an invalid response! Response: \(response)!"]))
        } else {
          print("Your request returned an invalid response!")
        }
        return
      }

      /* GUARD: Was there any data returned? */
      guard let data = data else {
        completionHandler(nil, nil, nil, NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                                                 userInfo: [NSLocalizedDescriptionKey:"No data was returned by the request!"]))
        return
      }


      /* Parse the data! */
      let parsedResult: [String: Any]
      do {
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          completionHandler(nil, nil, nil , NSError(domain: "getImageFromFlickrBySearchWithPage", code: 9999, userInfo: [NSLocalizedDescriptionKey: "Could not convert to dictionary '\(data)'"]))
          return
        }
        parsedResult = dictionary
      } catch {
        completionHandler(nil, nil, nil, NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                                                 userInfo: [NSLocalizedDescriptionKey:"Could not parse the data as JSON: '\(data)'"]))
        return
      }

      /* GUARD: Did Flickr return an error (stat != ok)? */
      guard let stat = parsedResult["stat"] as? String, stat == "ok" else {
        completionHandler(nil, nil, nil, NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                                                 userInfo: [NSLocalizedDescriptionKey:"Flickr API returned an error. See error code and message in \(parsedResult)"]))

        return
      }

      /* GUARD: Is the "photos" key in our result? */
      guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {

        completionHandler(stat, nil, nil, NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                                                  userInfo: [NSLocalizedDescriptionKey:"Cannot find key 'photos' in \(parsedResult)"]))
        return
      }

      /* GUARD: Is the "total" key in photosDictionary? */
      guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
        completionHandler(stat, photosDictionary, nil, NSError(domain: "getImageFromFlickrBySearchWithPage", code: 0,
                                                               userInfo: [NSLocalizedDescriptionKey:"Cannot find key 'total' in \(photosDictionary)"]))
        return
      }

      completionHandler(stat, photosDictionary, totalPhotosVal, nil)
    })

    task.resume()
  }


}
// MARK: Convenience methods
extension Flickr {
  func getSearchPhotoMethodArgumentsConvenience(_ text: String, perPage:Int) -> [String:AnyObject]{
    let EXTRAS = "url_b,url_q,url_o,license"
    let SAFE_SEARCH = "1"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    let methodArguments : [String:AnyObject] = [
      "method": Flickr.Resources.searchPhotos as AnyObject,
      "api_key": Flickr.Constants.apiKey as AnyObject,
      "safe_search": SAFE_SEARCH as AnyObject,
      "extras": EXTRAS as AnyObject,
      "format": DATA_FORMAT as AnyObject,
      "nojsoncallback": NO_JSON_CALLBACK as AnyObject,
      "text": text as AnyObject,
      "per_page": perPage as AnyObject,
      "license": "1,2,3,4,5,6,7,8" as AnyObject
    ]
    return methodArguments
  }
  func getPeopleSearchArgumentsConvenience(_ userId: String) -> [String:AnyObject]{
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    let methodArguments : [String:AnyObject] = [
      "method": Flickr.Resources.getPeopleInfo as AnyObject,
      "api_key": Flickr.Constants.apiKey as AnyObject,
      "user_id": userId as AnyObject,
      "format": DATA_FORMAT as AnyObject,
      "nojsoncallback": NO_JSON_CALLBACK as AnyObject,

      ]
    return methodArguments
  }
  func getImageFromFlickrWithPageConvenience(_ methodArguments: [String:AnyObject], pageNumber:Int, completionHandler:@escaping (_ thumbnailUrl: String?, _ origImageUrl: String?, _ flickrPageUrl: String?, _ ownerName: String?, _ license: Int?, _ error: NSError?)->Void) {
    Flickr.sharedInstance().getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: pageNumber, completionHandler: { (stat, photosDictionary, totalPhotosVal, error) -> Void in
      guard error == nil else {
        print(String(describing: error?.localizedDescription))
        return
      }

      if totalPhotosVal! > 0 {
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

          //use owner ID to find owner real name
          guard let ownerIDStr = photoDictionary["owner"] as? String else {
            print("Cannot find key 'owner' in \(photoDictionary)")
            return
          }

          // use Photo ID and OwnerID to make URL
          guard let photoID = photoDictionary["id"] as? String else {
            print("Cannot find key 'id' in \(photoDictionary)")
            return
          }

          // can be nil
          let originalImageUrlStr = photoDictionary["url_o"] as? String

          guard let license = photoDictionary["license"]?.integerValue else {
            print("cannot find key license in \(photoDictionary) ")
            return
          }

          self.getOwnerName(self.getPeopleSearchArgumentsConvenience(ownerIDStr), completionHandler: { (ownerName, error) in
            guard error == nil else {
              completionHandler(thumbnailUrlStr, originalImageUrlStr, Constants.webPageUrlForPhoto(ownerIDStr, photoID: photoID), nil, license, NSError(domain: "getOwnerName", code: 9999, userInfo: [NSLocalizedDescriptionKey: error!.localizedDescription]))
              print("no real name")
              return
            }
            completionHandler(thumbnailUrlStr, originalImageUrlStr, Constants.webPageUrlForPhoto(ownerIDStr, photoID: photoID), ownerName, license, nil)
          })

        }
      } else {
        completionHandler(nil, nil, nil, nil, nil, NSError(domain: "getImageFromFlickrConvenience", code: 999, userInfo:[ NSLocalizedDescriptionKey: "No photos here"]))

      }
    })
  }
  func getCellImageConvenience(_ url:String, completion: @escaping ((_ data: Data) -> Void)) {
    self.downloadImage(url, completion: { (data, response, error) -> Void in
      /* GUARD: Was there an error? */
      if let error = error {
        print("There was an error with your request: \(error)")
        return
      }

      /* GUARD: Did we get a successful 2XX response? */
      guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
        if let response = response as? HTTPURLResponse {
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
      DispatchQueue.main.async{
        completion(data)
      }
    })
  }
}
