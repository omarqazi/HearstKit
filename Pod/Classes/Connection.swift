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
    
    
    init(serverDomain: String) {
        let socketUrl = NSURL(string: "wss://\(serverDomain)/sock/")!
        self.socket = WebSocket(url: socketUrl)
    }
    
    public func connect() -> Bool {
        if self.socket.isConnected {
            return true
        }
        
        socket.onConnect = {
            self.socket.writeString(self.auth.socketAuthenticationRequest())
            if let oc = self.onConnect {
                oc()
            }
            print("websocket is connected")
        }
        
        socket.onDisconnect = { (error: NSError?) in
            if let odc = self.onDisconnect {
                odc(error)
            }
            print("websocket is disconnected: \(error?.localizedDescription)")
            
        }
        
        socket.onText = { (text: String) in
            if let otxt = self.onText {
                otxt(text)
            }
            let jsonData = text.dataUsingEncoding(NSUTF8StringEncoding)
            let json = JSON(data: jsonData!)
            print(json)

        }
        
        socket.onData = { (data: NSData) in
            print("got some data: \(data.length)")
        }
        
        socket.onPong = {
            print("PONG")
        }
        
        socket.connect()
        return true
    }
    
    public func disconnect() -> Bool {
        self.socket.disconnect()
        return true
    }
    
    public func sendObject(command: AnyObject) -> Bool {
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(command, options: [])
            let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding)
            self.socket.writeString(jsonString!)
            return true
        } catch {
            return false
        }
    }
    
    public func createModel(modelName: String,payload: AnyObject) {
        let command = ["action" : "create", "model" : modelName]
        self.sendObject(command)
        self.sendObject(payload)
    }
    
    public func createMailbox(mb: Mailbox) {
        self.createModel("mailbox", payload: mb.serverRepresentation())
    }
    
    public func createThread(tr: Thread) {
        self.createModel("thread", payload: tr.serverRepresentation())
    }
    
    public func createMember(mem: Member) {
        self.createModel("threadmember", payload: mem.serverRepresentation())
    }
    
    public func createMessage(msg: Message) {
        self.createModel("message", payload: msg.serverRepresentation())
    }
}