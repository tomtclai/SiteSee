//
//  NewYorkTimes.swift
//  SiteSee
//
//  Created by Tom Lai on 3/24/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import Foundation
class NewYorkTimes : Model {
    // MARK: Shared Instance
    class func sharedInstance() -> NewYorkTimes {
        struct Singleton {
            static var sharedInstance = NewYorkTimes()
        }
        return Singleton.sharedInstance
    }
}