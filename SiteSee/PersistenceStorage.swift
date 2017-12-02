//
//  ArticleStore.swift
//  SiteSee
//
//  Created by Tom Lai on 11/24/17.
//  Copyright © 2017 Lai. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit
protocol PersistenceStorageLocationDelegate {
    func add(annotation : VTAnnotation)
    func remove(annotation : VTAnnotation)
}
struct PersistenceStorage {
    var annotationsDelegate: NSFetchedResultsControllerDelegate?
    var locationDelegate: PersistenceStorageLocationDelegate?
    var selectedAnnotation: VTAnnotation!
    lazy var annotations: [VTAnnotation] = {
        do {
            try annotationFetchedResultsController.performFetch()
            if let objects = annotationFetchedResultsController.fetchedObjects {
                return objects.map{$0 as VTAnnotation}
            }
        } catch {
            fatalError("Fetched failed \(error)")
        }
    }()

    private var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

    private lazy var annotationFetchedResultsController: NSFetchedResultsController<VTAnnotation> = {
        let request = NSFetchRequest<VTAnnotation>(entityName: "VTAnnotation")
        request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true), NSSortDescriptor(key: "longitude", ascending: true)]
        return NSFetchedResultsController<VTAnnotation>(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
    }()

    private lazy var articleFetchedArticlesController: NSFetchedResultsController<Article> = {
        let request = NSFetchRequest<Article>(entityName: "Article")
        request.predicate = NSPredicate(format: "pin == %@", self.selectedAnnotation)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

        let fetched =  NSFetchedResultsController<Article>(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetched.delegate = self
        return fetched
    }()


    private lazy var imageFetchedResultsController: NSFetchedResultsController<Image> = {
        let request = NSFetchRequest<Image>(entityName: "Image")
        request.predicate = NSPredicate(format: "pin == %@", self.selectedAnnotation)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

        let fetched =  NSFetchedResultsController<Image>(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetched.delegate = self
        return fetched
    }()
}

extension PersistenceStorage: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch anObject {
        case let annotation as VTAnnotation:
            switch type {
            case .insert:
                locationDelegate?.add(annotation: annotation)
            case .delete:
                locationDelegate?.remove(annotation: annotation)
            case .update:
                locationDelegate?.remove(annotation: annotation)
                locationDelegate?.add(annotation: annotation)
            default:
                return
            }
        case let image as Image:
            switch type {

            }

        case let article as Article:
            switch type {

            }

        }
    }
}
