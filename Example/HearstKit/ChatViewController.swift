//
//  ChatViewController.swift
//  HearstChat
//
//  Created by Omar Qazi on 1/30/16.
//  Copyright © 2016 BQE Software. All rights reserved.
//

import UIKit
import SlackTextViewController
import Starscream
import Alamofire
import SwiftyJSON
import AudioToolbox
import FBSDKCoreKit

class ChatViewController: SLKTextViewController {
    @IBOutlet weak var aButtonItem: UIBarButtonItem?
    var messages = [HearstMessage]()
    var socket = WebSocket(url: NSURL(string: "wss://chat.smick.co/socket/")!)
    var chatServer = Connection(serverDomain: "chat.smick.co")
    var mailboxId = ""
    var threadId = ""
    var sessionToken = ""
    var lastOffsets = [Float]()
    var bottomRow: NSIndexPath?
    var lockScrolling = false // don't scroll the view when the user is scrolling
    var scrollLockTimer: NSTimer?
    var sentTypingIndicatorRecently = false
    var typingIndicatorTimer: NSTimer?
    var facebookUserId: String?
    var facebookUserName: String?
    
    var connecting = false
    
    required init(coder decoder: NSCoder) {
        super.init(tableViewStyle: .Plain)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.registerNib(UINib(nibName: "ChatViewCell", bundle: nil), forCellReuseIdentifier: "ChatCell")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func didPressRightButton(sender: AnyObject!) {
        self.sendMessage(self.textView.text)
        super.didPressRightButton(sender)
    }
    
    func requestFacebookProfile() {
        FBSDKGraphRequest(graphPath: "me?fields=id,name", parameters: nil).startWithCompletionHandler({ (conn, result, err) -> Void in
            if err != nil {
                self.showLogin(self)
                return
            }
            
            if let respDict = result as? [String : String] {
                print(respDict)
                self.facebookUserId = respDict["id"]
                self.facebookUserName = respDict["name"]
                self.setTextInputbarHidden(false, animated: false)
            }
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        if FBSDKAccessToken.currentAccessToken() != nil {
            self.requestFacebookProfile()
        } else {
            self.setTextInputbarHidden(true, animated: false)
        }
        
        self.title = "Hearst Chat"
        self.inverted = false
        self.textInputbar.textView.placeholder = "Type some shit"
        self.keyboardPanningEnabled = true
        
        if !socket.isConnected {
            self.connecting = true
            print("about to attempt connection")
            self.attemptConnection()
        }
        
        self.chatServer.onConnect = {
            print("Connected using HearstKit")
        }
        
        self.chatServer.onText = { msg in
            print("HearstKit got message:", msg)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        if self.socket.isConnected {
            self.socket.disconnect()
            print("disconnecting")
        } else {
            print("no need to disconnect")
        }
    }
    
    override func textViewDidChange(textView: UITextView) {
        // if we haven't sent a typing notification recently, and they are typing
        if !sentTypingIndicatorRecently && !textView.text.isEmpty {
            sentTypingIndicatorRecently = true
            self.sendTypingNotification(true)
            NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(ChatViewController.typingNotificationNoLongerRecent(_:)), userInfo: nil, repeats: false)
        } else if textView.text.isEmpty {
            self.sendTypingNotification(false)
            sentTypingIndicatorRecently = false
        }
        super.textViewDidChange(textView)
    }
    
    func typingNotificationNoLongerRecent(sender: AnyObject) {
        self.sentTypingIndicatorRecently = false
    }
    
    func sendTypingNotification(isTyping: Bool) {
        if self.facebookUserId == nil || self.facebookUserName == nil {
            return
        }
        
        let insertRequest = ["model":"message", "action": "insert"]
        let messageDescription = [
            "ThreadId" : self.threadId,
            "SenderMailboxId" : self.mailboxId,
            "Body" : "",
            "Labels" : ["SenderFacebookName" : self.facebookUserName!,"SenderFacebookId" : self.facebookUserId!],
            "Payload" : ["is_typing" : isTyping.description],
            "Topic" : "typing-notification"
        ]
        do {
            let requestData = try NSJSONSerialization.dataWithJSONObject(insertRequest, options: NSJSONWritingOptions(rawValue: 0))
            let messageData = try NSJSONSerialization.dataWithJSONObject(messageDescription, options: NSJSONWritingOptions(rawValue: 0))
            let requestString = String(data: requestData, encoding: NSUTF8StringEncoding)
            let messageString = String(data: messageData, encoding: NSUTF8StringEncoding)
            if requestString != nil && messageString != nil {
                socket.writeString(requestString!)
                socket.writeString(messageString!)
            }
        } catch {
            print("it shit the bed")
        }
    }
    
    func showLogin(sender: AnyObject!) {
        self.performSegueWithIdentifier("PresentLogin", sender: self)
    }
    
    func sendMessage(aMessage: String) {
        if self.facebookUserId == nil || self.facebookUserName == nil {
            return
        }
        
        sentTypingIndicatorRecently = false
        
        let insertRequest = ["model":"message", "action": "insert"]
        let messageDescription = [
            "ThreadId" : self.threadId,
            "SenderMailboxId" : self.mailboxId,
            "Body" : aMessage,
            "Labels" : ["SenderFacebookName" : self.facebookUserName!,"SenderFacebookId" : self.facebookUserId!],
            "Payload" : [],
            "Topic" : "chat-message"
        ]
        do {
            let requestData = try NSJSONSerialization.dataWithJSONObject(insertRequest, options: NSJSONWritingOptions(rawValue: 0))
            let messageData = try NSJSONSerialization.dataWithJSONObject(messageDescription, options: NSJSONWritingOptions(rawValue: 0))
            let requestString = String(data: requestData, encoding: NSUTF8StringEncoding)
            let messageString = String(data: messageData, encoding: NSUTF8StringEncoding)
            if requestString != nil && messageString != nil {
                socket.writeString(requestString!)
                socket.writeString(messageString!)
            }
        } catch {
            print("it shit the bed")
        }
    }
    
    
    func attemptConnection() -> Bool {
        Alamofire.request(.GET, "https://www.smick.tv/auth/hearstchat").responseJSON { response in
            if let responseJson = response.result.value {
                self.mailboxId = responseJson["mailbox_id"] as! String
                self.threadId = responseJson["thread_id"] as! String
                self.sessionToken = responseJson["session_token"] as! String
                
                let authStrategy = Authentication()
                authStrategy.strategy = .Session
                authStrategy.mailboxId = responseJson["mailbox_id"] as! String
                authStrategy.sessionToken = responseJson["session_token"] as! String
                self.chatServer.auth = authStrategy
                self.chatServer.connect()
                
                self.connectToHearst(self.mailboxId, threadId: self.threadId, sessionToken: self.sessionToken)
            }
        }
        return true
    }
    
    func connectToHearst(mailboxId: String, threadId: String, sessionToken: String) {
        socket = WebSocket(url: NSURL(string: "wss://chat.smick.co/socket/")!)
        socket.headers["X-Hearst-Mailbox"] = mailboxId
        socket.headers["X-Hearst-Session"] = sessionToken
        socket.onConnect = {
            let jsonString = "{\"model\" : \"thread\", \"action\" : \"list\", \"follow\" : \"true\", \"history_topic\" : \"chat-message\", \"limit\" : \"100\", \"thread_id\" : \"\(threadId)\"}"
            self.socket.writeString(jsonString)
            print("websocket is connected")
        }
        //websocketDidDisconnect
        socket.onDisconnect = { (error: NSError?) in
            print("websocket is disconnected: \(error?.localizedDescription)")
        }
        //websocketDidReceiveMessage
        socket.onText = { (text: String) in
            let jsonData = text.dataUsingEncoding(NSUTF8StringEncoding)
            let json = JSON(data: jsonData!)
            print(json)
            
            let isFirstLoad = (self.messages.count == 0)
            var actualMessageAdded = false
            
            for (_, val) in json {
                var message = val
                var bottomAdd = false
                let modelClass = val["ModelClass"]
                if modelClass != nil && modelClass == "message" {
                    message = val["Payload"]
                    bottomAdd = true
                }
                
                let newMessage = HearstMessage()
                newMessage.parse(message)
                if newMessage.body != nil && !newMessage.body!.isEmpty {
                    if newMessage.senderName != nil {
                        self.typingIndicatorView?.removeUsername(newMessage.senderName!)
                    }
                    self.appendNewMessage(newMessage,addToBottom: bottomAdd)
                    actualMessageAdded = true
                } else if newMessage.body != nil && newMessage.body!.isEmpty {
                    if let isTyping = newMessage.serverPayload?["Payload"]["is_typing"].string {
                        if let sendName = newMessage.senderName {
                            if sendName != self.facebookUserName {
                                if isTyping == "true" {
                                    self.typingIndicatorView?.insertUsername(sendName)
                                } else if isTyping == "false" {
                                    self.typingIndicatorView?.removeUsername(sendName)
                                }
                            }
                        }
                    }
                }
            }
            
            if !actualMessageAdded { // if we didn't add anything to the table view
                return // dont worry about scrolling or vibrating
            }
            
            if !self.lockScrolling && self.messages.count > 0 {
                let lastIndex = NSIndexPath(forRow: (self.messages.count - 1), inSection: 0)
                self.tableView?.scrollToRowAtIndexPath(lastIndex, atScrollPosition: .Bottom, animated: !isFirstLoad)
            } else if self.lockScrolling {
                if json.count == 1 {
                    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
                }
            }
        }
        //websocketDidReceiveData
        socket.onData = { (data: NSData) in
            print("got some data: \(data.length)")
        }
        
        socket.onPong = {
            print("PONG")
        }
        socket.connect()
        self.connecting = false
    }
    
    func appendNewMessage(message: HearstMessage,addToBottom: Bool) {
        let insertionIndex = messages.count
        messages.insert(message, atIndex: insertionIndex)
        let indexPath = NSIndexPath(forRow: insertionIndex, inSection: 0)
        self.tableView?.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        if !self.lockScrolling {
            self.tableView?.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: addToBottom)
        }
    }
    
    func removeScrollLock(sender: AnyObject) {
        self.lockScrolling = false
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        if !self.textView.isFirstResponder() {
            return
        }
        
        self.lockScrolling = true
        self.scrollLockTimer?.invalidate()
        self.scrollLockTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(ChatViewController.removeScrollLock(_:)), userInfo: nil, repeats: false)
        
        lastOffsets.append(Float(scrollView.contentOffset.y))
        
        var isScrollingUp = false
        if lastOffsets.count > 35 {
            isScrollingUp = true
            for reverseIndex in 1...35 {
                let aElement = lastOffsets[lastOffsets.count - reverseIndex]
                let elementBefore = lastOffsets[lastOffsets.count - reverseIndex - 1]
                if aElement > elementBefore {
                    isScrollingUp = false
                    break
                }
            }
        }
        
        if isScrollingUp {
            self.textView.resignFirstResponder()
            lastOffsets = [Float]()
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75.0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ChatCell", forIndexPath: indexPath) as! ChatViewCell
        let msg = messages[indexPath.row]
        cell.message = msg
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func didChangeKeyboardStatus(status: SLKKeyboardStatus) {
        super.didChangeKeyboardStatus(status)
        let willChange = (status == SLKKeyboardStatus.WillShow || status == SLKKeyboardStatus.WillHide)
        let didChange = (status == SLKKeyboardStatus.DidShow || status == SLKKeyboardStatus.DidHide)
        if willChange {
            let lastVisibleIndexPath = self.tableView?.indexPathsForVisibleRows?.last
            self.bottomRow = lastVisibleIndexPath
        } else if didChange && self.bottomRow != nil {
            if !self.lockScrolling {
                self.tableView?.scrollToRowAtIndexPath(bottomRow!, atScrollPosition: .Bottom, animated: true)
            }
        }
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}