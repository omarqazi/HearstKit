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
    public var onMessage: ((Message) -> Void)?
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
        
        var objectId = json["Id"].string // Find callback by Id
        
        if objectId == nil {
            objectId = json["rid"].string // or request ID
        }
        
        // or by the thread id + mailbox id if a member
        if objectId == nil { // for members, which don't have an Id
            let threadId = json["ThreadId"].string
            let mailboxId = json["MailboxId"].string
            if threadId != nil && mailboxId != nil {
                objectId = "\(threadId)-\(mailboxId)"
            }
        }
        
        // or using a notification callback
        if json[0]["ModelClass"].string == "message" {
            for (_,eventJson):(String, JSON) in json {
                let message = Message(json: eventJson["Payload"])
                
                if let om = self.onMessage {
                    om(message)
                }
                
                objectId = "notification-\(message.threadId)"
            }
        }
        
        if objectId == nil { // huh? this shouldn't happen
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
    
    public func knownThread(uuid: String) -> Thread {
        let thread = Thread()
        thread.uuid  = uuid
        thread.serverConnection = self
        return thread
    }
    
    // Payload must be serializable by NSJSONSerialization
    // Your model class should generate an NSDictionary or similar of how it was to be serialized
    public func createModel(modelName: String,payload: AnyObject,callback: (JSON) -> (Bool)) {
        let rid = NSUUID().UUIDString
        self.addCallback(rid, callback: callback)
        self.sendObject(["action" : "create", "model" : modelName, "rid" : rid],payload)
    }
    
    public func createMailbox(mb: Mailbox, callback: (Mailbox) -> ()) {
        self.createModel("mailbox", payload: mb.serverRepresentation()) { (json) -> (Bool) in
            let mb = Mailbox(json: json)
            mb.serverConnection = self
            callback(mb)
            return true
        }
    }
    
    public func createThread(tr: Thread, callback: (Thread) -> ()) {
        self.createModel("thread", payload: tr.serverRepresentation()) { (json) -> (Bool) in
            let tr = Thread(json: json)
            tr.serverConnection = self
            callback(tr)
            return true
        }
    }
    
    public func createMember(mem: Member, callback: (Member) -> (Bool)) {
        self.createModel("threadmember", payload: mem.serverRepresentation()) { (json) -> (Bool) in
            let mem = Member(json: json)
            mem.serverConnection = self
            callback(mem)
            return true
        }
    }
    
    public func createMessage(msg: Message, callback: (Message) -> ()) {
        self.createModel("message", payload: msg.serverRepresentation()) { (json) -> (Bool) in
            let msg = Message(json: json)
            msg.serverConnection = self
            callback(msg)
            return true
        }
    }
    
    public func getMailbox(uuid: String, callback: (Mailbox) -> ()) {
        self.addCallback(uuid) { (json) -> (Bool) in
            let mailbox = Mailbox(json: json)
            mailbox.serverConnection = self
            callback(mailbox)
            return true
        }
        self.sendObject(["action" : "read", "model" : "mailbox","id" : uuid])
    }
    
    public func getThread(uuid: String, callback: (Thread) -> ()) {
        // let us know when you get a response
        self.addCallback(uuid) { (json) -> (Bool) in
            let thread = Thread(json: json)
            thread.serverConnection = self
            callback(thread)
            return true
        }
        self.sendObject(["action" : "read", "model" : "thread","id" : uuid]) // send request
    }
    
    public func getMember(threadId: String, mailboxId: String, callback: (Member) -> ()) {
        let combinedId = "\(threadId)-\(mailboxId)"
        self.addCallback(combinedId) { (json) -> (Bool) in
            let member = Member(json: json)
            member.serverConnection = self
            callback(member)
            return true
        }
        self.sendObject(["action" : "read", "model": "threadmember","thread_id":threadId,"mailbox_id":mailboxId])
    }
    
    public func getMessage(uuid: String, callback: (Message) -> ()) {
        self.addCallback(uuid) { (json) -> (Bool) in
            let message = Message(json: json)
            message.serverConnection = self
            callback(message)
            return true
        }
        self.sendObject(["action" : "read", "model" : "message","id" : uuid])

    }
    
    public func updateMailbox(mb: Mailbox,callback: (Mailbox) -> ()) {
        self.addCallback(mb.uuid) { (json) -> (Bool) in
            let mbx = Mailbox(json: json)
            mb.serverConnection = self
            callback(mbx)
            return true
        }
        self.sendObject(["action":"update","model":"mailbox"],mb.serverRepresentation())
    }
    
    public func updateThread(tr: Thread,callback: (Thread) -> ()) {
        self.addCallback(tr.uuid) { (json) -> (Bool) in
            let tx = Thread(json: json)
            tx.serverConnection = self
            callback(tx)
            return true
        }
        self.sendObject(["action":"update","model":"thread"],tr.serverRepresentation())
    }
    
    public func updateMember(mem: Member,callback: (Member) -> ()) {
        let combinedId = "\(mem.threadId)-\(mem.mailboxId)"
        self.addCallback(combinedId) { (json) -> (Bool) in
            let mem = Member(json: json)
            mem.serverConnection = self
            callback(mem)
            return true
        }
        self.sendObject(["action":"update","model":"threadmember"],mem.serverRepresentation())
    }
    
    public func deleteMailbox(mb: Mailbox, callback: (Mailbox) -> ()) {
        self.addCallback(mb.uuid) { (json) -> (Bool) in
            let mbx = Mailbox(json: json)
            mbx.serverConnection = self
            callback(mbx)
            return true
        }
        self.sendObject(["action" : "delete", "model":"mailbox","id" : mb.uuid])
    }
    
    public func deleteThread(tr: Thread, callback: (Thread) -> ()) {
        self.addCallback(tr.uuid) { (json) -> (Bool) in
            let trx = Thread(json: json)
            trx.serverConnection = self
            callback(trx)
            return true
        }
        self.sendObject(["action":"delete","model":"thread","id":tr.uuid])
    }
    
    public func deleteMember(mem: Member, callback: (Member) -> ()) {
        let combinedId = "\(mem.threadId)-\(mem.mailboxId)"
        self.addCallback(combinedId) { (json) -> (Bool) in
            let memx = Member(json: json)
            memx.serverConnection = self
            callback(memx)
            return true
        }
        self.sendObject(["action":"delete","model":"threadmember","mailbox_id":mem.mailboxId,"thread_id":mem.threadId])
    }
    
    public func listThread(thread: Thread,topic: String, lastSequence: Int64, limit: Int, choose: String, callback: ([Message]) -> ()) {
        let rid = NSUUID().UUIDString
        self.addCallback(rid) { (json) -> (Bool) in
            var messages = [Message]()
            if let listResponse = json["payload"].array {
                for messageJson in listResponse {
                    let mess = Message(json: messageJson)
                    mess.serverConnection = self
                    messages.append(mess)
                }
                callback(messages)
            }
            
            return true
        }
        self.sendObject([
            "action":"list",
            "model":"thread",
            "id":thread.uuid,
            "topic" : topic,
            "lastsequence" : "\(lastSequence)",
            "limit":"\(limit)",
            "rid" : rid,
            "choose" : choose
        ])
    }
    
    public func messagesSince(thread: Thread,topic: String,lastSequence: Int64, limit: Int, callback: ([Message]) -> ()) {
        self.listThread(thread, topic: topic, lastSequence: lastSequence, limit: limit, choose: "first", callback: callback)
    }
    
    public func recentMessages(thread: Thread, topic: String, lastSequence: Int64, limit: Int, callback: ([Message]) -> ()) {
        self.listThread(thread, topic: topic, lastSequence: lastSequence, limit: limit, choose: "latest", callback: callback)
    }
    
    public func addCallback(uuid: String, callback: (JSON) -> (Bool)) {
        if self.requestCallbacks[uuid] == nil {
            requestCallbacks[uuid] = [callback]
        } else {
            requestCallbacks[uuid]?.append(callback)
        }
    }
}