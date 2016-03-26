//
//  PhotoAlbumViewController.swift
//  SiteSee
//
//  Created by Tom Lai on 1/23/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import Foundation
// TODO: long tap to display a menu that says delete
class PhotoAlbumViewController: UIViewController {
    var selectedIndexPath: NSIndexPath?
    var annotation: VTAnnotation! {
        didSet{
            let keyword =  annotation.keyword()
            do { try self.fetchedResultsController.performFetch() }  catch {}
            searchPhotosByText(keyword, pageNumber: lastPageNumber)
        }
    }
    var blockOperations: [NSBlockOperation] = []
    let placeholder = UIImage(named: "placeholder")!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    @IBOutlet weak var collectionView: UICollectionView!
    //verify there is no way to get to this view controller if no photos is at this location
    var lastPageNumber : Int {
        set {
            annotation.pageNumber = newValue
            do {
                try sharedContext.save()
            } catch {}
        }
        get {
            return annotation.pageNumber.integerValue
        }
    }
    @IBAction func didTap(sender: UITapGestureRecognizer) {
        let point = sender.locationInView(self.collectionView)
        
        if let indexPath = self.collectionView.indexPathForItemAtPoint(point)
        {
            selectedIndexPath = indexPath
            performSegueWithIdentifier("PhotoViewController", sender: self)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PhotoViewController" {
            guard let zoomInSegue = segue as? ZoomInSegue else {
                print("segue isnt ZoomInSegue")
                return
            }
            guard let indexPath = selectedIndexPath else {
                print("selectedIndexPath is nil")
                return
            }
            guard let cell = self.collectionView.cellForItemAtIndexPath(indexPath) else {
                print("no cellForItemAtIndexPath")
                return
            }
            let cellRect = cell.frame
            
            zoomInSegue.animateFromRect = collectionView.convertRect(cellRect, toView: collectionView.superview)
            guard let destVc = segue.destinationViewController as? PhotoViewController else {
                print("destVc isnt PhotoViewController")
                return
            }
            guard let image = fetchedResultsController.objectAtIndexPath(indexPath) as? Image else {
                print("objectAtIndexPath isn't Image")
                return
            }
            destVc.image = image
        }
    }

    func removeAllPhotosAtThisLocation() {
        for object in fetchedResultsController.fetchedObjects! {
            if let obj = object as? NSManagedObject {
                sharedContext.deleteObject(obj)
            }
        }
    }

    
    override func viewDidLoad() {
        navigationController?.navigationBarHidden = false

        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.addGestureRecognizer(tapGesture)
        
    }

    // MARK: Flickr API

    func searchPhotosByText(text:String, pageNumber: Int) {
        let methodArguments = Flickr.sharedInstance().getSearchMethodArgumentsConvenience(text, perPage: 21)
        
        Flickr.sharedInstance().getImageFromFlickrBySearch(methodArguments) { (stat, photosDict, totalPages, error) -> Void in
            guard error == nil else {
                print(error?.localizedDescription)
                return
            }
            let pageLimit = min(totalPages!, 40)
            dispatch_async(dispatch_get_main_queue()){
                if pageLimit == 0 {
                    self.lastPageNumber = 0
                } else if self.collectionView.numberOfItemsInSection(0) == 0 {
                    self.lastPageNumber = pageNumber % pageLimit
                } else if self.lastPageNumber == pageNumber { // do not download the same page again
                    // TODO: change this for infinite scroll
                        return
                }
                var sortOrder: Double = 0.0
                Flickr.sharedInstance().getImageFromFlickrWithPageConvenience(methodArguments, pageNumber: self.lastPageNumber, completionHandler: { (thumbnailUrl, imageUrl, origImageUrl, error) in
                    guard error == nil else {
                        return
                    }
                    // add thumbnail url to core data
                    // add medium url to core data
                    let imageDictionary : [String: AnyObject?] = [
                        Image.Keys.ThumbnailUrl : thumbnailUrl!,
                        Image.Keys.ImageUrl : imageUrl!,
                        Image.Keys.OrigImageUrl : origImageUrl,
                        Image.Keys.SortOrder : NSNumber(double: sortOrder)
                        
                    ]
                    sortOrder += 1.0
                    
                    dispatch_async(dispatch_get_main_queue()){
                        let image = Image(dictionary: imageDictionary, context: self.sharedContext)
                        image.pin = self.annotation
                        self.saveContext()
                    }
                })
                
            }
        }
    }
    
    
    
