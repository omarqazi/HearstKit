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
        db.server?.connect()
        let expectation = self.expectationWithDescription("server connected")
        db.server?.onConnect = {
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(5.0) { (err) in
            if err != nil {
                XCTFail("Did not connect to server in time: \(err?.localizedDescription)")
            }
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDontAutomaticallyConnectOnInit() {
        let hs = HearstStore(path: NSTemporaryDirectory().stringByAppendingString("ayylmao.db"), domain: "chat.smick.co")
        XCTAssert(hs.server?.socket.isConnected == false,"datastore should not automatically connect to server on init")
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
    
    func testUpdate() {
        let someUuid = NSUUID().UUIDString.lowercaseString
        print(someUuid)
        let mb = Mailbox(uuid: someUuid)
        mb.deviceId = "hello-world"
        mb.connectedAt = NSDate()
        
        let serverExpectation = self.expectationWithDescription("server returned mailbox")
        
        let emb = db.getMailbox(someUuid) { smb in
            print("RETURNED FROM GET",smb.serverRepresentation())
        }
        
        XCTAssert(emb == nil,"Expected mailbox to not exist, but found something when calling get")
        
        let insertErr = db.createMailbox(mb) { mb in
            serverExpectation.fulfill()
            XCTAssert(mb.uuid.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 ,"Unexpected UUID")
        }
        
        XCTAssert(insertErr == nil,"Expected mailbox to insert but db returned err \(insertErr?.localizedDescription)")
        
        self.waitForExpectationsWithTimeout(5.0) { (err) in
            if err != nil {
                XCTFail("Server never returned from create mailbox command")
            }
        }
        
        let getExpectation = self.expectationWithDescription("got created mailbox from server")
        let imb = db.getMailbox(someUuid) { mbx in
            mbx.deviceId = "hello-mars"
            let er = self.db.updateMailbox(mbx) { umb in
            }
            XCTAssert(er == nil,"Expected no database error but got \(er!.localizedDescription)")
            
            let marsmb = self.db.getMailbox(someUuid) { mbxx in
                XCTAssert(mbxx.deviceId == mbx.deviceId,"Expected device ID to be updated but it was not")
            }
            
            XCTAssert(marsmb?.deviceId == mbx.deviceId,"Expected device ID to be updated but it was not")
            getExpectation.fulfill()
        }
        
        XCTAssert(imb != nil,"Expected mailbox to exist after being created")
        self.waitForExpectationsWithTimeout(5.0) { (err) in
            if err != nil {
                XCTFail("Server never returned from get mailbox command")
            }
        }
    }
}
