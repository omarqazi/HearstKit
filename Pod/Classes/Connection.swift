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
    
    public func createObject(modelClass: String) {
        self.socket.writeString("{\"action\":\"create\",\"model\":\"\(modelClass)\"}")
        self.socket.writeString("{\"Subject\":\"HEARST FUCKING KIT\"}")
    }
}