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
            self.navigationItem.rightBarButtonItem = self.editButtonItem
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
            if !UserDefaults.standard.bool(forKey: locationIsLoadedKey()) {
                searchWikipediaForArticles(keyword)
                searchFlickrForPhotos(keyword)
            }
        }
    }
    let placeholder = UIImage(named: "placeholder")!
    var collectionView: UICollectionView {
        let flickrCell = tableView.cellForRow(at: IndexPath(row: 0, section: flickerSection)) as! SSTableViewPhotosCell
        return flickrCell.collectionView
    }

    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
    }

    // MARK: Helpers
    func locationIsLoadedKey() -> String {
        return "locationIsLoaded: \(annotation.latitude) \(annotation.longitude)"
    }
    func convertIndexPathForFetchedResultsController(_ indexPath: IndexPath) -> IndexPath {
        return setSectionForIndexPath(indexPath, section: 0)!
    }
    func setSectionForIndexPath(_ indexPath: IndexPath?, section:Int) -> IndexPath? {
        guard let ip = indexPath else {
            return nil
        }
        return IndexPath(row: ip.row, section: section)
    }
    func gotoArticle(_ indexPath: IndexPath) {
        let fi = convertIndexPathForFetchedResultsController(indexPath)
        guard let article = fetchedArticlesController.object(at: fi) as? Article  else {
            print("fetched result not an article")
            return
        }
        guard let title = article.title else {
            print("article does not have a title")
            return
        }
        guard let urlEncodedTitle = title.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlUserAllowed) else {
            print("title did not encode: \(title)")
            return
        }
        let urlStr = Wikipedia.Constants.userBaseUrl + urlEncodedTitle
        
        guard let url = URL(string: urlStr) else {
            print("\(urlStr) is not a valid url")
            return
        }
        
        pushSafariViewController(url)
    }
    
    func pushSafariViewController(_ url: URL) {
        let sfVc = SFSafariViewController(url: url)
        sfVc.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.pushViewController(sfVc, animated: true)
    }

    // MARK: Flickr Client
    func searchFlickrForPhotos(_ text:String) {
        let methodArguments = Flickr.sharedInstance().getSearchPhotoMethodArgumentsConvenience(text, perPage: 21)
        
        Flickr.sharedInstance().getImageFromFlickrBySearch(methodArguments) { (stat, photosDict, totalPages, error) -> Void in
            guard error == nil else {
                print(error?.localizedDescription)
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
    
    // MARK: - Table View Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case flickerSection:
            return "Flickr"
        case wikiSection:
            return "Wikipedia"
        default:
            return ""
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    func dequeuePlainTableCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "plainTableCell", for: indexPath) as? SSTableViewCell else {
            print("cell isn't SSTableViewCell")
            return tableView.dequeueReusableCell(withIdentifier: "plainTableCell", for: indexPath)
        }
        let fi = convertIndexPathForFetchedResultsController(indexPath)
        guard let article = fetchedArticlesController.object(at: fi) as? Article  else {
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
    
    func dequeuePhotoTableCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "photosCell", for: indexPath) as? SSTableViewPhotosCell else {
            print("cell isn't SSTableViewPhotosCell")
            return tableView.dequeueReusableCell(withIdentifier: "photosCell", for: indexPath)
        }

        if fetchedImagesController.fetchedObjects?.count == 0{
            cell.noPhotosLabel.isHidden = false
        }
        
        return cell
    }
   
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            performSegue(withIdentifier: "photoAlbumViewController", sender: tableView)
        case 1:
            gotoArticle(indexPath)
        default:
            print("Unexpected section in didSelectRowAtIndexPath")
            return
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let fi = convertIndexPathForFetchedResultsController(indexPath)
        guard let object = fetchedArticlesController.object(at: fi) as? NSManagedObject else {
            print("fetchedResultsController returned non NSManagedObject")
            return
        }
        if editingStyle == .delete {
            DispatchQueue.main.async(execute: { 
                self.sharedContext.delete(object)
                do { try self.sharedContext.save() } catch {}
            })
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            print("Insertion is not supported")
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        let targetSortOrder : Double
        let ffi = convertIndexPathForFetchedResultsController(fromIndexPath)
        let fti = convertIndexPathForFetchedResultsController(toIndexPath)
        guard let objectToMove = fetchedArticlesController.object(at: ffi) as? Article else {
            print("objectToMove isn't an Article")
            return
        }
        
        guard let objectToDisplace = fetchedArticlesController.object(at: fti) as? Article else {
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
            let auxIndexPath = IndexPath(row: toIndexPath.row-1, section: fti.section)
            let fi = convertIndexPathForFetchedResultsController(auxIndexPath)
            guard let objectBeforeDest = fetchedArticlesController.object(at: fi) as? Article else {
                print("objectBeforeDest isn't an Article")
                return
            }
            targetSortOrder = (objectBeforeDest.sortOrder!.doubleValue + objectToDisplace.sortOrder!.doubleValue) / 2
        }
        objectToMove.sortOrder = targetSortOrder
        DispatchQueue.main.async {
            do { try self.sharedContext.save() } catch {}
        }
        
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            var row = 0
            if sourceIndexPath.section < proposedDestinationIndexPath.section {
                row = tableView.numberOfRows(inSection: sourceIndexPath.section) - 1
            }
            return IndexPath(row: row, section: sourceIndexPath.section)
        }
        return proposedDestinationIndexPath
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoAlbumViewController" {
            if let pavc = segue.destination as? PhotoAlbumViewController {
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
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Article")
        request.predicate = NSPredicate(format: "pin == %@", self.annotation)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        let fetched =  NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetched.delegate = self
        return fetched
    }()
    
    lazy var fetchedImagesController: NSFetchedResultsController = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Image")
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
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(annotation.longitude, forKey: longitudeKey)
        coder.encode(annotation.latitude, forKey: latitudeKey)
        coder.encode(tableView.contentOffset.y, forKey: tableScrollPosition)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        let long = coder.decodeObject(forKey: longitudeKey) as! NSNumber
        let lat = coder.decodeObject(forKey: latitudeKey) as! NSNumber
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "VTAnnotation")
        request.predicate = NSPredicate(format: "latitude == %f AND longitude == %f", argumentArray: [lat.doubleValue, long.doubleValue])
        request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        do { annotation = try sharedContext.fetch(request).first as! VTAnnotation} catch {}
        
        tableView.contentOffset.y = coder.decodeObject(forKey: tableScrollPosition) as! CGFloat
    }
    
}
// MARK: NSFetchedResultsControllerDelegate
extension SiteTableViewController : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == fetchedArticlesController {
            tableView.beginUpdates()
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == fetchedArticlesController {
            tableView.endUpdates()
        } else if controller == fetchedImagesController {
            if fetchedImagesController.fetchedObjects?.count != 0{
                let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! SSTableViewPhotosCell
                cell.noPhotosLabel.isHidden = true
            }
        }
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if controller == fetchedImagesController {
            let ti = setSectionForIndexPath(indexPath, section: flickerSection)
            let tni = setSectionForIndexPath(newIndexPath, section: flickerSection)
            switch type {
            case .insert:
                collectionView.insertItems(at: [tni!])
            case .delete:
                collectionView.deleteItems(at: [ti!])
            case .update:
                collectionView.reloadItems(at: [ti!])
            case .move:
                collectionView.moveItem(at: ti!, to: tni!)
            }
        } else if controller == fetchedArticlesController {
            let ti = setSectionForIndexPath(indexPath, section: wikiSection)
            let tni = setSectionForIndexPath(newIndexPath, section: wikiSection)
            switch type {
            case .insert:
                tableView.insertRows(at: [tni!], with: .automatic)
            case .delete:
                tableView.deleteRows(at: [ti!], with: .automatic)
            case .update:
                tableView.reloadRows(at: [ti!], with: .automatic)
            case .move:
                tableView.moveRow(at: ti!, to: tni!)
            }
        }
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let set = IndexSet(integer: sectionIndex)
        if controller == fetchedArticlesController {
            switch type {
            case .insert:
                tableView.insertSections(set, with: .automatic)
            case .delete:
                tableView.deleteSections(set, with: .automatic)
            case .update:
                tableView.reloadSections(set, with: .automatic)
                
            default: break
            }
        } else if controller == fetchedImagesController {
            switch type {
            case .insert:
                collectionView.insertSections(set)
            case .delete:
                collectionView.deleteSections(set)
            case .update:
                collectionView.reloadSections(set)
            default: break
            }
        }
    }
}


// MARK: SFSafariViewControllerDelegate
extension SiteTableViewController : SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        navigationController?.popViewController(animated: true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

// MARK: UICollectionViewDataSource
extension SiteTableViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let fetchedObject = fetchedImagesController.fetchedObjects else {
            return 0
        }
        return fetchedObject.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! VTCollectionViewCell
        cell.activity.hidesWhenStopped = true
        let fi = convertIndexPathForFetchedResultsController(indexPath)
        let image = fetchedImagesController.object(at: fi) as! Image
        
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "photoAlbumViewController", sender: tableView)
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension SiteTableViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding:CGFloat = 5
        let photoSide = collectionView.bounds.height - 2 * padding
        return CGSize(width: photoSide, height: photoSide)
    }
}

//MARK: UIViewControllerRestoration
extension SiteTableViewController : UIViewControllerRestoration {
    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SiteTableViewController")
    }
}


