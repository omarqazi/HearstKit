//
//  Hearst.swift
//  
//
//  Created by Omar Qazi on 1/28/16.

import Foundation
import SwiftyJSON

var globalDateParser: NSDateFormatter?
var relativeDateFormatter: NSDateFormatter?
var imageCache = [String : UIImage]()

class HearstMessage {
    var body: String?
    var threadId: String?
    var senderName: String?
    var serverPayload: JSON?
    var sendDate: NSDate?
    var facebookId: String?
    var dateParser: NSDateFormatter {
        if globalDateParser == nil {
            globalDateParser = NSDateFormatter()
            globalDateParser!.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSSSSZ"
            globalDateParser!.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        }
        return globalDateParser!
    }
    var userImageUrl: NSURL? {
        get {
            if self.facebookId == nil || self.facebookId!.isEmpty {
                return nil
            }
            
            
            let url = NSURL(string: "https://graph.facebook.com/v2.5/\(self.facebookId!)/picture?height=150&width=150")
            return url
        }
    }
    var userImage: UIImage? {
        get {
            if self.facebookId == nil {
                return nil
            }
            
            if imageCache[self.facebookId!] != nil {
                return imageCache[self.facebookId!]
            }
            let cacheDirs = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
            let cachePath = cacheDirs.last
            
            var imageData: NSData?
            var cacheFile = ""
            
            // first try and get the data from a file cache
            if cachePath != nil {
                cacheFile = cachePath! + "/\(self.facebookId!).jpg"
                if NSFileManager.defaultManager().fileExistsAtPath(cacheFile) {
                    imageData = NSData(contentsOfFile: cacheFile)
                    let img = UIImage(data: imageData!)
                    imageCache[self.facebookId!] = img
                    return img
                }
            }
            
            if self.userImageUrl == nil {
                return nil
            }
            
            // otherwise download it
            if imageData == nil {
                imageData = NSData(contentsOfURL: self.userImageUrl!)
                if cacheFile == "" {
                    imageData?.writeToFile(cacheFile, atomically: true)
                }
            }
            
            if imageData == nil {
                return nil
            }
            
            let img = UIImage(data: imageData!)
            imageCache[self.facebookId!] = img
            return img
        }
    }
    var dateFormatter: NSDateFormatter {
        if relativeDateFormatter == nil {
            relativeDateFormatter = NSDateFormatter()
            relativeDateFormatter?.locale = NSLocale.autoupdatingCurrentLocale()
            relativeDateFormatter?.timeStyle = .ShortStyle
            relativeDateFormatter?.dateStyle = .NoStyle
            relativeDateFormatter?.doesRelativeDateFormatting = true
        }
        return relativeDateFormatter!
    }
    
    func parse(payload: JSON) {
        self.serverPayload = payload
        self.body = payload["Body"].string
        self.senderName = payload["Labels"]["SenderFacebookName"].string
        self.facebookId = payload["Labels"]["SenderFacebookId"].string
        let dateString = payload["CreatedAt"].string
        if dateString != nil {
             self.sendDate = self.dateParser.dateFromString(dateString!)
        }
    }
    
    func relativeSendTime() -> String {
        if self.sendDate == nil {
            return ""
        }
        return self.dateFormatter.stringFromDate(self.sendDate!)
    }
}
