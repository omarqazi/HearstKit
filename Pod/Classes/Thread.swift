//
//  Thread.swift
//  HearstKit
//
//  Created by Omar Qazi on 2/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import SwiftyJSON
import SQLite

public class Thread {
    public var subject: String = ""
    public var uuid: String = ""
    public var domain: String = ""
    public var identifier: String = ""
    public var createdAt: NSDate = NSDate.distantPast()
    public var updatedAt: NSDate = NSDate.distantPast()
    public var serverConnection:  Connection?
    public var dbTable = Table("threads")
    
    public convenience init(json: JSON) {
        self.init()
        self.parse(json)
    }
    
    public convenience init(uuid: String) {
        self.init()
        self.uuid = uuid
    }
    
    public func serverRepresentation() -> [String : AnyObject] {
        let payload = [
            "Subject" : self.subject,
            "Id" : self.uuid,
            "Identifier" : self.identifier,
            "Domain" : self.domain,
        ]
        
        return payload
    }
    
    public func parse(json: JSON) {
        if let uuid = json["Id"].string {
            self.uuid = uuid
        }
        
        if let domain = json["Domain"].string {
            self.domain  = domain
        }
        
        if let subject = json["Subject"].string {
            self.subject = subject
        }
        
        if let identifier = json["Identifier"].string {
            self.identifier = identifier
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

    }
    
    public func addMember(member: Member, callback: (Member) -> ()) {
        member.threadId = self.uuid
        self.serverConnection?.createMember(member, callback: callback)
    }
    
    public func addMember(member: Member) {
        self.addMember(member) { mem in
        }
    }
    
    public func sendMessage(message: Message) {
        self.sendMessage(message) { (msg) in
        }
    }
    
    public func sendMessage(message: Message, callback: (Message) -> ()) {
        message.threadId = self.uuid
        self.serverConnection?.createMessage(message, callback: callback)
        
    }
    
    public func messagesSince(lastSequence: Int64, limit: Int, topicFilter: String,callback: ([Message]) -> ()) {
        self.serverConnection?.messagesSince(self, topic: topicFilter, lastSequence: lastSequence, limit: limit, callback: callback)
    }
    
    public func recentMessages(lastSequence: Int64, limit: Int, topicFilter: String, callback: ([Message]) -> ()) {
        self.serverConnection?.recentMessages(self, topic: topicFilter, lastSequence: lastSequence, limit: limit, callback: callback)
    }
    
    public func onMessage(callback: (Message) -> (Bool)) {
        self.serverConnection?.replaceCallback("notification-\(self.uuid)", callback: { (json) -> (Bool) in
            for (_,eventJson):(String, JSON) in json {
                let message = Message(json: eventJson["Payload"])
                let rv = callback(message)
                if rv == true {
                    return true
                }
            }
            return false
        })
    }
    
    public func parseRow(row: Row) {
        self.uuid = row[Expression<String>("uuid")]
        self.identifier = row[Expression<String>("identifier")]
        self.domain = row[Expression<String>("domain")]
        self.subject = row[Expression<String>("subject")]
        self.createdAt = NSDate(timeIntervalSince1970: NSTimeInterval(row[Expression<Int64>("created_at")]))
        self.updatedAt = NSDate(timeIntervalSince1970: NSTimeInterval(row[Expression<Int64>("updated_at")]))
    }
    
    public func insertQuery() -> Insert {
        let insertQuery = self.dbTable.insert(
            Expression<String>("uuid") <- self.uuid,
            Expression<String>("identifier") <- self.identifier,
            Expression<String>("domain") <- self.domain,
            Expression<String>("subject") <- self.subject,
            Expression<Int64>("created_at") <- Int64(self.createdAt.timeIntervalSince1970),
            Expression<Int64>("updated_at") <- Int64(self.updatedAt.timeIntervalSince1970)
        )
        
        return insertQuery
    }
    
    public func selectQuery() -> Table {
        let uuidField = Expression<String>("uuid")
        let selectQuery = self.dbTable.filter(uuidField == self.uuid).limit(1)
        return selectQuery
    }
    
    public func updateQuery() -> Update {
        let updateQuery = self.selectQuery().update(
            Expression<String>("uuid") <- self.uuid,
            Expression<String>("identifier") <- self.identifier,
            Expression<String>("domain") <- self.domain,
            Expression<String>("subject") <- self.subject,
            Expression<Int64>("created_at") <- Int64(self.createdAt.timeIntervalSince1970),
            Expression<Int64>("updated_at") <- Int64(self.updatedAt.timeIntervalSince1970)
        )
        return updateQuery
    }
    
    public func deleteQuery() -> Delete {
        let deleteQuery = self.selectQuery().delete()
        return deleteQuery
    }
}