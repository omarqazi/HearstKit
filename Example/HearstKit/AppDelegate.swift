//
//  AppDelegate.swift
//  HearstKit
//
//  Created by Omar Qazi on 02/02/2016.
//  Copyright (c) 2016 Omar Qazi. All rights reserved.
//

import UIKit
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        self.registerUserNotificationSettings(application)
        application.registerForRemoteNotifications()
        return true
    }
    
    
    func registerUserNotificationSettings(application: UIApplication) {
        let newMessageCategory = UIMutableUserNotificationCategory()
        newMessageCategory.identifier = "chat-message"
        
        let thumbsUpAction = UIMutableUserNotificationAction()
        thumbsUpAction.identifier = "thumbs-up"
        thumbsUpAction.title = "👍"
        thumbsUpAction.activationMode = UIUserNotificationActivationMode.Background
        thumbsUpAction.authenticationRequired = false
        
        let replyAction = UIMutableUserNotificationAction()
        replyAction.identifier = "reply-with-message"
        replyAction.title = "Reply"
        replyAction.activationMode = UIUserNotificationActivationMode.Background
        replyAction.authenticationRequired = false
        if #available(iOS 9.0, *) {
            replyAction.behavior = UIUserNotificationActionBehavior.TextInput
            replyAction.parameters = [UIUserNotificationTextInputActionButtonTitleKey : "Reply"]
        } else {
            // No text replies on older iOS versions
        }
        
        
        newMessageCategory.setActions([thumbsUpAction,replyAction], forContext: .Default)
        newMessageCategory.setActions([thumbsUpAction,replyAction], forContext: .Minimal)
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert,.Sound,.Badge], categories: [newMessageCategory])
        application.registerUserNotificationSettings(notificationSettings)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        print("did register user notification settings")
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        print(userInfo)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("failed to register for remote notifications",error)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("Got notification",userInfo)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print(deviceToken)
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }


}

