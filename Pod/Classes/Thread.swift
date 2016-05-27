//
//  Thread.swift
//  HearstKit
//
//  Created by Omar Qazi on 2/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import SwiftyJSON

public class Thread {
    public var subject: String = ""
    public var uuid: String = ""
    public var domain: String = ""
    public var identifier: String = ""
    public var createdAt: NSDate = NSDate.distantPast()
    public var updatedAt: NSDate = NSDate.distantPast()
    public var serverConnection:  Connection?
    
    public convenience init(json: JSON) {
        self.init()
        self.parse(json)
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
}