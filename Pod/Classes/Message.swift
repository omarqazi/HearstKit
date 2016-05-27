//
//  Message.swift
//  HearstKit
//
//  Created by Omar Qazi on 2/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import SwiftyJSON

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
    public var serverConnection:  Connection?
    
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
        if let createdAt = json["CreatedAt"].string {
            if let createdDate = jsonDateFormatter.dateFromString(createdAt) {
                self.createdAt = createdDate
            }
        }
    }
}