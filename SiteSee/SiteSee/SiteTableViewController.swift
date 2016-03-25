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
    var annotation: VTAnnotation!
    var blockOperations: [NSBlockOperation] = []
    let placeholder = UIImage(named: "placeholder")!
    var collectionView: UICollectionView {
        let flickrCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! SSTableViewPhotosCell
        return flickrCell.collectionView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
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
        if !NSUserDefaults.standardUserDefaults().boolForKey(locationIsLoadedKey(keyword)) {
            searchWikipediaForArticles(keyword)
            searchFlickrForPhotos(keyword)
        }
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 160
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
    }
    func locationIsLoadedKey(keyword: String) -> String {
        return "locationIsLoaded: " + keyword
    }
    
    func searchFlickrForPhotos(text:String) {
        let methodArguments = Flickr.sharedInstance().getSearchMethodArgumentsConvenience(text, perPage: 21)
        
        Flickr.sharedInstance().getImageFromFlickrBySearch(methodArguments) { (stat, photosDict, totalPages, error) -> Void in
            guard error == nil else {
                print(error?.localizedDescription)
                return
            }
            dispatch_async(dispatch_get_main_queue()){
                var sortOrder: Double = 0.0
                Flickr.sharedInstance().getImageFromFlickrWithPageConvenience(methodArguments, pageNumber: 0, completionHandler: { (thumbnailUrl, imageUrl, error) in
                    guard error == nil else {
                        print("no photos")
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                        })
                        return
                    }
                    // add thumbnail url to core data
                    // add medium url to core data
                    let imageDictionary : [String: AnyObject] = [
                        Image.Keys.ThumbnailUrl : thumbnailUrl!,
                        Image.Keys.ImageUrl : imageUrl!,
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
    func searchWikipediaForArticles(keyword: String) {
        let metthodArguments: [String: AnyObject] = [
            "action" : Wikipedia.Actions.query,
            "format" : Wikipedia.Constants.format,
            "list" : Wikipedia.List.search,
            "utf-8" : 1,
            "srsearch" : keyword,
            "srlimit" : 5
        ]
        var sortOrder : Double = 0.0
        Wikipedia.sharedInstance().getListOfArticles(metthodArguments) { (title, subtitle, error) -> Void in
            guard error == nil else {
                print(error)
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
                
                Article(dictionary: articleDict, context: self.sharedContext).pin = self.annotation
                do {
                    try self.sharedContext.save()
                } catch {}
            } else {
                print ("no title")
            }
        }
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: locationIsLoadedKey(keyword))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return fetchedArticlesController.sections![0].numberOfObjects
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Flickr"
        case 1:
            return "Wikipedia"
        default:
            return ""
        }
    }
    
    func dequeuePlainTableCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("plainTableCell", forIndexPath: indexPath) as? SSTableViewCell else {
            print("cell isn't SSTableViewCell")
            return tableView.dequeueReusableCellWithIdentifier("plainTableCell", forIndexPath: indexPath)
        }
        let fetchedIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
        guard let article = fetchedArticlesController.objectAtIndexPath(fetchedIndexPath) as? Article  else {
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
        //        guard let article = fetchedResultsController.objectAtIndexPath(indexPath) as? Article  else {
        //            print("fetched result not an article")
        //            return cell
        //        }
        //        guard let title = cell.titleLabel else {
        //            print("cell does not have a titleLabel")
        //            return cell
        //        }
        //        guard let subtitle = cell.subtitleLabel else {
        //            print("cell does not have a subtitleLabel")
        //            return cell
        //        }
        //        title.text = article.title
        //        subtitle.text = article.subtitle
        return cell
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
    func gotoArticle(indexPath: NSIndexPath) {
        let fetchedIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
        guard let article = fetchedArticlesController.objectAtIndexPath(fetchedIndexPath) as? Article  else {
            print("fetched result not an article")
            return
        }
        guard let title = article.title else {
            print("article does not have a title")
            return
        }
        guard let urlEncodedTitle = title.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLUserAllowedCharacterSet()) else {
            print("title did not encode: \(title)")
            return
        }
        let urlStr = Wikipedia.Constants.userBaseUrl + urlEncodedTitle
        
        guard let url = NSURL(string: urlStr) else {
            print("\(urlStr) is not a valid url")
            return
        }
        
        pushSafariViewController(url)
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            performSegueWithIdentifier("photoAlbumViewController", sender: tableView)
        case 1:
            gotoArticle(indexPath)
        default:
            print("Unexpected section in didSelectRowAtIndexPath")
            return
        }
    }
    func pushSafariViewController(url: NSURL) {
        let sfVc = SFSafariViewController(URL: url)
        sfVc.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.pushViewController(sfVc, animated: true)
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
        let fetchedIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
        guard let object = fetchedArticlesController.objectAtIndexPath(fetchedIndexPath) as? NSManagedObject else {
            print("fetchedResultsController returned non NSManagedObject")
            return
        }
        if editingStyle == .Delete {
            sharedContext.deleteObject(object)
            do { try sharedContext.save() } catch {}
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            print("Insertion is not supported")
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let targetSortOrder : Double
        let fetchedFromIndexPath = NSIndexPath(forRow: fromIndexPath.row, inSection: 0)
        let fetchedToIndexPath = NSIndexPath(forRow: toIndexPath.row, inSection: 0)
        guard let objectToMove = fetchedArticlesController.objectAtIndexPath(fetchedFromIndexPath) as? Article else {
            print("objectToMove isn't an Article")
            return
        }
        
        guard let objectToDisplace = fetchedArticlesController.objectAtIndexPath(fetchedToIndexPath) as? Article else {
            print("objectToDisplace isn't an Article")
            return
        }
        if toIndexPath.row == 0 {
            // move to top
            targetSortOrder = objectToDisplace.sortOrder!.doubleValue - 1.0
        } else if toIndexPath.row == fetchedArticlesController.sections![fetchedFromIndexPath.section].numberOfObjects - 1 {
            // move to bottom
            targetSortOrder = objectToDisplace.sortOrder!.doubleValue + 1.0
        } else {
            // move to middle
            let auxIndexPath = NSIndexPath(forRow: toIndexPath.row-1, inSection: fetchedToIndexPath.section)
            guard let objectBeforeDest = fetchedArticlesController.objectAtIndexPath(auxIndexPath) as? Article else {
                print("objectBeforeDest isn't an Article")
                return
            }
            targetSortOrder = (objectBeforeDest.sortOrder!.doubleValue + objectToDisplace.sortOrder!.doubleValue) / 2
        }
        objectToMove.sortOrder = targetSortOrder
        do { try sharedContext.save() } catch {}
        
    }
    
    
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
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
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
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
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        super.decodeRestorableStateWithCoder(coder)
    }
    
}
// MARK: NSFetchedResultsControllerDelegate
extension SiteTableViewController : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if controller == fetchedArticlesController {
            tableView.beginUpdates()
        } else if controller == fetchedImagesController {
            blockOperations.removeAll(keepCapacity: false)
        }
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if controller == fetchedArticlesController {
            tableView.endUpdates()
        } else if controller == fetchedImagesController {
            collectionView.performBatchUpdates({ () -> Void in
                for op : NSBlockOperation in self.blockOperations {
                    op.start()
                }
                
            }) { completed -> Void in
                self.blockOperations.removeAll(keepCapacity: false)
                
            }
        }
    }
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if controller == fetchedArticlesController {
            switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            case .Update:
                tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            case .Move:
                tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
            }
        } else if controller == fetchedImagesController {
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
        let image = fetchedImagesController.objectAtIndexPath(indexPath) as! Image
        
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
        let photoSide = 100
        return CGSize(width: photoSide, height: photoSide)
    }
}
