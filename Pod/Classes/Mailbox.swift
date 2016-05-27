//
//  Mailbox.swift
//  HearstKit
//
//  Created by Omar Qazi on 2/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import Security
import SwiftyJSON

let jsonDateFormatter = NSDateFormatter()

public class Mailbox {
    public var privateKey: SecKey?
    public var publicKey: SecKey?
    public var privateKeyTag: String = "co.smick.hearst.defaultkey.private"
    public var publicKeyTag: String = "co.smick.hearst.defaultkey.public"
    public var publicKeyString: String = ""
    public var uuid: String = ""
    public var deviceId: String = ""
    public var connectedAt: NSDate = NSDate.distantPast()
    public var createdAt: NSDate = NSDate.distantPast()
    public var updatedAt: NSDate = NSDate.distantPast()
    public var serverConnection:  Connection?
    
    
    public init() {
        
    }
    
    public convenience init(json: JSON) {
        self.init()
        self.parse(json)
    }
    
    public func generatePrivateKey() -> OSStatus {
        var pubKey, privKey: SecKey?
        
        let publicKeyParameters: [String: AnyObject] = [
            String(kSecAttrIsPermanent): true,
            String(kSecAttrApplicationTag): self.publicKeyTag
        ]
        let privateKeyParameters: [String: AnyObject] = [
            String(kSecAttrIsPermanent): true,
            String(kSecAttrApplicationTag): self.privateKeyTag
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
    
    public func keyToString() -> String {
        return self.taggedKeyToString(self.publicKeyTag)
    }
    
    internal func privateKeyToString() -> String {
        return self.taggedKeyToString(self.privateKeyTag)
    }
    
    public func taggedKeyToString(keyTag: String) -> String {
        var dataPointer: AnyObject?
        let query: [String : AnyObject] = [
            String(kSecClass): kSecClassKey,
            String(kSecAttrApplicationTag): keyTag,
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
    
    public func parse(json: JSON) {
        if let uuid = json["Id"].string {
            self.uuid = uuid
        }
        
        if let deviceId = json["DeviceId"].string {
            self.deviceId = deviceId
        }
        
        if let publicKey = json["PublicKey"].string {
            self.publicKeyString = publicKey
        }
        
        jsonDateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
        if let createdAt = json["CreatedAt"].string {
            if let createdDate = jsonDateFormatter.dateFromString(createdAt) {
                self.createdAt = createdDate
            }
        }
        if let updatedAt = json["UpdatedAt"].string {
            if let updatedDate = jsonDateFormatter.dateFromString(updatedAt) {
                self.updatedAt = updatedDate
            }
        }
        
        if let connectedAt = json["ConnectedAt"].string {
            if let connectedDate = jsonDateFormatter.dateFromString(connectedAt) {
                self.connectedAt = connectedDate
            }
        }
    }
    
    public func serverRepresentation() -> [String : AnyObject] {
        jsonDateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
        let payload = [
            "Id" : self.uuid,
            "PublicKey" : self.keyToString(),
            "DeviceId" : self.deviceId,
            "ConnectedAt" : jsonDateFormatter.stringFromDate(self.connectedAt)
        ]
        return payload
    }
    
    // func payloadData returns a serialized NSData representation of the object
    // Serialization format is json
    public func payloadData() -> NSData {
        jsonDateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
        let payload: [String : AnyObject] = [
            "Id" : self.uuid,
            "PublicKey" : self.keyToString(),
            "DeviceId" : self.deviceId,
        ]
        
        var jsonData: NSData?
        do {
            jsonData = try NSJSONSerialization.dataWithJSONObject(payload, options: [])
        } catch {
            jsonData = NSData()
        }
        
        return jsonData!
    }
    
    // Returns payloadData() as a string by assuming UTF8 string encoding type and JSON
    public func payload() -> String {
        return String(data: self.payloadData(), encoding: NSUTF8StringEncoding)!
    }
}