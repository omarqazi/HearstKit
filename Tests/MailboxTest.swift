//
//  MailboxTest.swift
//  HearstKit
//
//  Created by Omar Qazi on 2/7/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest

class MailboxTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testGenerateKey() {
        let mb = Mailbox()
        let stat = mb.generatePrivateKey()
        XCTAssert(stat == errSecSuccess, "Expected status errSecSuccess but got \(stat)")
        XCTAssert(mb.privateKey != nil, "Expected private key to be generated but found nil")
        XCTAssert(mb.publicKey != nil, "Expected public key to be generated but found nil")
    }
    
    func testGenerateKeyString() {
        let mb = Mailbox()
        let stat = mb.generatePrivateKey()
        XCTAssert(stat == errSecSuccess, "Expected status errSecSuccess but got \(stat)")
        
        let pubKeyString = mb.keyToString()
        let privateKeyString = mb.privateKeyToString()
        
        XCTAssert(!pubKeyString.containsString("error"), "Error generating string for public key: \(pubKeyString)")
        XCTAssert(!privateKeyString.containsString("error"), "Error generating string for private key: \(privateKeyString)")
        
        let pubKeyLength = pubKeyString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        let privateKeyLength = privateKeyString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        
        XCTAssert(privateKeyLength > pubKeyLength, "Expected private key to be bigger than public key")
    }
    
}
