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
    let flickerSection = 0
    let wikiSection = 1
    var selectedAnnotation: VTAnnotation
    var keyword: String {
        return selectedAnnotation.title!
    }
    var title: String {
        get {
            if let subtitle = selectedAnnotation.subtitle {
                return keyword + ", \(subtitle)"
            }
            return keyword
        }
    }
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

    // MARK: Flickr Client
    func searchFlickrForPhotos(_ text:String) {
        let methodArguments = Flickr.sharedInstance().getSearchPhotoMethodArgumentsConvenience(text, perPage: 21)

        Flickr.sharedInstance().getImageFromFlickrBySearch(methodArguments) { (stat, photosDict, totalPages, error) -> Void in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            DispatchQueue.main.async{
                var sortOrder: Double = 0.0
                Flickr.sharedInstance().getImageFromFlickrWithPageConvenience(methodArguments, pageNumber: 0, completionHandler: { (thumbnailUrl, origImageUrl, flickrPageUrl, ownerName, license, error) in
                    guard error == nil else {
                        return
                    }
                    // add thumbnail url to core data
                    // add medium url to core data
                    let imageDictionary : [String: AnyObject?] = [
                        Image.Keys.ThumbnailUrl : thumbnailUrl! as AnyObject,
                        Image.Keys.OrigImageUrl : origImageUrl as AnyObject,
                        Image.Keys.SortOrder : NSNumber(value: sortOrder as Double),
                        Image.Keys.FlickrPageUrl : flickrPageUrl as AnyObject,
                        Image.Keys.OwnerName : ownerName as AnyObject,
                        Image.Keys.License : NSNumber(value: license!) as AnyObject
                    ]
                    sortOrder += 1.0

                    DispatchQueue.main.async{
                        let image = Image(dictionary: imageDictionary, context: self.sharedContext)
                        image.pin = self.selectedAnnotation
                        self.saveContext()
                    }
                })
            }
        }
    }

    func searchWikipediaForArticles(_ keyword: String) {
        let metthodArguments: [String: AnyObject] = [
            "action" : Wikipedia.Actions.query as AnyObject,
            "format" : Wikipedia.Constants.format as AnyObject,
            "list" : Wikipedia.List.search as AnyObject,
            "utf-8" : 1 as AnyObject,
            "srsearch" : keyword as AnyObject,
            "srlimit" : 8 as AnyObject
        ]
        var sortOrder : Double = 0.0
        Wikipedia.sharedInstance().getListOfArticles(metthodArguments) { (title, subtitle, error) -> Void in
            guard error == nil else {
                let uac = UIAlertController(title: error!.localizedDescription, message: nil, preferredStyle: .alert)
                uac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(uac, animated: true, completion: nil)
                UserDefaults.standard.set(false, forKey: self.locationIsLoadedKey())
                return
            }
            if let title = title {
                let articleDict : [String : AnyObject?] = [
                    Article.Keys.Title : title as AnyObject,
                    Article.Keys.Subtitle : subtitle as AnyObject,
                    Article.Keys.Url : nil,
                    Article.Keys.SortOrder : NSNumber(value: sortOrder as Double)
                ]
                sortOrder += 1.0
                DispatchQueue.main.async(execute: {
                    Article(dictionary: articleDict, context: self.sharedContext).pin = self.annotation
                    do {
                        try self.sharedContext.save()
                    } catch {}
                })
            } else {
                print ("no title")
            }
        }
        UserDefaults.standard.set(true, forKey: locationIsLoadedKey())
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
