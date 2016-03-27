//
//  LocationsMapViewController.swift
//  SiteSee
//
//  Created by Tom Lai on 1/18/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationsMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    var annotation: VTAnnotation!
    var locationManager = CLLocationManager()
    var geocoder = CLGeocoder()
    var dictionaryStateNames = NSDictionary(objects:
        ["Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"] ,
                                            forKeys:
        ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"])

    @IBOutlet weak var locationButton: UIBarButtonItem!
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Fetch failed: \(error)")
        }
        locationManager.delegate = self
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(fetchedResultsController.fetchedObjects as! [MKAnnotation])
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: User Interaction
    @IBAction func locationTapped(sender: UIBarButtonItem) {
        startTrackingLocation()
    }
    
    func startTrackingLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .Denied:
            let uac = UIAlertController(title: "Enable Location Services to Allow SiteSee to Determine Your Location", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            uac.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) in
                UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!);
            }))
            uac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

            presentViewController(uac, animated: true, completion: nil)
            
        case .Restricted:
            locationButton.enabled = false
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            switch mapView.userTrackingMode {
            case .Follow, .FollowWithHeading:
                mapView.setUserTrackingMode(.None, animated: true)
            case .None:
                mapView.setUserTrackingMode(.Follow, animated: true)
            }
            
        }
    }
    @IBAction func layersButtonTapped(sender: UIBarButtonItem) {
        let uac = UIAlertController(title: "Change Map Type", message: nil, preferredStyle: .ActionSheet)
        uac.addAction(UIAlertAction(title: "Standard", style: .Default, handler: { (uac) in
            self.mapView.mapType = .Standard
        }))
        uac.addAction(UIAlertAction(title: "Hybrid", style: .Default, handler: { (uac) in
            self.mapView.mapType = .Hybrid
        }))
        uac.addAction(UIAlertAction(title: "Satellite", style: .Default, handler: { (uac) in
            self.mapView.mapType = .Satellite
        }))
        uac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(uac, animated: true, completion: nil)
    }
    
    @IBAction func didLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .Ended {
            addPin()
        }
    }
    @IBAction func addButtonTapped(sender: UIBarButtonItem) {
        addPin()
    }
    @IBAction func trashButtonTapped(sender: UIBarButtonItem) {
        let uac = UIAlertController(title: "Delete All Pins", message: "Are you sure you want to delete all pins?", preferredStyle: .ActionSheet)
        uac.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { (uac) in
            if let objects = self.fetchedResultsController.fetchedObjects as? [NSManagedObject] {
                for object in objects {
                    self.sharedContext.deleteObject(object)
                }
            }
        }))
        uac.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        presentViewController(uac, animated: true, completion: nil)
    }
    
    func addPin()  {
        geocoder.reverseGeocodeLocation(CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)) { (placemarks, error) -> Void in
            if let placemark = placemarks?.first {
                var locationNames = self.locationNames(placemark, altitude:self.mapView.camera.altitude)
                var annotationDictionary : [String:AnyObject]
                annotationDictionary = [
                    VTAnnotation.Keys.Longitude : NSNumber(double: self.mapView.centerCoordinate.longitude),
                    VTAnnotation.Keys.Latitude : NSNumber(double: self.mapView.centerCoordinate.latitude),
                    VTAnnotation.Keys.Title : locationNames[0],
                    VTAnnotation.Keys.Page : NSNumber(integer: 1)
                ]
                if locationNames.count > 1 {
                    annotationDictionary[VTAnnotation.Keys.Subtitle] = locationNames[1]
                }
                dispatch_async(dispatch_get_main_queue()){
                    let _ = VTAnnotation(dictionary: annotationDictionary, context: self.sharedContext)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }
    }
    
    // MARK: - State Restoration
    let mapViewLat = "MapViewLat"
    let mapViewLong = "MapViewLong"
    let mapViewSpanLatDelta = "MapViewSpanLatDelta"
    let mapViewSpanLongDelta = "MapViewSpanLongDelta"
    let mapTypeKey = "MapType"
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        coder.encodeDouble(mapView.region.center.latitude, forKey: mapViewLat)
        coder.encodeDouble(mapView.region.center.longitude, forKey: mapViewLong)
        coder.encodeDouble(mapView.region.span.latitudeDelta, forKey: mapViewSpanLatDelta)
        coder.encodeDouble(mapView.region.span.longitudeDelta, forKey: mapViewSpanLongDelta)
        
        coder.encodeInt( Int32 (mapView.mapType.rawValue), forKey: mapTypeKey)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        super.decodeRestorableStateWithCoder(coder)
        
        var center = CLLocationCoordinate2D()
        var span = MKCoordinateSpan()
        
        center.latitude = coder.decodeDoubleForKey(mapViewLat)
        center.longitude = coder.decodeDoubleForKey(mapViewLong)
        
        span.latitudeDelta = coder.decodeDoubleForKey(mapViewSpanLatDelta)
        span.longitudeDelta = coder.decodeDoubleForKey(mapViewSpanLongDelta)
        
        let region = MKCoordinateRegion(center: center, span: span)
        
        mapView.setRegion(region, animated: true)
        mapView.mapType = MKMapType(rawValue: UInt(coder.decodeIntForKey(mapTypeKey)))!
    }
    
    // MARK: Navigation
    let siteTableViewControllerSegueID = "SiteTableViewController"
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == siteTableViewControllerSegueID {
            guard let pavc = segue.destinationViewController as? SiteTableViewController else {
                print("unexpected destionation viewcontroller")
                return
            }
            pavc.annotation = annotation
            
        }
    }
    
    // MARK: Core Data Convenience
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "VTAnnotation")
        request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true), NSSortDescriptor(key: "longitude", ascending: true)]
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    // MARK: Helpers
    func locationNames(placemark: CLPlacemark, altitude: CLLocationDistance) -> [String] {
        var names = [String]()
        
        
        if altitude < 100000 {
            if let subLocality = placemark.subLocality {
                names.append(subLocality)
            }
        }
        
        if altitude < 300000 {
            if let locality = placemark.locality {
                names.append(locality)
            }
        }
        
        if altitude < 1000000 {
            if let administrativeArea = placemark.administrativeArea {
                if let name = dictionaryStateNames[administrativeArea] as? String{
                    names.append(name)
                } else {
                    names.append(administrativeArea)
                }
            }
        }

        if let country = placemark.country {
            names.append(country)
        }
        if let ocean = placemark.ocean {
            names.append(ocean)
        }

        return names
    }
    func reverseGeocodeLocation(coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance, completionHandler: (name: String) -> Void) {
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { (placemarks, error) -> Void in
            if error == nil {
                guard let placemarks = placemarks else {
                    return
                }
                guard let placemark = placemarks.first else {
                    return
                }
            
                if let name = self.locationNames(placemark, altitude: altitude).first {
                    completionHandler(name: name)
                }
                
            }
        }
    }
    
}

