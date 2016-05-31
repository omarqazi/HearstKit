//
//  HearstStoreTest.swift
//  HearstKit
//
//  Created by Omar Qazi on 5/30/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest

class HearstStoreTest: XCTestCase {
    var db: HearstStore = HearstStore(path: "ayylmao.db", domain: "chat.smick.co")

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDontAutomaticallyConnectOnInit() {
        XCTAssert(self.db.server?.socket.isConnected == false,"datastore should not automatically connect to server on init")
    }
}
