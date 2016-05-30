//
//  HearstStoreTest.swift
//  HearstKit
//
//  Created by Omar Qazi on 5/30/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest

class HearstStoreTest: XCTestCase {
    var db: HearstStore = HearstStore(path: "ayylmao.db")

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}
