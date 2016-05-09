//
//  Member.swift
//  HearstKit
//
//  Created by Omar Qazi on 2/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation

public class Member {
    public var threadId: String = ""
    public var mailboxId: String = ""
    public var allowRead: Bool = false
    public var allowWrite: Bool = false
    public var allowNotification: Bool = false
    
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
}
