//
//  Member.swift
//  HearstKit
//
//  Created by Omar Qazi on 2/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import SwiftyJSON

public class Member {
    public var threadId: String = ""
    public var mailboxId: String = ""
    public var allowRead: Bool = false
    public var allowWrite: Bool = false
    public var allowNotification: Bool = false
    
    public convenience init(json: JSON) {
        self.init()
        self.parse(json)
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
}