// MARK: UIViewControllerRestoration
extension LocationsMapViewController : UIViewControllerRestoration {
    static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LocationsMapViewController")
        vc.restorationClass = LocationsMapViewController.self
        vc.restorationIdentifier = (identifierComponents.last as! String)
        return vc
    }
}

// MARK: MKMapViewDelegate
extension LocationsMapViewController : MKMapViewDelegate {
    func mapView(mapView: MKMapView, didChangeUserTrackingMode mode: MKUserTrackingMode, animated: Bool) {
        if mode == .None {
            locationButton.image = UIImage(named: "GPS")
        } else {
            locationButton.image = UIImage(named: "GPS-Filled")
        }
    }
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        reverseGeocodeLocation(mapView.centerCoordinate, altitude: mapView.camera.altitude) { (name) -> Void in
            self.navigationItem.title = name
        }
    }
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let annotation = view.annotation as? VTAnnotation {
            self.annotation = annotation
            performSegueWithIdentifier(siteTableViewControllerSegueID, sender: self)
        }
    }
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        for annView in views
        {
            if annView.isKindOfClass(MKPinAnnotationView) {
                let endFrame = annView.frame;
                annView.frame = CGRectOffset(endFrame, 0, -500);
                UIView.animateWithDuration(0.3, animations: {
                    annView.frame = endFrame
                })
            }
        }
    }
    func mapViewWillStartLoadingMap(mapView: MKMapView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    func mapViewDidFinishLoadingMap(mapView: MKMapView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension LocationsMapViewController : NSFetchedResultsControllerDelegate {
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        let pin = anObject as! VTAnnotation
        switch type {
        case .Insert:
            mapView.addAnnotation(pin)
        case .Delete:
            mapView.removeAnnotation(pin)
        case .Update:
            mapView.removeAnnotation(pin)
            mapView.addAnnotation(pin)
        default:
            return
        }
    }
    
}

extension LocationsMapViewController : CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            if !NSUserDefaults.standardUserDefaults().boolForKey("firstTimeLaunching") {
                startTrackingLocation()
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "firstTimeLaunching")
            }
        }
    }
}


