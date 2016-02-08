//
//  Mailbox.swift
//  HearstKit
//
//  Created by Omar Qazi on 2/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import Security

public class Mailbox {
    public var privateKey: SecKey?
    public var publicKey: SecKey?
    
    public func generatePrivateKey(privateTag: String,publicTag: String) -> OSStatus {
        var pubKey, privKey: SecKey?
        
        let publicKeyParameters: [String: AnyObject] = [
            String(kSecAttrIsPermanent): true,
            String(kSecAttrApplicationTag): publicTag
        ]
        let privateKeyParameters: [String: AnyObject] = [
            String(kSecAttrIsPermanent): true,
            String(kSecAttrApplicationTag): privateTag
        ]
        let parameters: [String: AnyObject] = [
            String(kSecAttrKeyType): kSecAttrKeyTypeRSA,
            String(kSecAttrKeySizeInBits): 2048,
            String(kSecPublicKeyAttrs): publicKeyParameters,
            String(kSecPrivateKeyAttrs): privateKeyParameters
        ]
        
        let rv = SecKeyGeneratePair(parameters, &pubKey, &privKey)
        
        if let pk = privKey {
            self.privateKey = pk
            if let pub = pubKey {
                self.publicKey = pub
            }
        }
        
        return rv
    }
    
    public func keyToString(pubKeyTag: String) -> String {
        var dataPointer: AnyObject?
        let query: [String : AnyObject] = [
            String(kSecClass): kSecClassKey,
            String(kSecAttrApplicationTag): pubKeyTag,
            String(kSecReturnData): kCFBooleanTrue,
        ]
        
        let qresult = SecItemCopyMatching(query, &dataPointer)
        
        if (qresult != errSecSuccess) {
            return "error \(qresult)"
        }
        
        if let pubKeyData = dataPointer as! NSData? {
            let bsf = pubKeyData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
            return bsf
        }
        
        return "internal error"
    }
}