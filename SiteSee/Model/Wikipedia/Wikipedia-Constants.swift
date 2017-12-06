//
//  Wikipedia-Constants.swift
//  SiteSee
//
//  Created by Tom Lai on 3/22/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import Foundation
extension Wikipedia {
    struct Constants {
        // TODO: consider changing language based on region setting
        static let userBaseUrl = "https://en.wikipedia.org/wiki/"
        static let baseUrl = "https://en.wikipedia.org/w/api.php"
        static let format = "json"
    }
    
    struct Actions {
        static let query = "query"
    }
    
    struct List {
        static let search = "search"
        static let geoSearch = "geosearch"
    }
    
}