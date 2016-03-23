//
//  Image+CoreDataProperties.swift
//  SiteSee
//
//  Created by Tom Lai on 3/23/16.
//  Copyright © 2016 Lai. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Image {

    @NSManaged var uuid: String?
    @NSManaged var imageUrl: String?
    @NSManaged var thumbnailUrl: String?
    @NSManaged var pin: VTAnnotation?

}
