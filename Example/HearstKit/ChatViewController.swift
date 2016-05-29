import UIKit
import SlackTextViewController
import Starscream
import Alamofire
import SwiftyJSON
import AudioToolbox
import FBSDKCoreKit

class ChatViewController: SLKTextViewController {
    // For sending & receiving chat messages:
    var chatServer = Connection(serverDomain: "chat.smick.co") // Connection to server
    var publicThread = Thread()
    var messages = [Message]() // we'll keep message data from the server in here
    
    // Info for connecting to hearst
    var mailboxId = ""
    var threadId = ""
    
    // User Facebook info
    var facebookUserId: String?
    var facebookUserName: String?
    var outgoingLabels: [String : String] {
        return ["SenderFacebookName" : self.facebookUserName!,"SenderFacebookId" : self.facebookUserId!]
    }
    
    // Timer to limit how often we send the typing indicator
    var sentTypingIndicatorRecently = false
    var typingIndicatorTimer: NSTimer?
    
    // variables for tracking UI state
    var lastOffsets = [Float]()
    var bottomRow: NSIndexPath?
    var lockScrolling = false // don't scroll the view when the user is scrolling
    var scrollLockTimer: NSTimer?
    
    required init(coder decoder: NSCoder) {
        super.init(tableViewStyle: .Plain)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Use a custom table view cell to display chat messages
        self.tableView?.registerNib(UINib(nibName: "ChatViewCell", bundle: nil), forCellReuseIdentifier: "ChatCell")
    }
    
    func chatServerConnected() {
        print("Connected to Hearst server")
        self.publicThread = self.chatServer.knownThread(self.threadId)
        var lastIndex: Int64 = 0
        if self.messages.count > 0 {
            lastIndex = self.messages.last!.index
        }
        
        // get the 20 most recent chat messages we don't already have
        self.publicThread.recentMessages(lastIndex, limit: 20, topicFilter: "chat-message", callback: { msgs in
            for msg in msgs {
                self.displayNewMessage(msg)
            }
        })
        
        // add new messages as we get them
        self.publicThread.onMessage(self.chatServerGotMessage)
        self.chatServer.onDisconnect = self.chatServerDisconnected
    }
    
    func chatServerGotMessage(msg: Message) -> Bool {
        switch msg.topic {
        case "chat-message":
            self.displayNewMessage(msg)
        case "typing-notification":
            self.handleTypingNotification(msg)
        default:
            print("huh WTF is this topic:",msg.topic)
        }
        return false
    }
    
    func chatServerDisconnected(err: NSError?) {
        print("Disconnected from Hearst server", err)
    }
    
    override func viewWillAppear(animated: Bool) {
        if FBSDKAccessToken.currentAccessToken() != nil { // if we're authorized with Facebook
            self.requestFacebookProfile() // get the user's info
        } else {
            self.setTextInputbarHidden(true, animated: false) // otherwise they can't send messages
        }
        
        // Setup UI
        self.title = "Hearst Chat"
        self.inverted = false
        self.textInputbar.textView.placeholder = "Type some shit"
        self.keyboardPanningEnabled = true
        
        self.chatServer.onConnect = self.chatServerConnected
        self.attemptConnection()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.chatServer.disconnect()
    }
    
    override func textViewDidChange(textView: UITextView) {
        // if we haven't sent a typing notification recently, and they are typing
        if !sentTypingIndicatorRecently && !textView.text.isEmpty {
            sentTypingIndicatorRecently = true
            self.sendTypingNotification(true)
            self.typingIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(ChatViewController.typingNotificationNoLongerRecent(_:)), userInfo: nil, repeats: false)
        } else if textView.text.isEmpty {
            self.typingIndicatorTimer?.invalidate()
            self.sendTypingNotification(false)
            sentTypingIndicatorRecently = false
        }
        
