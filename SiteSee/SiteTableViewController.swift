//
//  SiteTableViewController.swift
//  SiteSee
//
//  Created by Tom Lai on 3/21/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import UIKit
import CoreData
import SafariServices
class SiteTableViewController: UITableViewController {
    let flickerSection = 0
    let wikiSection = 1
    
    var annotation: VTAnnotation! {
        didSet {
            self.navigationItem.rightBarButtonItem = self.editButtonItem()
            var keyword = annotation.title!
            if let subtitle = annotation.subtitle {
                keyword += ", \(subtitle)"
                navigationItem.title = keyword
            }
            fetchedArticlesController.delegate = self
            fetchedImagesController.delegate = self
            do {
                try fetchedArticlesController.performFetch()
                try fetchedImagesController.performFetch()
            } catch {
                fatalError("Fetch failed: \(error)")
            }
            if !NSUserDefaults.standardUserDefaults().boolForKey(locationIsLoadedKey()) {
                searchWikipediaForArticles(keyword)
                searchFlickrForPhotos(keyword)
            }
        }
    }
    let placeholder = UIImage(named: "placeholder")!
    var collectionView: UICollectionView {
        let flickrCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: flickerSection)) as! SSTableViewPhotosCell
        return flickrCell.collectionView
    }

    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        registerForPreviewingWithDelegate(self, sourceView: tableView)
        
    }

    // MARK: Helpers
    func locationIsLoadedKey() -> String {
        return "locationIsLoaded: \(annotation.latitude) \(annotation.longitude)"
    }
    func convertIndexPathForFetchedResultsController(indexPath: NSIndexPath) -> NSIndexPath {
        return setSectionForIndexPath(indexPath, section: 0)!
    }
    func setSectionForIndexPath(indexPath: NSIndexPath?, section:Int) -> NSIndexPath? {
        guard let ip = indexPath else {
            return nil
        }
        return NSIndexPath(forRow: ip.row, inSection: section)
    }
    func urlForTableCellAt(indexPath: NSIndexPath) -> NSURL? {
        let fi = convertIndexPathForFetchedResultsController(indexPath)
        guard let article = fetchedArticlesController.objectAtIndexPath(fi) as? Article  else {
            print("fetched result not an article")
            return nil
        }
        guard let title = article.title else {
            print("article does not have a title")
            return nil
        }
        guard let urlEncodedTitle = title.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLUserAllowedCharacterSet()) else {
            print("title did not encode: \(title)")
            return nil
        }
        let urlStr = Wikipedia.Constants.userBaseUrl + urlEncodedTitle
        
        guard let url = NSURL(string: urlStr) else {
            print("\(urlStr) is not a valid url")
            return nil
        }
        return url
    }
    
    func pushSafariViewController(url: NSURL) {
        let sfVc = SFSafariViewController(URL: url)
        sfVc.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.pushViewController(sfVc, animated: true)
    }

    // MARK: Flickr Client
    func searchFlickrForPhotos(text:String) {
        let methodArguments = Flickr.sharedInstance().getSearchPhotoMethodArgumentsConvenience(text, perPage: 21)
        
        Flickr.sharedInstance().getImageFromFlickrBySearch(methodArguments) { (stat, photosDict, totalPages, error) -> Void in
            guard error == nil else {
                print(error?.localizedDescription)
                return
            }
            dispatch_async(dispatch_get_main_queue()){
                var sortOrder: Double = 0.0
                Flickr.sharedInstance().getImageFromFlickrWithPageConvenience(methodArguments, pageNumber: 0, completionHandler: { (thumbnailUrl, origImageUrl, flickrPageUrl, ownerName, license, error) in
                    guard error == nil else {
                        return
                    }
                    // add thumbnail url to core data
                    // add medium url to core data
                    let imageDictionary : [String: AnyObject?] = [
                        Image.Keys.ThumbnailUrl : thumbnailUrl!,
                        Image.Keys.OrigImageUrl : origImageUrl,
                        Image.Keys.SortOrder : NSNumber(double: sortOrder),
                        Image.Keys.FlickrPageUrl : flickrPageUrl,
                        Image.Keys.OwnerName : ownerName,
                        Image.Keys.License : license
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
    func searchWikipediaForArticles(keyword: String) {
        let metthodArguments: [String: AnyObject] = [
            "action" : Wikipedia.Actions.query,
            "format" : Wikipedia.Constants.format,
            "list" : Wikipedia.List.search,
            "utf-8" : 1,
            "srsearch" : keyword,
            "srlimit" : 8
        ]
        var sortOrder : Double = 0.0
        Wikipedia.sharedInstance().getListOfArticles(metthodArguments) { (title, subtitle, error) -> Void in
            guard error == nil else {
                let uac = UIAlertController(title: error!.localizedDescription, message: nil, preferredStyle: .Alert)
                uac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(uac, animated: true, completion: nil)
                NSUserDefaults.standardUserDefaults().setBool(false, forKey: self.locationIsLoadedKey())
                return
            }
            if let title = title {
                let articleDict : [String : AnyObject?] = [
                    Article.Keys.Title : title,
                    Article.Keys.Subtitle : subtitle,
                    Article.Keys.Url : nil,
                    Article.Keys.SortOrder : NSNumber(double: sortOrder)
                ]
                sortOrder += 1.0
                dispatch_async(dispatch_get_main_queue(), {
                    Article(dictionary: articleDict, context: self.sharedContext).pin = self.annotation
                    do {
                        try self.sharedContext.save()
                    } catch {}
                })
            } else {
                print ("no title")
            }
        }
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: locationIsLoadedKey())
    }
    
    // MARK: - Table View Data Source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case flickerSection:
                return 1
        case wikiSection:
            if let sections = fetchedArticlesController.sections {
                return sections[0].numberOfObjects
            }
            return 0
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case flickerSection:
            return "Flickr"
        case wikiSection:
            return "Wikipedia"
        default:
            return ""
        }
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return dequeuePhotoTableCell(tableView, indexPath: indexPath)
        case 1:
            return dequeuePlainTableCell(tableView, indexPath: indexPath)
        default:
            print("Unexpected section in cellForRowAtIndexPath")
            return UITableViewCell()
        }
    }
    func dequeuePlainTableCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("plainTableCell", forIndexPath: indexPath) as? SSTableViewCell else {
            print("cell isn't SSTableViewCell")
            return tableView.dequeueReusableCellWithIdentifier("plainTableCell", forIndexPath: indexPath)
        }
        let fi = convertIndexPathForFetchedResultsController(indexPath)
        guard let article = fetchedArticlesController.objectAtIndexPath(fi) as? Article  else {
            print("fetched result not an article")
            return cell
        }
        guard let title = cell.titleLabel else {
            print("cell does not have a titleLabel")
            return cell
        }
        guard let subtitle = cell.subtitleLabel else {
            print("cell does not have a subtitleLabel")
            return cell
        }
        title.text = article.title
        subtitle.text = article.subtitle
        return cell
    }
    
    func dequeuePhotoTableCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("photosCell", forIndexPath: indexPath) as? SSTableViewPhotosCell else {
            print("cell isn't SSTableViewPhotosCell")
            return tableView.dequeueReusableCellWithIdentifier("photosCell", forIndexPath: indexPath)
        }

        if fetchedImagesController.fetchedObjects?.count == 0{
            cell.noPhotosLabel.hidden = false
        }
        
        return cell
    }
   
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            performSegueWithIdentifier("photoAlbumViewController", sender: tableView)
        case 1:
            guard let url = urlForTableCellAt(indexPath) else {
                print("url is nil")
                return
            }
            pushSafariViewController(url)
        default:
            print("Unexpected section in didSelectRowAtIndexPath")
            return
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        switch indexPath.section {
        case 0:
            return false
        case 1:
            return true
        default:
            print("Unexpected section in canEditRowAtIndexPath")
            return false
        }
    }

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let fi = convertIndexPathForFetchedResultsController(indexPath)
        guard let object = fetchedArticlesController.objectAtIndexPath(fi) as? NSManagedObject else {
            print("fetchedResultsController returned non NSManagedObject")
            return
        }
        if editingStyle == .Delete {
            dispatch_async(dispatch_get_main_queue(), { 
                self.sharedContext.deleteObject(object)
                do { try self.sharedContext.save() } catch {}
            })
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            print("Insertion is not supported")
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let targetSortOrder : Double
        let ffi = convertIndexPathForFetchedResultsController(fromIndexPath)
        let fti = convertIndexPathForFetchedResultsController(toIndexPath)
        guard let objectToMove = fetchedArticlesController.objectAtIndexPath(ffi) as? Article else {
            print("objectToMove isn't an Article")
            return
        }
        
        guard let objectToDisplace = fetchedArticlesController.objectAtIndexPath(fti) as? Article else {
            print("objectToDisplace isn't an Article")
            return
        }
        if toIndexPath.row == 0 {
            // move to top
            targetSortOrder = objectToDisplace.sortOrder!.doubleValue - 1.0
        } else if toIndexPath.row == fetchedArticlesController.sections![ffi.section].numberOfObjects - 1 {
            // move to bottom
            targetSortOrder = objectToDisplace.sortOrder!.doubleValue + 1.0
        } else {
            // move to middle
            let auxIndexPath = NSIndexPath(forRow: toIndexPath.row-1, inSection: fti.section)
            let fi = convertIndexPathForFetchedResultsController(auxIndexPath)
            guard let objectBeforeDest = fetchedArticlesController.objectAtIndexPath(fi) as? Article else {
                print("objectBeforeDest isn't an Article")
                return
            }
            targetSortOrder = (objectBeforeDest.sortOrder!.doubleValue + objectToDisplace.sortOrder!.doubleValue) / 2
        }
        objectToMove.sortOrder = targetSortOrder
        dispatch_async(dispatch_get_main_queue()) {
            do { try self.sharedContext.save() } catch {}
        }
        
    }

    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            var row = 0
            if sourceIndexPath.section < proposedDestinationIndexPath.section {
                row = tableView.numberOfRowsInSection(sourceIndexPath.section) - 1
            }
            return NSIndexPath(forRow: row, inSection: sourceIndexPath.section)
        }
        return proposedDestinationIndexPath
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "photoAlbumViewController" {
            if let pavc = segue.destinationViewController as? PhotoAlbumViewController {
                pavc.annotation = annotation
            } else {
                print("unexpected view controller in prepareForSegue")
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
    lazy var fetchedArticlesController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Article")
        request.predicate = NSPredicate(format: "pin == %@", self.annotation)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        let fetched =  NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetched.delegate = self
        return fetched
    }()
    
    lazy var fetchedImagesController: NSFetchedResultsController = {
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
    let tableScrollPosition = "tableScrollPosition"
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        coder.encodeObject(annotation.longitude, forKey: longitudeKey)
        coder.encodeObject(annotation.latitude, forKey: latitudeKey)
        coder.encodeObject(tableView.contentOffset.y, forKey: tableScrollPosition)
    }

    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        super.decodeRestorableStateWithCoder(coder)
        let long = coder.decodeObjectForKey(longitudeKey) as! NSNumber
        let lat = coder.decodeObjectForKey(latitudeKey) as! NSNumber
        
        let request = NSFetchRequest(entityName: "VTAnnotation")
        request.predicate = NSPredicate(format: "latitude == %f AND longitude == %f", argumentArray: [lat.doubleValue, long.doubleValue])
        request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        do { annotation = try sharedContext.executeFetchRequest(request).first as! VTAnnotation} catch {}
        
        tableView.contentOffset.y = coder.decodeObjectForKey(tableScrollPosition) as! CGFloat
    }
    
}
// MARK: NSFetchedResultsControllerDelegate
extension SiteTableViewController : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if controller == fetchedArticlesController {
            tableView.beginUpdates()
        }
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if controller == fetchedArticlesController {
            tableView.endUpdates()
        } else if controller == fetchedImagesController {
            if fetchedImagesController.fetchedObjects?.count != 0{
                let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! SSTableViewPhotosCell
                cell.noPhotosLabel.hidden = true
            }
        }
    }
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if controller == fetchedImagesController {
            let ti = setSectionForIndexPath(indexPath, section: flickerSection)
            let tni = setSectionForIndexPath(newIndexPath, section: flickerSection)
            switch type {
            case .Insert:
                collectionView.insertItemsAtIndexPaths([tni!])
            case .Delete:
                collectionView.deleteItemsAtIndexPaths([ti!])
            case .Update:
                collectionView.reloadItemsAtIndexPaths([ti!])
            case .Move:
                collectionView.moveItemAtIndexPath(ti!, toIndexPath: tni!)
            }
        } else if controller == fetchedArticlesController {
            let ti = setSectionForIndexPath(indexPath, section: wikiSection)
            let tni = setSectionForIndexPath(newIndexPath, section: wikiSection)
            switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([tni!], withRowAnimation: .Automatic)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([ti!], withRowAnimation: .Automatic)
            case .Update:
                tableView.reloadRowsAtIndexPaths([ti!], withRowAnimation: .Automatic)
            case .Move:
                tableView.moveRowAtIndexPath(ti!, toIndexPath: tni!)
            }
        }
    }
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        let set = NSIndexSet(index: sectionIndex)
        if controller == fetchedArticlesController {
            switch type {
            case .Insert:
                tableView.insertSections(set, withRowAnimation: .Automatic)
            case .Delete:
                tableView.deleteSections(set, withRowAnimation: .Automatic)
            case .Update:
                tableView.reloadSections(set, withRowAnimation: .Automatic)
                
            default: break
            }
        } else if controller == fetchedImagesController {
            switch type {
            case .Insert:
                collectionView.insertSections(set)
            case .Delete:
                collectionView.deleteSections(set)
            case .Update:
                collectionView.reloadSections(set)
            default: break
            }
        }
    }
}


