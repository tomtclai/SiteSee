//
//  Image+CoreDataProperties.swift
//  SiteSee
//
//  Created by Tom Lai on 4/1/16.
//  Copyright © 2016 Lai. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Image {

    @NSManaged var origImageUrl: String?
    @NSManaged var sortOrder: NSNumber?
    @NSManaged var thumbnailUrl: String?
    @NSManaged var uuid: String?
    @NSManaged var flickrPageUrl: String?
    @NSManaged var ownerName: String?
    @NSManaged var license: NSNumber?
    @NSManaged var pin: VTAnnotation?

}
