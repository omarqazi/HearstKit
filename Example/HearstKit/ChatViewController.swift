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
    
    // User Facebook info
    var facebookUserId: String?
    var facebookUserName: String?
    
    // Info for connecting to hearst
    var mailboxId = ""
    var threadId = ""
    
    // variables for tracking UI state
    var lastOffsets = [Float]()
    var bottomRow: NSIndexPath?
    var lockScrolling = false // don't scroll the view when the user is scrolling
    var scrollLockTimer: NSTimer?
    
    // Timer to limit how often we send the typing indicator
    var sentTypingIndicatorRecently = false
    var typingIndicatorTimer: NSTimer?

    
    required init(coder decoder: NSCoder) {
        super.init(tableViewStyle: .Plain)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Use a custom table view cell to display chat messages
        self.tableView?.registerNib(UINib(nibName: "ChatViewCell", bundle: nil), forCellReuseIdentifier: "ChatCell")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        
        self.chatServer.onConnect = {
            print("Connected to Hearst server")
            self.publicThread = self.chatServer.knownThread(self.threadId)
            
            // get the 20 most recent chat messages we don't already have
            self.publicThread.recentMessages(340, limit: 20, topicFilter: "chat-message", callback: { msgs in
                for msg in msgs {
                    self.addNextMessage(msg)
                }
            })
            
            // add new messages as we get them
            self.publicThread.onMessage({ (msg) -> (Bool) in
                switch msg.topic {
                case "chat-message":
                    self.addNextMessage(msg)
                case "typing-notification":
                    self.handleTypingNotification(msg)
                default:
                    print("huh WTF is this topic:",msg.topic)
                }
                return false
            })
        }
        
        self.chatServer.onDisconnect = { err in
            print("Disconnected from Hearst server", err)
        }
        
        self.attemptConnection()
    }
    
    func handleTypingNotification(msg: Message) {
        if msg.topic == "typing-notification" {
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
    }
    
    override func viewWillDisappear(animated: Bool) {
        if self.chatServer.socket.isConnected {
            self.chatServer.disconnect()
        } else {
        }
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
            let msg = Message()
            msg.labels = JSON(["SenderFacebookName" : self.facebookUserName!,"SenderFacebookId" : self.facebookUserId!])
            msg.topic = "typing-notification"
            msg.payload = JSON(["is_typing" : isTyping.description])
            
            self.publicThread.sendMessage(msg) { msgx in
            }
        }
    }
    
    func sendMessage(aMessage: String) {
        if self.facebookUserId != nil && self.facebookUserName != nil {
            self.typingIndicatorTimer?.invalidate()
            sentTypingIndicatorRecently = false
            
            let msg = Message()
            msg.body = aMessage
            msg.labels = JSON(["SenderFacebookName" : self.facebookUserName!,"SenderFacebookId" : self.facebookUserId!])
            msg.topic = "chat-message"
            self.publicThread.sendMessage(msg, callback: { (msg) in
            })
        }
    }
    
    
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
    
    func addNextMessage(message: Message) {
        if message.topic != "chat-message" {
            return
        }
        self.typingIndicatorView?.removeUsername(message.labels["SenderFacebookName"].string)
        let insertionIndex = messages.count
        messages.insert(message, atIndex: insertionIndex)
        let indexPath = NSIndexPath(forRow: insertionIndex, inSection: 0)
        self.tableView?.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        if !self.lockScrolling {
            self.tableView?.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        } else {
            AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
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
}