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
class PhotoAlbumViewController: UIViewController {
    var selectedIndexPath: IndexPath?
    var annotation: VTAnnotation! {
        didSet{
            let keyword =  annotation.keyword()
            do { try self.fetchedResultsController.performFetch() }  catch {}
            searchPhotosByText(keyword, pageNumber: lastPageNumber)
        }
    }
    var blockOperations: [BlockOperation] = []
    let placeholder = UIImage(named: "placeholder")!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    @IBOutlet weak var collectionView: UICollectionView!
    var lastPageNumber : Int {
        set {
            annotation.pageNumber = newValue as NSNumber
            DispatchQueue.main.async {
                do {
                    try self.sharedContext.save()
                } catch {}
            }
        }
        get {
            return annotation.pageNumber.intValue
        }
    }
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        navigationController?.isNavigationBarHidden = false
        
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.addGestureRecognizer(tapGesture)
        
    }
    // MARK: User Iteraction
    @IBAction func didTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self.collectionView)
        
        if let indexPath = self.collectionView.indexPathForItem(at: point)
        {
            selectedIndexPath = indexPath
            performSegue(withIdentifier: "PhotoViewController", sender: self)
        }
    }

    override var canBecomeFirstResponder : Bool {
        return true
    }
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(VTCollectionViewCell.deleteImage)
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PhotoViewController" {
            guard let indexPath = selectedIndexPath else {
                print("selectedIndexPath is nil")
                return
            }
            guard let destVc = segue.destination as? PhotoViewController else {
                print("destVc isnt PhotoViewController")
                return
            }
            guard let image = fetchedResultsController.object(at: indexPath) as? Image else {
                print("objectAtIndexPath isn't Image")
                return
            }
            destVc.image = image
        }
    }
    
    // MARK: Flickr API

    func searchPhotosByText(_ text:String, pageNumber: Int) {
        let methodArguments = Flickr.sharedInstance().getSearchPhotoMethodArgumentsConvenience(text, perPage: 21)
        
        Flickr.sharedInstance().getImageFromFlickrBySearch(methodArguments) { (stat, photosDict, totalPages, error) -> Void in
            guard error == nil else {
                let uac = UIAlertController(title: error!.localizedDescription, message: nil, preferredStyle: .alert)
                uac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(uac, animated: true, completion: nil)
                return
            }
            let pageLimit = min(totalPages!, 40)
            DispatchQueue.main.async{
                if pageLimit == 0 {
                    self.lastPageNumber = 0
                } else if self.collectionView.numberOfItems(inSection: 0) == 0 {
                    self.lastPageNumber = pageNumber % pageLimit
                } else if self.lastPageNumber == pageNumber { // do not download the same page again
                    // TODO: change this for infinite scroll
                        return
                }
                var sortOrder: Double = 0.0
                Flickr.sharedInstance().getImageFromFlickrWithPageConvenience(methodArguments, pageNumber: self.lastPageNumber, completionHandler: { (thumbnailUrl, origImageUrl, flickrPageUrl, ownerName, license, error) in
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
                        Image.Keys.License : license
                    ]
                    sortOrder += 1.0
                    
                    DispatchQueue.main.async{
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
    lazy var fetchedResultsController: NSFetchedResultsController<Image> = {
        let request = NSFetchRequest<Image>(entityName: "Image")
        request.predicate = NSPredicate(format: "pin == %@", self.annotation)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        let fetched =  NSFetchedResultsController<Image>(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetched.delegate = self
        return fetched
    }()
    
    // MARK: State Restoration
    let longitudeKey = "longitude"
    let latitudeKey = "latitude"
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(annotation.longitude, forKey: longitudeKey)
        coder.encode(annotation.latitude, forKey: latitudeKey)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        let long = coder.decodeObject(forKey: longitudeKey) as! NSNumber
        let lat = coder.decodeObject(forKey: latitudeKey) as! NSNumber
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "VTAnnotation")
        request.predicate = NSPredicate(format: "latitude == %f AND longitude == %f", argumentArray: [lat.doubleValue, long.doubleValue])
        request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        do { annotation = try sharedContext.fetch(request).first as! VTAnnotation} catch {}
        
    }
    
    // Mark: Documents Directory
    static func photoURL(_ uniqueFileName: String) -> URL {
        let documentsDirectoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectoryURL.appendingPathComponent(uniqueFileName)
    }
}
// MARK: NSFetchedResultsControllerDelegate
extension PhotoAlbumViewController : NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll(keepingCapacity: false)
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            blockOperations.append(
                BlockOperation(block: { () -> Void in
                    self.collectionView.insertItems(at: [newIndexPath!])
                })
            )
        case .delete:
            blockOperations.append(
                BlockOperation(block: { () -> Void in
                    self.collectionView.deleteItems(at: [indexPath!])
                })
            )
        case .update:
            blockOperations.append(
                BlockOperation(block: { () -> Void in
                    self.collectionView.reloadItems(at: [indexPath!])
                })
            )
        case .move:
            blockOperations.append(
                BlockOperation(block: { () -> Void in
                    self.collectionView.moveItem(at: indexPath!, to: newIndexPath!)
                })
            )
        }
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let set = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            blockOperations.append(
                BlockOperation(block: { () -> Void in
                    self.collectionView.insertSections(set)
                })
            )
        case .delete:
            blockOperations.append(
                BlockOperation(block: { () -> Void in
                    self.collectionView.deleteSections(set)
                })
            )
        case .update:
            blockOperations.append(
                BlockOperation(block: { () -> Void in
                    self.collectionView.reloadSections(set)
                })
            )
        default: break
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            self.collectionView.performBatchUpdates({ () -> Void in
                for op : BlockOperation in self.blockOperations {
                    op.start()
                }
                
                }) { completed -> Void in
                    self.blockOperations.removeAll(keepingCapacity: false)
                    
            }
    }
}
// MARK: UICollectionViewDelegateFlowLayout
extension PhotoAlbumViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow:CGFloat = 3
        let padding:CGFloat = 5
        let rowWidth = min(collectionView.bounds.width, collectionView.bounds.height)
        let photoSide = (rowWidth / itemsPerRow) - padding
        return CGSize(width: photoSide, height: photoSide)
    }
}
// MARK: UICollectionViewDelegate
extension PhotoAlbumViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        selectedIndexPath = indexPath
        
        var targetFrame = collectionView.cellForItem(at: indexPath)!.frame
        targetFrame = collectionView.convert(targetFrame, to: collectionView.superview)
        
        UIMenuController.shared.setTargetRect(targetFrame, in: collectionView.superview!)
        let deleteMenuItem = UIMenuItem(title: "Delete", action: #selector(VTCollectionViewCell.deleteImage))
        
        UIMenuController.shared.menuItems = [deleteMenuItem]
        return true
    }
    func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action==#selector(VTCollectionViewCell.deleteImage)
    }
    func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    }
}
// MARK: UICollectionViewDataSource
extension PhotoAlbumViewController : UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! VTCollectionViewCell
        cell.activity.hidesWhenStopped = true
        cell.delegate = self
        let image = fetchedResultsController.object(at: indexPath) as! Image
        
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
                DispatchQueue.main.async{
                    let img = UIImage(data: data)!
                    cell.backgroundView = UIImageView(image: img)
                    image.uuid = UUID().uuidString
                    let jpegData = UIImageJPEGRepresentation(img, 1.0)!
                    try? jpegData.write(to: URL(fileURLWithPath: Image.imgPath(image.uuid!)), options: [.atomic])
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
    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotoAlbumViewController")
    }
}
//MARK: UIGestureRecognizerDelegate
extension PhotoAlbumViewController : UIGestureRecognizerDelegate {
}
extension PhotoAlbumViewController : VTCollectionViewCellDelegate {
    func deleteSelectedImage() {
        if let selected = selectedIndexPath {
            if let object = fetchedResultsController.object(at: selected) as? NSManagedObject {
                DispatchQueue.main.async(execute: { 
                    self.sharedContext.delete(object)
                    do{ try self.sharedContext.save() } catch {}
                })
            } else {
                print("objectAtIndexPath isn't NSmanaged object")
            }
        } else {
            print("selectedIndexPath is nil")
        }
    }
}
