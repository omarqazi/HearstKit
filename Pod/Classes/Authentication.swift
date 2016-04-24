//
//  Authentication.swift
//  HearstKit
//
//  Created by Omar Qazi on 4/24/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation

public enum AuthenticationType {
    case Temporary
    case New
    case Session
}

public class Authentication {
    public var strategy: AuthenticationType = .Temporary
    public var mailboxId: String = ""
    public var sessionToken: String = ""
    
    public func socketAuthenticationRequest() -> String {
        switch self.strategy {
        case .New:
            return "{\"auth\":\"new\"}"
        case .Temporary:
            return "{\"auth\":\"temp\"}"
        case .Session:
            return "{\"auth\":\"session\",\"mailbox\":\"\(self.mailboxId)\",\"token\":\"\(self.sessionToken)\"}"

        }
    }
}