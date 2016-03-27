//
//  PhotoViewController.swift
//  SiteSee
//
//  Created by Tom Lai on 3/26/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {
    var image : Image!
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {

        super.viewDidLoad()
        
        guard let uuid = image.uuid else {
            print("image has no uuid")
            return
        }
        
        imageView.image = UIImage(contentsOfFile: Image.imgPath(uuid))

        loadFullSizeImage()
    }
    
    func loadFullSizeImage() -> Void {
        guard image.origImageUrl != nil else {
            return
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        Flickr.sharedInstance().getCellImageConvenience(image.origImageUrl!, completion: { (data) -> Void in
            dispatch_async(dispatch_get_main_queue()){
                
                UIView.transitionWithView(self.imageView, duration:0.2, options: .TransitionCrossDissolve, animations: {
                    self.imageView.image = UIImage(data: data)!
                    }, completion: nil)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        })
    }
}
