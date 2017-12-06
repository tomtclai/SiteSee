//
//  Flickr-Constants.swift
//  SiteSee
//
//  Created by Tom Lai on 1/31/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import Foundation

extension Flickr {
    struct Constants {
        static let baseUrl = "https://api.flickr.com/services/rest/"
        static let apiKey = FlickrSecretAPIKey // Not to be shared on a public repo
        static func webPageUrlForPhoto(_ userID: String, photoID: String) -> String {
            var url = "https://www.flickr.com/photos/"
            url.append(userID)
            url.append("/")
            url.append(photoID)
            return url
        }
        static func licenseUrl(_ licenseID: Int) -> String? {
            // TODO: use the API function to get these
            switch licenseID {
            case 1:
                return "http://creativecommons.org/licenses/by-nc-sa/2.0/"
            case 2:
                return "http://creativecommons.org/licenses/by-nc/2.0/"
            case 3:
                return "http://creativecommons.org/licenses/by-nc-nd/2.0/"
            case 4:
                return "http://creativecommons.org/licenses/by/2.0/"
            case 5:
                return "http://creativecommons.org/licenses/by-sa/2.0/"
            case 6:
                return "http://creativecommons.org/licenses/by-nd/2.0/"
            case 7:
                return "http://flickr.com/commons/usage/"
            case 8:
                return "http://www.usa.gov/copyright.shtml"
            default:
                return nil
            }
        }
        static func licenseName(_ licenseID: Int) -> String? {
            // TODO: use the API function to get these
            switch licenseID {
            case 1:
                return "Attribution-NonCommercial-ShareAlike"
            case 2:
                return "Attribution-NonCommercial"
            case 3:
                return "Attribution-NonCommercial-NoDerivs"
            case 4:
                return "Attribution"
            case 5:
                return "Attribution-ShareAlike"
            case 6:
                return "Attribution-NoDerivs"
            case 7:
                return "No known copyright restrictions"
            case 8:
                return "United States Government Work"
            default:
                return nil
            }
        }
    }
    
    struct Resources {
        static let searchPhotos = "flickr.photos.search"
        static let getPeopleInfo = "flickr.people.getInfo"
    }
}
