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
    var photoViewModel: PhotoViewModel!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var effectView: UIVisualEffectView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var attributionLabel: UILabel!
    @IBOutlet weak var attribution: UIButton!
    @IBOutlet weak var imageView: UIImageView!

    
    @IBAction func tapped(_ sender: UITapGestureRecognizer) {
        showFlickrPage()
    }
    func showFlickrPage() {
        guard let url = photoViewModel.flickrPageURL else {return}
        let sfv = SFSafariViewController(url: url)
        navigationController?.isNavigationBarHidden = true
        sfv.delegate = self
        present(sfv, animated: true, completion: nil)
    }
    override func viewDidLoad() {

        super.viewDidLoad()
        imageView.image = photoViewModel.image
        updateZoomScale()
        scrollView.delegate = self
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .automatic
        }
        setupAttributions()
        loadFullSizeImage()
    }

    override func viewWillLayoutSubviews() {
        updateZoomScale()
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

    func updateZoomScale() {
        let viewSize = scrollView.bounds.size
        guard let imageSize = self.imageView.image?.size else {
            return
        }
        let xScale = viewSize.width / imageSize.width
        let yScale = viewSize.height / imageSize.height
        scrollView.minimumZoomScale = min(xScale, yScale)
        scrollView.maximumZoomScale = max(xScale, yScale)
        scrollView.zoomScale = scrollView.minimumZoomScale
    }
    @IBAction func attributionTapped(_ sender: UIButton) {
        showFlickrPage()
    }
    func setupAttributions() -> Void {
        attribution.setTitle(photoViewModel.attributionTitle, for: .normal)
        attribution.titleLabel?.textAlignment = .center
        attributionLabel.text = photoViewModel.attributionLabelText
        attributionLabel.textColor = UIColor.black.withAlphaComponent(0.7)
        attribution.titleLabel?.textColor = UIColor.blue.withAlphaComponent(0.7)
        scrollView.scrollIndicatorInsets.bottom = effectView.frame.height;
    }
    func loadFullSizeImage() -> Void {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        photoViewModel.downloadFullSizeImage { [weak self] image in
            DispatchQueue.main.async {
                guard let strongSelf = self else {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    return
                }
                strongSelf.imageView.image = image
                strongSelf.updateZoomScale()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
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
extension PhotoViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        navigationController?.isNavigationBarHidden = false
    }
}
