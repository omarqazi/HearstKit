import UIKit

class ChatViewCell: UITableViewCell {
    @IBOutlet weak var senderNameField: UILabel?
    @IBOutlet weak var messageBodyField: UILabel?
    @IBOutlet weak var userImageView: UIImageView?
    @IBOutlet weak var dateField: UILabel?
    var _message: Message?
    var message: Message? {
        get {
            return self._message
        }
        
        set(newMessage) {
            self._message = newMessage
            self.updateDisplay()
        }
    }
    
    func updateDisplay() {
        let msg = self.message
        senderNameField?.text = msg?.labels["SenderFacebookName"].string
        messageBodyField?.text = msg?.body
        messageBodyField?.sizeToFit()
        dateField?.text = msg?.relativeSendTime()
        if userImageView != nil {
            let iv = userImageView!
            if let fbid = msg?.labels["SenderFacebookId"].string {
                iv.image = self.facebookImageFor(fbid)
            } else {
                // iv.image = defaultImage
            }
            iv.layer.cornerRadius = (iv.frame.size.width / 2)
            iv.layer.borderColor = UIColor.blackColor().CGColor
            iv.layer.borderWidth = 1.0
            iv.clipsToBounds = true
        }
    }
    
    func facebookImageFor(fbid: String) -> UIImage? {
        let url = NSURL(string: "https://graph.facebook.com/v2.5/\(fbid)/picture?height=150&width=150")
        if imageCache[fbid] != nil {
            return imageCache[fbid]
        }
        
        let cacheDirs = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        let cachePath = cacheDirs.last
        
        var imageData: NSData?
        var cacheFile = ""
        
        // first try and get the data from a file cache
        if cachePath != nil {
            cacheFile = cachePath! + "/\(fbid).jpg"
            if NSFileManager.defaultManager().fileExistsAtPath(cacheFile) {
                imageData = NSData(contentsOfFile: cacheFile)
                let img = UIImage(data: imageData!)
                imageCache[fbid] = img
                return img
            }
        }
        
        if imageData == nil && url != nil {
            imageData = NSData(contentsOfURL: url! )
            if cacheFile != "" {
                imageData?.writeToFile(cacheFile, atomically: true)
            }
        }
        
        if imageData == nil {
            return nil
        }
        
        let img = UIImage(data: imageData!)
        imageCache[fbid] = img
        return img
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
