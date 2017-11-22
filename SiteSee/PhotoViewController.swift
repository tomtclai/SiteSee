//
//  PhotoViewController.swift
//  SiteSee
//
//  Created by Tom Lai on 3/26/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import UIKit
import SafariServices
class PhotoViewController: UIViewController {
    var image : Image!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var effectView: UIVisualEffectView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var attributionLabel: UILabel!
    @IBOutlet weak var attribution: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    func attributionStr(_ flickrLicense: Int, ownerName: String)->String {
        let licenseName = Flickr.Constants.licenseName(flickrLicense)
        if flickrLicense == 7 || flickrLicense == 8 {
            return "\(licenseName ?? "License not available")."
        } else {
        return "This photo is made available under a \(licenseName!) license."
        }
    }
    
    @IBAction func tapped(_ sender: UITapGestureRecognizer) {
        let sfv = SFSafariViewController(url: URL(string:image.flickrPageUrl!)!)
        navigationController?.pushViewController(sfv, animated: true)
    }
    override func viewDidLoad() {

        super.viewDidLoad()
        
        guard let uuid = image.uuid else {
            print("image has no uuid")
            return
        }
        
        imageView.image = UIImage(contentsOfFile: Image.imgPath(uuid))
        updateZoomScale()
        scrollView.delegate = self;
        setupAttributions()
        loadFullSizeImage()
    }

    fileprivate func updateConstraintsForSize(_ size: CGSize) {
        
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset
        
        view.layoutIfNeeded()
    }
    func updateZoomScale() -> Void {
        let viewSize = self.scrollView.bounds.size
        let imageSize = imageView.bounds.size
        let xScale = imageSize.width / viewSize.width
        let yScale = imageSize.height / viewSize.height
        scrollView.minimumZoomScale = min(xScale, yScale)
        scrollView.maximumZoomScale = max(xScale, yScale)
        scrollView.zoomScale = scrollView.minimumZoomScale
    }
    @IBAction func attributionTapped(_ sender: UIButton) {
        let sfv = SFSafariViewController(url: URL(string: Flickr.Constants.licenseUrl(image.license!.intValue)!)!)
        navigationController?.pushViewController(sfv, animated: true)
    }
    func setupAttributions() -> Void {
        attribution.setTitle(attributionStr(image.license!.intValue, ownerName:image.ownerName!), for: UIControlState())
        attribution.titleLabel?.textAlignment = .center
        attributionLabel.text = "Copyright © \(image.ownerName!). No changes were made."
        attributionLabel.textColor = UIColor.black.withAlphaComponent(0.7)
        attribution.titleLabel?.textColor = UIColor.blue.withAlphaComponent(0.7)
        scrollView.scrollIndicatorInsets.bottom = effectView.frame.height;
    }
    func loadFullSizeImage() -> Void {
        guard image.origImageUrl != nil else {
            return
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        Flickr.sharedInstance().getCellImageConvenience(image.origImageUrl!, completion: { (data) -> Void in
            DispatchQueue.main.async{
                
                self.imageView.image = UIImage(data: data)!
                self.updateZoomScale()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        })
    }
}
extension PhotoViewController: UIGestureRecognizerDelegate{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view!.isDescendant(of: attribution){
            return false
        }
        return true
    }
}

extension PhotoViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView;
    }
}
