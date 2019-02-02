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
  @IBOutlet weak var effectView: UIVisualEffectView!
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var attributionLabel: UILabel!
  @IBOutlet weak var attribution: UIButton!
  @IBOutlet weak var imageView: UIImageView!
  func attributionStr(_ flickrLicense: Int, ownerName: String)->String {
    let licenseName = Flickr.Constants.licenseName(flickrLicense)
    if flickrLicense == 7 || flickrLicense == 8 {
      return "\(licenseName ?? "-")"
    } else {
      return "This photo is made available under a \(licenseName!) license"
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
    scrollView.delegate = self
    setupAttributions()
    loadFullSizeImage()
  }



  func updateZoom() {
    guard let image = imageView?.image else { return }
    let scrollViewSize = scrollView.bounds.size
    let imageSize = image.size
    let zoomScale = min(scrollViewSize.width / imageSize.width,
                        scrollViewSize.height / imageSize.height)
    if zoomScale > 1 {
      self.scrollView.minimumZoomScale = 1
    }

    self.scrollView.minimumZoomScale = zoomScale
    self.scrollView.zoomScale = zoomScale
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
    guard image.origImageUrl != nil else { return }
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    Flickr.sharedInstance().getCellImageConvenience(image.origImageUrl!, completion: { [weak self] (data) -> Void in
      guard let self = self else { return }
      guard let image = UIImage(data: data) else { return }
      self.imageView.image = image
      self.updateZoom()
      self.centerImage()
      UIApplication.shared.isNetworkActivityIndicatorVisible = false
    })
  }

  func centerImage() {
    guard let subView = scrollView.subviews.first else { return }
    let xOffset = max((scrollView.bounds.size.width - scrollView.contentSize.width) / 2.0, 0.0)
    let yOffset = max((scrollView.bounds.size.height - scrollView.contentSize.height) / 2.0, 0.0)
    subView.center = CGPoint(x: scrollView.contentSize.width / 2.0 + xOffset,
                             y: scrollView.contentSize.height / 2.0 + yOffset)
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

  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    centerImage()
  }
}
