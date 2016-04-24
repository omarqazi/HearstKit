//
//  ViewController.swift
//  HearstKit
//
//  Created by Omar Qazi on 02/02/2016.
//  Copyright (c) 2016 Omar Qazi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        let xx = Connection(serverDomain: "chat.smick.co")
        xx.connect()
    }

}

