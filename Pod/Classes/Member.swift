//
//  Member.swift
//  HearstKit
//
//  Created by Omar Qazi on 2/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import SwiftyJSON
import SQLite

public class Member {
    public var threadId: String = ""
    public var mailboxId: String = ""
    public var allowRead: Bool = false
    public var allowWrite: Bool = false
    public var allowNotification: Bool = false
    public var serverConnection:  Connection?
    public var dbTable = Table("thread_members")

    public convenience init(json: JSON) {
        self.init()
        self.parse(json)
    }
    
    public convenience init(threadId: String, mailboxId: String) {
        self.init()
        self.threadId = threadId
        self.mailboxId = mailboxId
    }
    
    public func serverRepresentation() -> [String : AnyObject] {
        let payload: [String : AnyObject] = [
            "ThreadId" : self.threadId,
            "MailboxId" : self.mailboxId,
            "AllowRead" : self.allowRead,
            "AllowWrite" : self.allowWrite,
            "AllowNotification" : self.allowNotification,
        ]
        
        return payload
    }
    
    public func parse(json: JSON) {
        if let threadId = json["ThreadId"].string {
            self.threadId = threadId
        }
        
        if let mailboxId = json["MailboxId"].string {
            self.mailboxId = mailboxId
        }
        
        if let allowRead = json["AllowRead"].bool {
            self.allowRead = allowRead
        }
        
        if let allowWrite = json["AllowWrite"].bool {
            self.allowWrite = allowWrite
        }
        
        if let allowNotification = json["AllowNotification"].bool {
            self.allowNotification = allowNotification
        }
    }
    
    public func parseRow(row: Row) {
        self.threadId = row[Expression<String>("thread_id")]
        self.mailboxId = row[Expression<String>("mailbox_id")]
        self.allowRead = row[Expression<Bool>("allow_read")]
        self.allowWrite = row[Expression<Bool>("allow_write")]
        self.allowNotification = row[Expression<Bool>("allow_notification")]
    }
    
    public func insertQuery() -> Insert {
        let insertQuery = self.dbTable.insert(
            Expression<String>("thread_id") <- self.threadId,
            Expression<String>("mailbox_id") <- self.mailboxId,
            Expression<Bool>("allow_read") <- self.allowRead,
            Expression<Bool>("allow_write") <- self.allowWrite,
            Expression<Bool>("allow_notification") <- self.allowNotification
        )
        return insertQuery
    }
    
    public func selectQuery() -> Table {
        let selectQuery = dbTable.filter(Expression<String>("thread_id") == self.threadId).filter(Expression<String>("mailbox_id") == self.mailboxId).limit(1)
        return selectQuery
    }
    
    public func updateQuery() -> Update {
        let updateQuery = self.selectQuery().update(
            Expression<String>("thread_id") <- self.threadId,
            Expression<String>("mailbox_id") <- self.mailboxId,
            Expression<Bool>("allow_read") <- self.allowRead,
            Expression<Bool>("allow_write") <- self.allowWrite,
            Expression<Bool>("allow_notification") <- self.allowNotification
        )
        return updateQuery
    }
    
    public func deleteQuery() -> Delete {
        let deleteQuery = self.selectQuery().delete()
        return deleteQuery
    }
}
