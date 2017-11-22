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
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    let dictionaryStateNames = [
        "AK" : "Alaska",
        "AL" : "Alabama",
        "AR" : "Arkansas",
        "AS" : "American Samoa",
        "AZ" : "Arizona",
        "CA" : "California",
        "CO" : "Colorado",
        "CT" : "Connecticut",
        "DC" : "District of Columbia",
        "DE" : "Delaware",
        "FL" : "Florida",
        "GA" : "Georgia",
        "GU" : "Guam",
        "HI" : "Hawaii",
        "IA" : "Iowa",
        "ID" : "Idaho",
        "IL" : "Illinois",
        "IN" : "Indiana",
        "KS" : "Kansas",
        "KY" : "Kentucky",
        "LA" : "Louisiana",
        "MA" : "Massachusetts",
        "MD" : "Maryland",
        "ME" : "Maine",
        "MI" : "Michigan",
        "MN" : "Minnesota",
        "MO" : "Missouri",
        "MS" : "Mississippi",
        "MT" : "Montana",
        "NC" : "North Carolina",
        "ND" : " North Dakota",
        "NE" : "Nebraska",
        "NH" : "New Hampshire",
        "NJ" : "New Jersey",
        "NM" : "New Mexico",
        "NV" : "Nevada",
        "NY" : "New York",
        "OH" : "Ohio",
        "OK" : "Oklahoma",
        "OR" : "Oregon",
        "PA" : "Pennsylvania",
        "PR" : "Puerto Rico",
        "RI" : "Rhode Island",
        "SC" : "South Carolina",
        "SD" : "South Dakota",
        "TN" : "Tennessee",
        "TX" : "Texas",
        "UT" : "Utah",
        "VA" : "Virginia",
        "VI" : "Virgin Islands",
        "VT" : "Vermont",
        "WA" : "Washington",
        "WI" : "Wisconsin",
        "WV" : "West Virginia",
        "WY" : "Wyoming"
    ]

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
        NotificationCenter.default.addObserver(self, selector: #selector(LocationsMapViewController.mapTypeChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    // MARK: User Interaction
    @objc func mapTypeChanged(_ notification: Notification) {

        if let rawValue = UserDefaults.standard.object(forKey: "mapType") as? UInt {
            if let mapType = MKMapType(rawValue: rawValue) {
                switch(mapType){
                case .standard:
                    segmentedControl.selectedSegmentIndex = 0
                case .hybrid:
                    segmentedControl.selectedSegmentIndex = 1
                case .satellite:
                    segmentedControl.selectedSegmentIndex = 2
                default:
                    return
                }
            }
        }
    }
    
    @IBAction func segmentedControlTapped(_ sender: UISegmentedControl) {
        let Map = 0
        let Hybrid = 1
        let Satellite = 2
        switch(sender.selectedSegmentIndex){
        case Map:
            mapView.mapType = .standard
            UserDefaults.standard.set(MKMapType.standard.rawValue, forKey: "mapType")
        case Hybrid:
            mapView.mapType = .hybrid
            UserDefaults.standard.set(MKMapType.hybrid.rawValue, forKey: "mapType")
        case Satellite:
            mapView.mapType = .satellite
            UserDefaults.standard.set(MKMapType.satellite.rawValue, forKey: "mapType")
        default:
            print("Wrong Index in segmented control")
        }
    }
    
    @IBAction func locationTapped(_ sender: UIBarButtonItem) {
        startTrackingLocation()
    }
    
    func startTrackingLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            let uac = UIAlertController(title: "Enable Location Services to Allow SiteSee to Determine Your Location", message: "", preferredStyle: UIAlertControllerStyle.alert)
            uac.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) in
                UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!, completionHandler: nil)
            }))
            uac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(uac, animated: true, completion: nil)
            
        case .restricted:
            locationButton.isEnabled = false
        case .authorizedAlways, .authorizedWhenInUse:
            switch mapView.userTrackingMode {
            case .follow, .followWithHeading:
                mapView.setUserTrackingMode(.none, animated: true)
            case .none:
                mapView.setUserTrackingMode(.follow, animated: true)
            }
            
        }
    }
    @IBAction func layersButtonTapped(_ sender: UIBarButtonItem) {
        let uac = UIAlertController(title: "Change Map Type", message: nil, preferredStyle: .actionSheet)
        uac.addAction(UIAlertAction(title: "Standard", style: .default, handler: { (uac) in
            self.mapView.mapType = .standard
            UserDefaults.standard.set(MKMapType.standard.rawValue, forKey: "mapType")
        }))
        uac.addAction(UIAlertAction(title: "Hybrid", style: .default, handler: { (uac) in
            self.mapView.mapType = .hybrid
            UserDefaults.standard.set(MKMapType.hybrid.rawValue, forKey: "mapType")
        }))
        uac.addAction(UIAlertAction(title: "Satellite", style: .default, handler: { (uac) in
            self.mapView.mapType = .satellite
            UserDefaults.standard.set(MKMapType.satellite.rawValue, forKey: "mapType")
        }))
        uac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(uac, animated: true, completion: nil)
    }
    
    @IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let location = sender.location(in: mapView)
            let coor = mapView.convert(location, toCoordinateFrom: mapView)
            addPin(coor)
        }
    }
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        addPin(mapView.centerCoordinate)
    }
    @IBAction func trashButtonTapped(_ sender: UIBarButtonItem) {
        let uac = UIAlertController(title: "Delete All Pins", message: "Are you sure you want to delete all pins?", preferredStyle: .actionSheet)
        uac.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (uac) in
            if let objects = self.fetchedResultsController.fetchedObjects as? [NSManagedObject] {
                for object in objects {
                    self.sharedContext.delete(object)
                }
            }
        }))
        uac.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        present(uac, animated: true, completion: nil)
    }
    
    func addPin(_ coordinate: CLLocationCoordinate2D)  {
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { (placemarks, error) -> Void in
            if let geoCodeError = error {
                let uac = UIAlertController(title: geoCodeError.localizedDescription, message: "Please make sure the internet is connected", preferredStyle: .alert)
                uac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(uac, animated: true, completion: nil)
                return
            } else {
                if let placemark = placemarks?.first {
                    var locationNames = self.locationNames(placemark, altitude:self.mapView.camera.altitude)
                    var annotationDictionary : [String:AnyObject]
                    annotationDictionary = [
                        VTAnnotation.Keys.Longitude : NSNumber(value: coordinate.longitude as Double),
                        VTAnnotation.Keys.Latitude : NSNumber(value: coordinate.latitude as Double),
                        VTAnnotation.Keys.Title : locationNames[0] as AnyObject,
                        VTAnnotation.Keys.Page : NSNumber(value: 1 as Int)
                    ]
                    if locationNames.count > 1 {
                        annotationDictionary[VTAnnotation.Keys.Subtitle] = locationNames[1] as AnyObject
                    }
                    DispatchQueue.main.async{
                        let _ = VTAnnotation(dictionary: annotationDictionary, context: self.sharedContext)
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
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
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(mapView.region.center.latitude, forKey: mapViewLat)
        coder.encode(mapView.region.center.longitude, forKey: mapViewLong)
        coder.encode(mapView.region.span.latitudeDelta, forKey: mapViewSpanLatDelta)
        coder.encode(mapView.region.span.longitudeDelta, forKey: mapViewSpanLongDelta)
        
        coder.encodeCInt( Int32 (mapView.mapType.rawValue), forKey: mapTypeKey)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        
        var center = CLLocationCoordinate2D()
        var span = MKCoordinateSpan()
        
        center.latitude = coder.decodeDouble(forKey: mapViewLat)
        center.longitude = coder.decodeDouble(forKey: mapViewLong)
        
        span.latitudeDelta = coder.decodeDouble(forKey: mapViewSpanLatDelta)
        span.longitudeDelta = coder.decodeDouble(forKey: mapViewSpanLongDelta)
        
        let region = MKCoordinateRegion(center: center, span: span)
        
        mapView.setRegion(region, animated: true)
        mapView.mapType = MKMapType(rawValue: UInt(coder.decodeCInt(forKey: mapTypeKey)))!
    }
    
    // MARK: Navigation
    let siteTableViewControllerSegueID = "SiteTableViewController"
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == siteTableViewControllerSegueID {
            guard let pavc = segue.destination as? SiteTableViewController else {
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

    lazy var fetchedResultsController: NSFetchedResultsController<VTAnnotation> = {
        let request = NSFetchRequest<VTAnnotation>(entityName: "VTAnnotation")
        request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true), NSSortDescriptor(key: "longitude", ascending: true)]
        return NSFetchedResultsController<VTAnnotation>(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    // MARK: Helpers
    func locationNames(_ placemark: CLPlacemark, altitude: CLLocationDistance) -> [String] {
        var names = [String]()
        
        
        if altitude < 200000 {
            if let subLocality = placemark.subLocality {
                names.append(subLocality)
            }
        }
        
        if altitude < 400000 {
            if let locality = placemark.locality {
                names.append(locality)
            }
        }
        
        if altitude < 10000000 {
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
    func reverseGeocodeLocation(_ coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance, completionHandler: @escaping (_ name: String) -> Void) {
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { (placemarks, error) -> Void in
            if error == nil {
                guard let placemarks = placemarks else {
                    return
                }
                guard let placemark = placemarks.first else {
                    return
                }
            
                if let name = self.locationNames(placemark, altitude: altitude).first {
                    completionHandler(name)
                }
                
            }
        }
    }
    
}

// MARK: UIViewControllerRestoration
extension LocationsMapViewController : UIViewControllerRestoration {
    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocationsMapViewController")
        vc.restorationClass = LocationsMapViewController.self
        vc.restorationIdentifier = (identifierComponents.last as! String)
        return vc
    }
}

// MARK: MKMapViewDelegate
extension LocationsMapViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if mode == .none {
            locationButton.image = UIImage(named: "GPS")
        } else {
            locationButton.image = UIImage(named: "GPS-Filled")
        }
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        reverseGeocodeLocation(mapView.centerCoordinate, altitude: mapView.camera.altitude) { (name) -> Void in
            self.navigationItem.title = name
        }
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? VTAnnotation {
            self.annotation = annotation
            performSegue(withIdentifier: siteTableViewControllerSegueID, sender: self)
        }
    }
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for annView in views
        {
            if annView.isKind(of: MKPinAnnotationView.self) {
                let endFrame = annView.frame;
                annView.frame = endFrame.offsetBy(dx: 0, dy: -500);
                UIView.animate(withDuration: 0.3, animations: {
                    annView.frame = endFrame
                })
            }
        }
    }
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension LocationsMapViewController : NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let pin = anObject as! VTAnnotation
        switch type {
        case .insert:
            mapView.addAnnotation(pin)
        case .delete:
            mapView.removeAnnotation(pin)
        case .update:
            mapView.removeAnnotation(pin)
            mapView.addAnnotation(pin)
        default:
            return
        }
    }
    
}

extension LocationsMapViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            if !UserDefaults.standard.bool(forKey: "firstTimeLaunching") {
                startTrackingLocation()
                UserDefaults.standard.set(true, forKey: "firstTimeLaunching")
            }
        }
    }
}