        super.textViewDidChange(textView)
    }
    
    func typingNotificationNoLongerRecent(sender: AnyObject) {
        self.sentTypingIndicatorRecently = false
    }
    
    func sendTypingNotification(isTyping: Bool) {
        if self.facebookUserId != nil && self.facebookUserName != nil {
            self.publicThread.sendMessage(Message(
                payload: ["is_typing" : isTyping.description],
                labels: self.outgoingLabels,
                topic: "typing-notification"
            ))
        }
    }
    
    // Send a chat message to the server
    func sendMessage(aMessage: String) {
        if self.facebookUserId != nil && self.facebookUserName != nil { // If we have our FB info
            self.noLongerTyping() // we are no longer typing
            
            self.publicThread.sendMessage( // send the message
                Message(body: aMessage, labels: self.outgoingLabels, topic: "chat-message")
            )
        }
    }
    
    func displayNewMessage(message: Message) {
        // We got a new chat message from a user. That means they're not typing it anymore
        self.typingIndicatorView?.removeUsername(message.labels["SenderFacebookName"].string)
        
        let insertionIndex = messages.count
        let indexPath = NSIndexPath(forRow: insertionIndex, inSection: 0)

        messages.insert(message, atIndex: insertionIndex) // store the message in memory and
        self.tableView?.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic) // display it
        
        if !self.lockScrolling { // if scrolling is not locked
            // scroll to the new message
            self.tableView?.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        } else {
            // otherwise vibrate
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
    }
    
    func handleTypingNotification(msg: Message) {
        if let isTyping = msg.payload["is_typing"].string {
            if let senderName = msg.labels["SenderFacebookName"].string {
                if senderName != self.facebookUserName {
                    if isTyping == "true" {
                        self.typingIndicatorView?.insertUsername(senderName)
                    } else {
                        self.typingIndicatorView?.removeUsername(senderName)
                    }
                }
            }
        }
    }
    
    // As of now we get the Hearst connection / auth info from a server
    func attemptConnection() -> Bool {
        Alamofire.request(.GET, "https://www.smick.tv/auth/hearstchat").responseJSON { response in
            if let responseJson = response.result.value {
                self.mailboxId = responseJson["mailbox_id"] as! String
                self.threadId = responseJson["thread_id"] as! String
                
                let authStrategy = Authentication()
                authStrategy.strategy = .Session
                authStrategy.mailboxId = responseJson["mailbox_id"] as! String
                authStrategy.sessionToken = responseJson["session_token"] as! String
                self.chatServer.auth = authStrategy
                self.chatServer.connect()
            }
        }
        return true
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
    
    func removeScrollLock(sender: AnyObject) {
        self.lockScrolling = false
    }
    
    override func didPressRightButton(sender: AnyObject!) {
        self.sendMessage(self.textView.text)
        super.didPressRightButton(sender)
    }
    
    // Get the user's name and user id from Facebook
    func requestFacebookProfile() {
        FBSDKGraphRequest(graphPath: "me?fields=id,name", parameters: nil).startWithCompletionHandler({ (conn, result, err) -> Void in
            if err != nil {
                self.navigationController?.popViewControllerAnimated(true)
                return
            }
            
            if let respDict = result as? [String : String] {
                self.facebookUserId = respDict["id"]
                self.facebookUserName = respDict["name"]
                self.setTextInputbarHidden(false, animated: false)
            }
        })
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ChatCell", forIndexPath: indexPath) as! ChatViewCell
        let msg = messages[indexPath.row]
        cell.message = msg
        return cell
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
    
    override func didChangeKeyboardStatus(status: SLKKeyboardStatus) {
        super.didChangeKeyboardStatus(status)
        
        let willChange = (status == SLKKeyboardStatus.WillShow || status == SLKKeyboardStatus.WillHide)
        let didChange = (status == SLKKeyboardStatus.DidShow || status == SLKKeyboardStatus.DidHide)
        
        if willChange { // if the keyboard status is changing
            self.bottomRow = self.tableView?.indexPathsForVisibleRows?.last // remember the bottom row
        } else if didChange && self.bottomRow != nil { // and then afterwards
            if !self.lockScrolling { // if the user isn't already scrolling
                // put the bottom row back at the bottom
                self.tableView?.scrollToRowAtIndexPath(bottomRow!, atScrollPosition: .Bottom, animated: true)
            }
        }
    }
    
    func noLongerTyping() {
        self.typingIndicatorTimer?.invalidate()
        sentTypingIndicatorRecently = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}