//
//  VTCollectionViewCell.swift
//  SiteSee
//
//  Created by Tom Lai on 2/19/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import UIKit

class VTCollectionViewCell: UICollectionViewCell {
    var delegate: VTCollectionViewCellDelegate!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    func deleteImage() {
        delegate.deleteSelectedImage()
    }
}

protocol VTCollectionViewCellDelegate {
    func deleteSelectedImage()
}
