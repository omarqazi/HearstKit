//
//  ChatViewCell.swift
//  Hearst
//
//  Created by Omar Qazi on 1/28/16.
//  Copyright © 2016 BQE Software. All rights reserved.
//

import UIKit

class ChatViewCell: UITableViewCell {
    @IBOutlet weak var senderNameField: UILabel?
    @IBOutlet weak var messageBodyField: UILabel?
    @IBOutlet weak var userImageView: UIImageView?
    @IBOutlet weak var dateField: UILabel?
    var _message: HearstMessage?
    var message: HearstMessage? {
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
        senderNameField?.text = msg?.senderName
        messageBodyField?.text = msg?.body
        messageBodyField?.sizeToFit()
        dateField?.text = msg?.relativeSendTime()
        if userImageView != nil {
            let iv = userImageView!
            iv.image = msg?.userImage
            iv.layer.cornerRadius = (iv.frame.size.width / 2)
            iv.layer.borderColor = UIColor.blackColor().CGColor
            iv.layer.borderWidth = 1.0
            iv.clipsToBounds = true
        }
        
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
