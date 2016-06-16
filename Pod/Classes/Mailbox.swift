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
import SQLite

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
    public var dbTable = Table("mailboxes")
    
    
    public init() {
        
    }
    
    public convenience init(uuid: String) {
        self.init()
        self.uuid = uuid
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
        jsonDateFormatter.timeZone = NSTimeZone(abbreviation: "UTC")
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
    
    public func selectQuery() -> Table {
        let uuidField = Expression<String>("uuid")
        let selectQuery = self.dbTable.filter(uuidField == self.uuid).limit(1)
        return selectQuery
    }
    
    public func insertQuery() -> Insert {
        let uuid = Expression<String>("uuid")
        let publicKey = Expression<String>("public_key")
        let deviceId = Expression<String>("device_id")
        let downloadedAt = Expression<Int64>("downloaded_at")
        let connectedAt = Expression<Int64>("connected_at")
        let createdAt = Expression<Int64>("created_at")
        let updatedAt = Expression<Int64>("updated_at")
        
        let insertQuery = self.dbTable.insert(
            uuid <- self.uuid,
            publicKey <- self.publicKeyString,
            deviceId <- self.deviceId,
            downloadedAt <- Int64(NSDate().timeIntervalSince1970),
            connectedAt <- Int64(self.connectedAt.timeIntervalSince1970),
            createdAt <- Int64(self.createdAt.timeIntervalSince1970),
            updatedAt <- Int64(self.updatedAt.timeIntervalSince1970)
        )
        return insertQuery
    }
    
    public func updateQuery() -> Update {
        let uuid = Expression<String>("uuid")
        let publicKey = Expression<String>("public_key")
        let deviceId = Expression<String>("device_id")
        let downloadedAt = Expression<Int64>("downloaded_at")
        let connectedAt = Expression<Int64>("connected_at")
        let createdAt = Expression<Int64>("created_at")
        let updatedAt = Expression<Int64>("updated_at")
        
        let updateQuery = self.selectQuery().update(
            uuid <- self.uuid,
            publicKey <- self.publicKeyString,
            deviceId <- self.deviceId,
            downloadedAt <- Int64(NSDate().timeIntervalSince1970),
            connectedAt <- Int64(self.connectedAt.timeIntervalSince1970),
            createdAt <- Int64(self.createdAt.timeIntervalSince1970),
            updatedAt <- Int64(self.updatedAt.timeIntervalSince1970)
        )
        return updateQuery
    }
    
    public func deleteQuery() -> Delete {
        let uuid = Expression<String>("uuid")
        let deleteQuery = self.dbTable.filter(uuid == self.uuid).delete()
        return deleteQuery
    }
    
    public func parseRow(row: Row) {
        let uuid = Expression<String>("uuid")
        let deviceId = Expression<String>("device_id")
        let connectedAt = Expression<Int64>("connected_at")
        let createdAt = Expression<Int64>("created_at")
        let updatedAt = Expression<Int64>("updated_at")
        
        self.uuid = row[uuid]
        self.deviceId = row[deviceId]
        self.connectedAt = NSDate(timeIntervalSince1970: NSTimeInterval(row[connectedAt]))
        self.createdAt = NSDate(timeIntervalSince1970: NSTimeInterval(row[createdAt]))
        self.updatedAt = NSDate(timeIntervalSince1970: NSTimeInterval(row[updatedAt]))
    }
}