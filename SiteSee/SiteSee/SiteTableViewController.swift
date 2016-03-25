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
    override func viewDidLoad() {
        super.viewDidLoad()
        var keyword = annotation.title!
        if let subtitle = annotation.subtitle {
            keyword += ", \(subtitle)"
            navigationItem.title = keyword
        }
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Fetch failed: \(error)")
        }
        if !NSUserDefaults.standardUserDefaults().boolForKey(locationIsLoadedKey(keyword)) {
            searchWikipediaForArticles(keyword)
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
//        if let sections = fetchedResultsController.sections {
//            return sections.count + 1
//        }
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return fetchedResultsController.sections![section].numberOfObjects
        case 1:
            return 1
        default:
            return 0
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Wikipedia"
        case 1:
            return "Flickr"
        default:
            return ""
        }
    }

    func dequeuePlainTableCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("plainTableCell", forIndexPath: indexPath) as? SSTableViewCell else {
            print("cell isn't SSTableViewCell")
            return tableView.dequeueReusableCellWithIdentifier("plainTableCell", forIndexPath: indexPath)
        }
        
        guard let article = fetchedResultsController.objectAtIndexPath(indexPath) as? Article  else {
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
            return dequeuePlainTableCell(tableView, indexPath: indexPath)
        case 1:
            return dequeuePhotoTableCell(tableView, indexPath: indexPath)
        default:
            print("Unexpected section in cellForRowAtIndexPath")
            return UITableViewCell()
        }
    }
    func gotoArticle(indexPath: NSIndexPath) {
        guard let article = fetchedResultsController.objectAtIndexPath(indexPath) as? Article  else {
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
            gotoArticle(indexPath)
        case 1:
            return // handled by
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
            return true
        case 1:
            return false
        default:
            print("Unexpected section in canEditRowAtIndexPath")
            return false
        }
    }
 

    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let object = fetchedResultsController.objectAtIndexPath(indexPath) as? NSManagedObject else {
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
        guard let objectToMove = fetchedResultsController.objectAtIndexPath(fromIndexPath) as? Article else {
            print("objectToMove isn't an Article")
            return
        }
        
        guard let objectToDisplace = fetchedResultsController.objectAtIndexPath(toIndexPath) as? Article else {
            print("objectToDisplace isn't an Article")
            return
        }
        if toIndexPath.row == 0 {
            // move to top
            targetSortOrder = objectToDisplace.sortOrder!.doubleValue - 1.0
        } else if toIndexPath.row == fetchedResultsController.sections![fromIndexPath.section].numberOfObjects - 1 {
            // move to bottom
            targetSortOrder = objectToDisplace.sortOrder!.doubleValue + 1.0
        } else {
            // move to middle
            let auxIndexPath = NSIndexPath(forRow: toIndexPath.row-1, inSection: toIndexPath.section)
            guard let objectBeforeDest = fetchedResultsController.objectAtIndexPath(auxIndexPath) as? Article else {
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
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Article")
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
        tableView.beginUpdates()
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
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
    }
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        let set = NSIndexSet(index: sectionIndex)
        switch type {
        case .Insert:
            tableView.insertSections(set, withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteSections(set, withRowAnimation: .Automatic)
        case .Update:
            tableView.reloadSections(set, withRowAnimation: .Automatic)
            
        default: break
        }
    }
}

extension SiteTableViewController : SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        navigationController?.popViewControllerAnimated(true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

extension SiteTableViewController : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath)
        return cell
    }
}

extension SiteTableViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let itemsPerRow:CGFloat = 4
        let padding:CGFloat = 5
        let photoWidth = (collectionView.bounds.width / itemsPerRow) - padding
        let photoHeight = collectionView.bounds.height - (2 * padding)
        return CGSize(width: photoWidth, height: photoHeight)
    }
}
