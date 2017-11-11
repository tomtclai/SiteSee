//
//  Image.swift
//  SiteSee
//
//  Created by Tom Lai on 3/23/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import Foundation
import CoreData


class Image: NSManagedObject {

    struct Keys {
        static let ThumbnailUrl = "thumbnailUrl"
        static let UUID = "uuid"
        static let FlickrPageUrl = "flickrPageUrl"
        static let SortOrder = "sortOrder"
        static let OrigImageUrl = "origImageUrl"
        static let OwnerName = "ownerName"
        static let License = "license"
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(dictionary: [String:AnyObject?], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Image", in: context)!
        super.init(entity: entity, insertInto: context)
        
        thumbnailUrl = dictionary[Keys.ThumbnailUrl] as? String
        flickrPageUrl = dictionary[Keys.FlickrPageUrl] as? String
        uuid = dictionary[Keys.UUID] as? String
        sortOrder = dictionary[Keys.SortOrder] as? Double as! NSNumber
        origImageUrl = dictionary[Keys.OrigImageUrl] as? String
        ownerName = dictionary[Keys.OwnerName] as? String
        license = dictionary[Keys.License] as? NSNumber
    }
    
    override func prepareForDeletion() {
        if let uuid = uuid {
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            let imgPath = documentDirectory.appendingPathComponent(uuid) + ".jpg"
            do {
                try FileManager.default.removeItem(atPath: imgPath)
            } catch {
                print("rm file error")
            }
        }
    }
    
    static func imgPath(_ uuid: String) -> String{
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        return documentDirectory.appendingPathComponent(uuid) + ".jpg"
    }
}
