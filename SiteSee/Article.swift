//
//  Article.swift
//  SiteSee
//
//  Created by Tom Lai on 3/23/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import Foundation
import CoreData

class Article: NSManagedObject {
    
    struct Keys {
        static let Title = "title"
        static let Subtitle = "subtitle"
        static let Url = "url"
        static let SortOrder = "sortOrder"
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(dictionary: [String:AnyObject?], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Article", in: context)!
        super.init(entity: entity, insertInto: context)
        
        title = dictionary[Keys.Title] as? String
        subtitle = dictionary[Keys.Subtitle] as? String
        url = dictionary[Keys.Url] as? String
        sortOrder = dictionary[Keys.SortOrder] as? NSNumber
    }
}