    // MARK: - Core Data Convenience
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Image")
        request.predicate = NSPredicate(format: "pin == %@", self.annotation)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        let fetched =  NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetched.delegate = self
        return fetched
    }()
    
    // MARK: state restoration
    let longitudeKey = "longitude"
    let latitudeKey = "latitude"
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        coder.encodeObject(annotation.longitude, forKey: longitudeKey)
        coder.encodeObject(annotation.latitude, forKey: latitudeKey)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        super.decodeRestorableStateWithCoder(coder)
        let long = coder.decodeObjectForKey(longitudeKey) as! NSNumber
        let lat = coder.decodeObjectForKey(latitudeKey) as! NSNumber
        
        let request = NSFetchRequest(entityName: "VTAnnotation")
        request.predicate = NSPredicate(format: "latitude == %f AND longitude == %f", argumentArray: [lat.doubleValue, long.doubleValue])
        request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        do { annotation = try sharedContext.executeFetchRequest(request).first as! VTAnnotation} catch {}
        
    }
    
}
// MARK: NSFetchedResultsControllerDelegate
extension PhotoAlbumViewController : NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        blockOperations.removeAll(keepCapacity: false)
    }
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            blockOperations.append(
                NSBlockOperation(block: { () -> Void in
                    self.collectionView.insertItemsAtIndexPaths([newIndexPath!])
                })
            )
        case .Delete:
            blockOperations.append(
                NSBlockOperation(block: { () -> Void in
                    self.collectionView.deleteItemsAtIndexPaths([indexPath!])
                })
            )
        case .Update:
            blockOperations.append(
                NSBlockOperation(block: { () -> Void in
                    self.collectionView.reloadItemsAtIndexPaths([indexPath!])
                })
            )
        case .Move:
            blockOperations.append(
                NSBlockOperation(block: { () -> Void in
                    self.collectionView.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                })
            )
        }
    }
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        let set = NSIndexSet(index: sectionIndex)
        switch type {
        case .Insert:
            blockOperations.append(
                NSBlockOperation(block: { () -> Void in
                    self.collectionView.insertSections(set)
                })
            )
        case .Delete:
            blockOperations.append(
                NSBlockOperation(block: { () -> Void in
                    self.collectionView.deleteSections(set)
                })
            )
        case .Update:
            blockOperations.append(
                NSBlockOperation(block: { () -> Void in
                    self.collectionView.reloadSections(set)
                })
            )
        default: break
        }
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
            self.collectionView.performBatchUpdates({ () -> Void in
                for op : NSBlockOperation in self.blockOperations {
                    op.start()
                }
                
                }) { completed -> Void in
                    self.blockOperations.removeAll(keepCapacity: false)
                    
            }
    }
}
// MARK: UICollectionViewDelegateFlowLayout
extension PhotoAlbumViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let itemsPerRow:CGFloat = 3
        let padding:CGFloat = 5
        let photoSide = (collectionView.bounds.width / itemsPerRow) - padding
        return CGSize(width: photoSide, height: photoSide)
    }
}
// MARK: UICollectionViewDataSource
extension PhotoAlbumViewController : UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        } else {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! VTCollectionViewCell
        cell.activity.hidesWhenStopped = true
        let image = fetchedResultsController.objectAtIndexPath(indexPath) as! Image
        
        // look for local path, if not found, download and save to documents directory
        
        if let uuid = image.uuid  {
            
            if let img = UIImage(contentsOfFile: Image.imgPath(uuid)) {
                cell.backgroundView = UIImageView(image: img)
                cell.activity.stopAnimating()
            }
            
        } else {
            // not found, download and save to documents directory, then display in cell
            cell.activity.startAnimating()
            cell.backgroundView = UIImageView(image: placeholder)
            if let thumbnailUrl = image.thumbnailUrl {
            Flickr.sharedInstance().getCellImageConvenience(thumbnailUrl, completion: { (data) -> Void in
                dispatch_async(dispatch_get_main_queue()){
                    let img = UIImage(data: data)!
                    cell.backgroundView = UIImageView(image: img)
                    image.uuid = NSUUID().UUIDString
                    let jpegData = UIImageJPEGRepresentation(img, 1.0)!
                    jpegData.writeToFile(Image.imgPath(image.uuid!), atomically: true)
                    do {
                        try self.sharedContext.save()
                    } catch {}
                }
            })
            } else {
                print("image.thumbnailURL is nill")
            }
        }
        return cell
    }

}

//MARK: UIViewControllerRestoration
extension PhotoAlbumViewController : UIViewControllerRestoration {
    static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PhotoAlbumViewController")
    }
}

//Mark: documents directory
extension PhotoAlbumViewController  {
    static func photoURL(uniqueFileName: String) -> NSURL {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        return documentsDirectoryURL.URLByAppendingPathComponent(uniqueFileName)
    }
}
//MARK: UIGestureRecognizerDelegate
extension PhotoAlbumViewController : UIGestureRecognizerDelegate {
}
