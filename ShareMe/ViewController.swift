//
//  ViewController.swift
//  ShareMe
//
//  Created by Siddharth Patel on 3/4/17.
//  Copyright © 2017 Siddharth Patel. All rights reserved.
//

import UIKit
import GoogleSignIn

class ViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
   
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().shouldFetchBasicProfile=true
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
 //Marks:- Google Sign in Function
    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            let idToken = user.authentication.idToken
            let name = user.profile.name
            let email = user.profile.email
            
            print(idToken, name, email)
        } else {
            print("\(error.localizedDescription)")
        }
    }
    
    


}

