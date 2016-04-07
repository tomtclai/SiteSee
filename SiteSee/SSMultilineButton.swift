//
//  SSMultilineButton.swift
//  SiteSee
//
//  Created by Tom Lai on 4/7/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import UIKit

class SSMultilineButton: UIButton {

    override func intrinsicContentSize() -> CGSize
    {
        if let titleLabel = self.titleLabel {
            return titleLabel.intrinsicContentSize();
        } else {
            return super.intrinsicContentSize()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let titleLabel = self.titleLabel {
            titleLabel.preferredMaxLayoutWidth = titleLabel.frame.size.width
            super.layoutSubviews()
        }
    }

}
