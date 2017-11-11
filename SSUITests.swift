//
//  SSUITests.swift
//  SiteSee
//
//  Created by Tom Lai on 3/30/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import XCTest

class SSUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        let app = XCUIApplication()
        setupSnapshot(app)
        continueAfterFailure = true
        app.launch()        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        
        let app = XCUIApplication()
        if app.alerts.count > 0  {
            app.alerts["Allow “SiteSee” to access your location while you use the app?"].collectionViews.buttons["Allow"].tap()
        }
        // screenshot
        Thread.sleep(forTimeInterval: 0.5)
        snapshot("01TapOn+ToDropAPin")
        app.toolbars.buttons["Add"].tap()
        // screenshot
        snapshot("02TapOnPin")
        app.otherElements["Cupertino, California"].tap()

        let cupertinoCaliforniaNavigationBar = app.navigationBars["Cupertino, California"]
        cupertinoCaliforniaNavigationBar.buttons["Edit"].tap()
        snapshot("04TapEditToReorder")
        // screenshot
        let tablesQuery = app.tables
        tablesQuery.buttons["Delete Cupertino, California, \"Cupertino\" redirects here. For the word-processing phenomenon, see Cupertino effect. Cupertino /ˌkuːpərˈtiːnoʊ/ is a city in Santa Clara County, California"].tap()
        snapshot("05OrDelete")
        cupertinoCaliforniaNavigationBar.buttons["Done"].tap()
        // screenshot
        snapshot("03SeeRelevantPhotosAndArticles")
        tablesQuery.children(matching: .cell).element(boundBy: 0).children(matching: .staticText).element.tap()
        snapshot("06ViewPictures")
        // screenshot
        XCUIApplication().collectionViews.cells.element(boundBy: 1).press(forDuration: 1.4);
        snapshot("07LongPressToDelete")
        
    }
    
}
