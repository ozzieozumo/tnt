//
//  tntUITests.swift
//  tntUITests
//
//  Created by Luke Everett on 3/30/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import XCTest

class tntUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        
        let app = XCUIApplication()
        let element = app.otherElements.containing(.navigationBar, identifier:"tnt.tntHomeView").children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
        let textField = element.children(matching: .textField).element(boundBy: 0)
        textField.tap()
        textField.typeText("9")
        element.children(matching: .textField).element(boundBy: 1).tap()
        app.buttons["Scores"].tap()
        app.tables["No Scores For This Meet"].buttons["New  Scoresheet"].tap()
        
    }
    
    
    
}