// MARK: SFSafariViewControllerDelegate
extension SiteTableViewController : SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        navigationController?.popViewControllerAnimated(true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

// MARK: UICollectionViewDataSource
extension SiteTableViewController : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let fetchedObject = fetchedImagesController.fetchedObjects else {
            return 0
        }
        return fetchedObject.count
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! VTCollectionViewCell
        cell.activity.hidesWhenStopped = true
        let fi = convertIndexPathForFetchedResultsController(indexPath)
        let image = fetchedImagesController.objectAtIndexPath(fi) as! Image
        
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
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("photoAlbumViewController", sender: tableView)
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension SiteTableViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let padding:CGFloat = 5
        let photoSide = collectionView.bounds.height - 2 * padding
        return CGSize(width: photoSide, height: photoSide)
    }
}

//MARK: UIViewControllerRestoration
extension SiteTableViewController : UIViewControllerRestoration {
    static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SiteTableViewController")
    }
}


extension SiteTableViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRowAtPoint(location) else { return nil }
        
        guard let url = urlForTableCellAt(indexPath) else { return nil }
        let sfVc = SFSafariViewController(URL: url)
        sfVc.delegate = self
        previewingContext.sourceRect = tableView.rectForRowAtIndexPath(indexPath)
        
        return sfVc
        
    }
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        showViewController(viewControllerToCommit, sender: self)
    }
}


