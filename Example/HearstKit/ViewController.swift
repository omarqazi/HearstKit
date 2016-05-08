//
//  ViewController.swift
//  HearstKit
//
//  Created by Omar Qazi on 02/02/2016.
//  Copyright (c) 2016 Omar Qazi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private var xx = Connection(serverDomain: "chat.smick.co")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        let rz = Mailbox()
        rz.uuid = "hello-world"
        rz.deviceId = "hey"
        
        xx.onConnect = {
            print("YE NIGGA")
            self.xx.createObject("thread")
        }
        
        xx.connect()
    }
    
    override func viewWillDisappear(animated: Bool) {
        xx.disconnect()
    }

}

