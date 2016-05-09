//
//  Connection.swift
//  HearstKit
//
//  Created by Omar Qazi on 4/24/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import Starscream
import SwiftyJSON

public class Connection {
    public var socket: WebSocket
    private var connectionStarted = false
    public var auth: Authentication = Authentication()
    public var onConnect: ((Void) -> Void)?
    public var onDisconnect: ((NSError?) -> Void)?
    public var onText: ((String) -> Void)?
    private var requestCallbacks: [String : [(JSON) -> (Bool)]] = [:]
    private var writeQueue: dispatch_queue_t = dispatch_queue_create("co.smick.hearstkit.writeq", DISPATCH_QUEUE_SERIAL)
    
    init(serverDomain: String) {
        let socketUrl = NSURL(string: "wss://\(serverDomain)/sock/")!
        self.socket = WebSocket(url: socketUrl)
    }
    
    public func connect() -> Bool {
        if self.socket.isConnected {
            return true
        }
        
        socket.onConnect = self.socketDidConnect
        socket.onDisconnect = self.socketDidDisconnect
        socket.onText = self.socketGotText
        
        socket.onData = { (data: NSData) in
            print("got some data: \(data.length)")
        }
        socket.onPong = {
            print("PONG")
        }
        
        socket.connect()
        return true
    }
    
    private func socketDidConnect() {
        dispatch_sync(self.writeQueue) {
            self.socket.writeString(self.auth.socketAuthenticationRequest())
        }
        
        if let oc = self.onConnect {
            oc()
        }
    }
    
    private func socketDidDisconnect(error: NSError?) {
        if let odc = self.onDisconnect {
            odc(error)
        }
    }
    
    private func socketGotText(text: String) {
        if let otxt = self.onText {
            otxt(text)
        }
        
        let jsonData = text.dataUsingEncoding(NSUTF8StringEncoding)
        let json = JSON(data: jsonData!)
        
        var objectId = json["Id"].string
        if objectId == nil {
            objectId = json["rid"].string
        }
        if objectId == nil {
            let threadId = json["ThreadId"].string
            let mailboxId = json["MailboxId"].string
            if threadId != nil && mailboxId != nil {
                objectId = "\(threadId)-\(mailboxId)"
            }
        }
        if objectId == nil {
            print("got something but couldnt find id")
            return
        }
        
        if let callbacks = self.requestCallbacks[objectId!] {
            var newCallbacks: [(JSON) -> (Bool)] = []
            
            for callback in callbacks {
                let doneListening = callback(json)
                if !doneListening {
                    newCallbacks.append(callback)
                }
            }
            
            if newCallbacks.count == 0 {
                self.requestCallbacks.removeValueForKey(objectId!)
            } else {
                 self.requestCallbacks[objectId!] = newCallbacks
            }
        }
        
    }
    
    public func disconnect() -> Bool {
        self.socket.disconnect()
        return true
    }
    
    public func sendObject(commands: AnyObject...) -> Bool {
        do {
            var jsonStrings = [String]()
            for command in commands {
                let jsonData = try NSJSONSerialization.dataWithJSONObject(command, options: [])
                let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding)
                jsonStrings.append(jsonString!)
            }
            dispatch_async(self.writeQueue) {
                for jsonString in jsonStrings {
                     self.socket.writeString(jsonString)
                }
            }
            return true
        } catch {
            return false
        }
    }
    
    // Payload must be serializable by NSJSONSerialization
    // Your model class should generate an NSDictionary or similar of how it was to be serialized
    public func createModel(modelName: String,payload: AnyObject,callback: (JSON) -> (Bool)) {
        let rid = NSUUID().UUIDString
        self.addCallback(rid, callback: callback)
        self.sendObject(["action" : "create", "model" : modelName, "rid" : rid])
        self.sendObject(payload)
    }
    
    public func createMailbox(mb: Mailbox, callback: (JSON) -> (Bool)) {
        self.createModel("mailbox", payload: mb.serverRepresentation(),callback: callback)
    }
    
    public func createThread(tr: Thread, callback: (JSON) -> (Bool)) {
        self.createModel("thread", payload: tr.serverRepresentation(), callback: callback)
    }
    
    public func createMember(mem: Member, callback: (JSON) -> (Bool)) {
        self.createModel("threadmember", payload: mem.serverRepresentation(), callback: callback)
    }
    
    public func createMessage(msg: Message, callback: (JSON) -> (Bool)) {
        self.createModel("message", payload: msg.serverRepresentation(),callback: callback)
    }
    
    public func getMailbox(uuid: String, callback: (Mailbox) -> ()) {
        self.addCallback(uuid) { (json) -> (Bool) in
            let mailbox = Mailbox(json: json)
            callback(mailbox)
            return true
        }
        self.sendObject(["action" : "read", "model" : "mailbox","id" : uuid])
    }
    
    public func getThread(uuid: String, callback: (Thread) -> ()) {
        // let us know when you get a response
        self.addCallback(uuid) { (json) -> (Bool) in
            let thread = Thread(json: json)
            callback(thread)
            return true
        }
        self.sendObject(["action" : "read", "model" : "thread","id" : uuid]) // send request
    }
    
    public func getMember(threadId: String, mailboxId: String, callback: (Member) -> ()) {
        let combinedId = "\(threadId)-\(mailboxId)"
        self.addCallback(combinedId) { (json) -> (Bool) in
            let member = Member(json: json)
            callback(member)
            return true
        }
        self.sendObject(["action" : "read", "model": "threadmember","thread_id":threadId,"mailbox_id":mailboxId])
    }
    
    public func getMessage(uuid: String, callback: (Message) -> ()) {
        self.addCallback(uuid) { (json) -> (Bool) in
            let message = Message(json: json)
            callback(message)
            return true
        }
        self.sendObject(["action" : "read", "model" : "message","id" : uuid])

    }
    
    public func updateMailbox(mb: Mailbox,callback: (Mailbox) -> ()) {
        self.addCallback(mb.uuid) { (json) -> (Bool) in
            let mbx = Mailbox(json: json)
            callback(mbx)
            return true
        }
    }
    
    private func addCallback(uuid: String, callback: (JSON) -> (Bool)) {
        if self.requestCallbacks[uuid] == nil {
            requestCallbacks[uuid] = [callback]
        } else {
            requestCallbacks[uuid]?.append(callback)
        }
    }
}