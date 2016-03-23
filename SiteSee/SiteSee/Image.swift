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
        static let ImageUrl = "imageUrl"
        static let ThumbnailUrl = "thumbnailUrl"
        static let UUID = "uuid"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String:AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Image", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        imageUrl = dictionary[Keys.ImageUrl] as? String
        thumbnailUrl = dictionary[Keys.ThumbnailUrl] as? String
        uuid = dictionary[Keys.UUID] as? String
    }
    
    override func prepareForDeletion() {
        if let uuid = uuid {
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
            let imgPath = documentDirectory.stringByAppendingPathComponent(uuid).stringByAppendingString(".jpg")
            do {
                try NSFileManager.defaultManager().removeItemAtPath(imgPath)
            } catch {
                print("rm file error")
            }
        }
    }
    
    static func imgPath(uuid: String) -> String{
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        return documentDirectory.stringByAppendingPathComponent(uuid).stringByAppendingString(".jpg")
    }
}
