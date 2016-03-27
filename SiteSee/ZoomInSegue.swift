//
//  ZoomInSegue.swift
//  SiteSee
//
//  Created by Tom Lai on 3/26/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import UIKit

class ZoomInSegue: UIStoryboardSegue {
    var animateFromRect: CGRect! = CGRectZero
    var duration: NSTimeInterval = 0.4
    override func perform() {
        let sourceViewControllerView = sourceViewController.view
        let destinationViewControllerView = destinationViewController.view
        let window = UIApplication.sharedApplication().keyWindow
        
        let destinationFrame = destinationViewControllerView.frame
        destinationViewControllerView.frame = animateFromRect
        window?.insertSubview(destinationViewControllerView, aboveSubview: sourceViewControllerView)
        
        UIView.animateWithDuration(duration, animations: {
            destinationViewControllerView.frame = destinationFrame
            }) { (Finished) in
                self.sourceViewController.navigationController?.pushViewController(self.destinationViewController, animated: false)
                
        }
    }
}

