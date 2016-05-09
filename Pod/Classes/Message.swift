//
//  Message.swift
//  HearstKit
//
//  Created by Omar Qazi on 2/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation

public class Message {
    public var uuid: String = ""
    public var body: String = ""
    public var labels: [String : String] = [String : String]()
    public var payload: [String : AnyObject] = [String: AnyObject]()
    public var topic: String = ""
    public var index: Int64 = 0
    public var threadId: String = ""
    public var senderId: String = ""
    public var createdAt: NSDate = NSDate.distantPast()
    
    public func serverRepresentation() -> [String : AnyObject] {
        let payload: [String : AnyObject] = [
            "Id" : self.uuid,
            "Body" : self.body,
            "Labels" : self.labels,
            "Index" : NSNumber(longLong: self.index),
            "Payload" : self.payload,
            "Topic" : self.topic,
            "ThreadId" : self.threadId,
            "SenderMailboxId" : self.senderId,
            
        ]
        
        return payload
    }
}