//
//  SiteTableViewModel.swift
//  SiteSee
//
//  Created by Tom Lai on 11/24/17.
//  Copyright © 2017 Lai. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class SiteTableViewModel: NSObject {
    var articlesBeginUpdate: (()->Void)? = nil
    var insertImage: ((IndexPath)->Void)? = nil
    var deleteImage: ((IndexPath)->Void)? = nil
    var updateImage: ((IndexPath)->Void)? = nil
    var moveImage: ((IndexPath, IndexPath)->Void)? = nil
    var articlesEndUpdate: (()->Void)? = nil
    var insertArticle: ((IndexPath)->Void)? = nil
    var deleteArticle: ((IndexPath)->Void)? = nil
    var updateArticle: ((IndexPath)->Void)? = nil
    var moveArticle: ((IndexPath, IndexPath)->Void)? = nil
    var imagesEndUpdate: (()->Void)? = nil
    private let flickerSection = 0
    private let wikiSection = 1
    init(annotation: VTAnnotation) {
        self.selectedAnnotation = annotation
        super.init()
    }
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

    lazy var fetchedArticlesController: NSFetchedResultsController<Article> = {
        let request = NSFetchRequest<Article>(entityName: "Article")
        request.predicate = NSPredicate(format: "pin == %@", self.selectedAnnotation)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

        let fetched =  NSFetchedResultsController<Article>(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetched.delegate = self
        return fetched
    }()

    lazy var fetchedImagesController: NSFetchedResultsController<Image> = {
        let request = NSFetchRequest<Image>(entityName: "Image")
        request.predicate = NSPredicate(format: "pin == %@", self.selectedAnnotation)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

        let fetched =  NSFetchedResultsController<Image>(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetched.delegate = self
        return fetched
    }()

    var selectedAnnotation: VTAnnotation
    let placeholderImage = UIImage(named: "placeholder")!
    private func locationIsLoadedKey() -> String {
        return "locationIsLoaded: \(selectedAnnotation.latitude) \(selectedAnnotation.longitude)"
    }
    private func convertIndexPathForFetchedResultsController(_ indexPath: IndexPath) -> IndexPath {
        return setSectionForIndexPath(indexPath, section: 0)!
    }
    private func setSectionForIndexPath(_ indexPath: IndexPath?, section:Int) -> IndexPath? {
        guard let indexPath = indexPath else {
            return nil
        }
        return IndexPath(row: indexPath.row, section: section)
    }
    func wikipediaURL(atIndexPath indexPath: IndexPath) -> URL? {
        let fi = convertIndexPathForFetchedResultsController(indexPath)
        guard let article = fetchedArticlesController.object(at: fi) as? Article  else {
            print("fetched result not an article")
            return nil
        }
        guard let title = article.title else {
            print("article does not have a title")
            return nil
        }
        guard let urlEncodedTitle = title.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlUserAllowed) else {
            print("title did not encode: \(title)")
            return nil
        }
        let urlStr = Wikipedia.Constants.userBaseUrl + urlEncodedTitle

        guard let url = URL(string: urlStr) else {
            print("\(urlStr) is not a valid url")
            return nil
        }
        return url
    }
}

extension SiteTableViewModel: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        articlesBeginUpdate?()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == fetchedArticlesController {
            articlesEndUpdate?()
        } else if controller == fetchedImagesController {
            imagesEndUpdate?()
        }
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if controller == fetchedImagesController {
            let currentIndexPath = setSectionForIndexPath(indexPath, section: flickerSection)!
            let newIndexPath = setSectionForIndexPath(newIndexPath, section: flickerSection)
            switch type {
            case .insert:
                insertImage?(currentIndexPath)
            case .delete:
                deleteImage?(currentIndexPath)
            case .update:
                updateImage?(currentIndexPath)
            case .move:
                moveImage?(currentIndexPath, newIndexPath!)
            }
        } else if controller == fetchedArticlesController {
            let currentIndexPath = setSectionForIndexPath(indexPath, section: wikiSection)!
            let newIndexPath = setSectionForIndexPath(newIndexPath, section: wikiSection)

            switch type {
            case .insert:
                insertArticle?(currentIndexPath)
            case .delete:
                deleteArticle?(currentIndexPath)
            case .update:
                updateArticle?(currentIndexPath)
            case .move:
                moveArticle?(currentIndexPath, newIndexPath!)
            }
        }
    }
}
