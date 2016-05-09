//
//  Thread.swift
//  HearstKit
//
//  Created by Omar Qazi on 2/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation

public class Thread {
    public var subject: String = ""
    public var uuid: String = ""
    public var domain: String = ""
    public var identifier: String = ""
    
    public func serverRepresentation() -> [String : AnyObject] {
        let payload = [
            "Subject" : self.subject,
            "Id" : self.uuid,
            "Identifier" : self.identifier,
            "Domain" : self.domain,
        ]
        
        return payload
    }
}