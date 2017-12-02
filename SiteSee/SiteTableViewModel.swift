//
//  SiteTableViewModel.swift
//  SiteSee
//
//  Created by Tom Lai on 11/24/17.
//  Copyright © 2017 Lai. All rights reserved.
//

import Foundation
import UIKit

struct SiteTableViewModel {


    var annotation: VTAnnotation
    let placeholderImage = UIImage(named: "placeholder")!
    private func locationIsLoadedKey() -> String {
        return "locationIsLoaded: \(annotation.latitude) \(annotation.longitude)"
    }
    private func convertIndexPathForFetchedResultsController(_ indexPath: IndexPath) -> IndexPath {
        return setSectionForIndexPath(indexPath, section: 0)!
    }
    private func setSectionForIndexPath(_ indexPath: IndexPath?, section:Int) -> IndexPath? {
        guard let indexPath = indexPath else {
            return nil
        }
        return IndexPath(row: indexPath.row, section: section)
    }
    func wikipediaURL(atIndexPath indexPath: IndexPath) -> URL? {
        let fi = convertIndexPathForFetchedResultsController(indexPath)
        guard let article = fetchedArticlesController.object(at: fi) as? Article  else {
            print("fetched result not an article")
            return nil
        }
        guard let title = article.title else {
            print("article does not have a title")
            return nil
        }
        guard let urlEncodedTitle = title.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlUserAllowed) else {
            print("title did not encode: \(title)")
            return nil
        }
        let urlStr = Wikipedia.Constants.userBaseUrl + urlEncodedTitle

        guard let url = URL(string: urlStr) else {
            print("\(urlStr) is not a valid url")
            return nil
        }
        return url
    }
}
