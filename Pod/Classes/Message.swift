//
//  Message.swift
//  HearstKit
//
//  Created by Omar Qazi on 2/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import SwiftyJSON
import SQLite
var relativeDateFormatter: NSDateFormatter?

public class Message {
    public var uuid: String = ""
    public var body: String = ""
    public var labels: JSON = JSON([:])
    public var payload: JSON = JSON([:])
    public var topic: String = ""
    public var index: Int64 = 0
    public var threadId: String = ""
    public var senderId: String = ""
    public var createdAt: NSDate = NSDate.distantPast()
    public var expiresAt: NSDate = NSDate.distantFuture()
    public var dbTable = Table("messages")
    public var serverConnection:  Connection?
    var sqlValues: [Setter] {
        var rawLabels = self.labels.rawString()
        var rawPayload = self.payload.rawString()
        
        if rawLabels == nil {
            rawLabels = "{}"
        }
        if rawPayload == nil {
            rawPayload = "{}"
        }
        
        let setters = [
            Expression<String>("uuid") <- self.uuid,
            Expression<String>("thread_id") <- self.threadId,
            Expression<String>("sender_id") <- self.senderId,
            Expression<Int64>("created_at") <- Int64(self.createdAt.timeIntervalSince1970),
            Expression<Int64>("expires_at") <- Int64(self.expiresAt.timeIntervalSince1970),
            Expression<String>("topic") <- self.topic,
            Expression<String>("body") <- self.body,
            Expression<String>("labels") <- rawLabels!,
            Expression<String>("payload") <- rawPayload!,
            Expression<Int64>("index") <- self.index
        ]
        return setters
    }
    var dateFormatter: NSDateFormatter {
        if relativeDateFormatter == nil {
            relativeDateFormatter = NSDateFormatter()
            relativeDateFormatter?.locale = NSLocale.autoupdatingCurrentLocale()
            relativeDateFormatter?.timeStyle = .ShortStyle
            relativeDateFormatter?.dateStyle = .NoStyle
            relativeDateFormatter?.doesRelativeDateFormatting = true
        }
        return relativeDateFormatter!
    }
    
    public convenience init(uuid: String) {
        self.init()
        self.uuid = uuid
    }
    
    public convenience init(body: String) {
        self.init()
        self.body = body
    }
    
    public convenience init(body: String, topic: String) {
        self.init()
        self.body = body
        self.topic = topic
    }
    
    public convenience init(body: String, labels: AnyObject, topic: String) {
        self.init()
        self.body = body
        self.labels = JSON(labels)
        self.topic = topic
    }
    
    public convenience init(payload: AnyObject, labels: AnyObject, topic: String) {
        self.init()
        self.body = ""
        self.payload = JSON(payload)
        self.labels = JSON(labels)
        self.topic = topic
    }
    
    public convenience init(json: JSON) {
        self.init()
        self.parse(json)
    }
    
    public func serverRepresentation() -> [String : AnyObject] {
        let labelsJson = self.labels.rawString(NSUTF8StringEncoding, options: [])!
        let payloadJson = self.payload.rawString(NSUTF8StringEncoding, options: [])!

        let payload: [String : AnyObject] = [
            "Id" : self.uuid,
            "Body" : self.body,
            "Labels" : labelsJson,
            "Index" : NSNumber(longLong: self.index),
            "Payload" : payloadJson,
            "Topic" : self.topic,
            "ThreadId" : self.threadId,
            "SenderMailboxId" : self.senderId,
        ]
        
        return payload
    }
    
    func relativeSendTime() -> String {
        return self.dateFormatter.stringFromDate(self.createdAt)
    }
    
    public func parse(json: JSON) {
        if let uuid = json["Id"].string {
            self.uuid = uuid
        }
        
        if let body = json["Body"].string {
            self.body = body
        }
        
        self.labels = json["Labels"]
        self.payload = json["Payload"]
        
        if let index = json["Index"].int64 {
            self.index = index
        }
        
        if let topic = json["Topic"].string {
            self.topic = topic
        }
        
        if let threadId = json["ThreadId"].string {
            self.threadId = threadId
        }
        
        if let senderId = json["SenderMailboxId"].string {
            self.senderId = senderId
        }
        
        jsonDateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
        jsonDateFormatter.timeZone = NSTimeZone(abbreviation: "UTC")
        if let createdAt = json["CreatedAt"].string {
            if let createdDate = jsonDateFormatter.dateFromString(createdAt) {
                self.createdAt = createdDate
            }
        }
    }
    
    public func parseRow(row: Row) {
        self.uuid = row[Expression<String>("uuid")]
        self.threadId = row[Expression<String>("thread_id")]
        self.senderId = row[Expression<String>("sender_id")]
        self.createdAt = NSDate(timeIntervalSince1970: NSTimeInterval(row[Expression<Int64>("created_at")]))
        self.expiresAt = NSDate(timeIntervalSince1970: NSTimeInterval(row[Expression<Int64>("expires_at")]))
        self.topic = row[Expression<String>("topic")]
        self.body = row[Expression<String>("body")]
        let labelData = row[Expression<String>("labels")].dataUsingEncoding(NSUTF8StringEncoding)
        let payloadData = row[Expression<String>("payload")].dataUsingEncoding(NSUTF8StringEncoding)
        if let ld = labelData {
            self.labels = JSON(data: ld)
        }
        if let pd = payloadData {
            self.payload = JSON(data: pd)
        }
        self.index = row[Expression<Int64>("index")]
    }
    
    public func insertQuery() -> Insert {
        return self.dbTable.insert(self.sqlValues)
    }
    
    public func selectQuery() -> Table {
        return self.dbTable.filter(Expression<String>("uuid") == self.uuid).limit(1)
    }
    
    public func updateQuery() -> Update {
        return self.dbTable.update(self.sqlValues)
    }
    
    public func deleteQuery() -> Delete {
        return self.selectQuery().delete()
    }
}