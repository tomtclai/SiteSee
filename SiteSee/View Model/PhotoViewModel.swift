//
//  PhotoViewModel.swift
//  SiteSee
//
//  Created by Tom Lai on 11/10/17.
//  Copyright © 2017 Lai. All rights reserved.
//

import Foundation
import UIKit
struct PhotoViewModel {
    var flickrPageURL: URL? {
        guard let urlString = imageData.flickrPageUrl else {return nil}
        return URL(string: urlString)
    }
    var image: UIImage? {
        guard let uuid = imageData.uuid else {return nil}
        return UIImage(contentsOfFile: Image.imgPath(uuid))
    }
    var attributionTitle: String? {
        guard let attributionInt = imageData.license?.intValue,
            let ownerName = imageData.ownerName else {
                return nil

        }
        return attributionStr(attributionInt, ownerName: ownerName)
    }
    var attributionLabelText: String? {
        guard let ownerName = imageData.ownerName else {return nil}
        return "Copyright © \(ownerName). No changes were made."
    }
    func downloadFullSizeImage(completion: @escaping (UIImage) -> Void) {
        guard let url = imageData.origImageUrl else {return}
        Flickr.sharedInstance().getCellImageConvenience(url, completion: { (data) -> Void in
            guard let image = UIImage(data: data) else {return}
            completion(image)
        })
    }
    private var imageData : Image
    private func attributionStr(_ flickrLicense: Int, ownerName: String)->String {
        let licenseName = Flickr.Constants.licenseName(flickrLicense)
        if flickrLicense == 7 || flickrLicense == 8 {
            return "\(licenseName ?? "License not available")."
        } else {
            return "This photo is made available under a \(licenseName!) license."
        }
    }
    init(imageData: Image) {
        self.imageData = imageData
    }
}
