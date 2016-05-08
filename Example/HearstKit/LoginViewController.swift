//
//  LoginViewController.swift
//  SmickChat
//
//  Created by Omar Qazi on 1/30/16.
//  Copyright © 2016 BQE Software. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    var autoAdvanced = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
        })
        if result.isCancelled {
            print("cancelled")
            return
        }
        print("Declined permisions:",result.declinedPermissions)
        print("Granted permissions:", result.grantedPermissions)
        print("Token:",result.token.tokenString)
        print("User ID",result.token.userID)
        self.performSegueWithIdentifier("PresentChat", sender: self)

    }
    
    func loginButtonWillLogin(loginButton: FBSDKLoginButton!) -> Bool {
        print("will login")
        return true
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("Did log out")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let loginButton = FBSDKLoginButton()
        loginButton.center = self.view.center
        loginButton.readPermissions = ["public_profile","email","user_friends"]
        loginButton.delegate = self
        self.view.addSubview(loginButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.title = "Login With Facebook"
        if FBSDKAccessToken.currentAccessToken() != nil && !self.autoAdvanced {
            self.performSegueWithIdentifier("PresentChat", sender: self)
            self.autoAdvanced = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.title = "Logout"
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
