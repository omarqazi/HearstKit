//
//  HearstStoreTest.swift
//  HearstKit
//
//  Created by Omar Qazi on 5/30/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest

class HearstStoreTest: XCTestCase {
    var db: HearstStore = HearstStore(path: NSTemporaryDirectory().stringByAppendingString("ayylmao.db"), domain: "chat.smick.co")

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
    
    func testGetMailbox() {
        let mailbox = db.getMailbox("9C11D096-8499-4183-8AB8-B28E9AC87202") { (mb) in
            print("got mailbox from server",mb)
        }
        
        XCTAssert(mailbox == nil,"Expected mailbox to be nil for empty database but something returned")
    }
    
    func testInsertAndSelect() {
        let someUuid = NSUUID().UUIDString.lowercaseString
        let mb = Mailbox(uuid: someUuid)
        mb.deviceId = "hello-world"
        mb.connectedAt = NSDate()
        
        let err = db.createMailbox(mb) { mbx in
            print(mbx)
        }
        
        XCTAssert(err == nil,"Expected mailbox db create to be bil but got: " + err!.localizedDescription)
        
        let mbz = db.getMailbox(someUuid) { mbx in
            print(mbx)
        }
        
        XCTAssert(mbz?.deviceId == mb.deviceId,"Expected store to retrieve device id from db but it did not")
    }
}
