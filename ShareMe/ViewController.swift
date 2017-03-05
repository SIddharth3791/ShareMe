//
//  ViewController.swift
//  ShareMe
//
//  Created by Siddharth Patel on 3/4/17.
//  Copyright © 2017 Siddharth Patel. All rights reserved.
//

import UIKit

import GoogleSignIn

class ViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, AWSIdentityProviderManager {

    var googleIdToken = ""
    
    // Marks:- Google The sign-in flow.
    
    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!){

        if (error == nil) {
            
            googleIdToken = user.authentication.idToken
           
            signInToCognito(user: user)
        } else {
            
            print("\(error.localizedDescription)")
        }
    }

    func logins() -> AWSTask<NSDictionary>{

        let result = NSDictionary(dictionary: [AWSIdentityProviderGoogle: googleIdToken])
        return AWSTask(result: result)
    }

    func signInToCognito(user: GIDGoogleUser){
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USWest2, identityPoolId: "us-west-2:ce587a78-52ec-476e-88d2-994a9001badc", identityProviderManager: self)

        let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        credentialsProvider.getIdentityId().continueWith(block: {(task:AWSTask) -> AnyObject? in
        //getIdentityId().continue(  {(task:AWSTask) -> AnyObject? in

            if task.error == nil {

                let syncClient = AWSCognito.default()
                
                let dataset = syncClient.openOrCreateDataset("ShareApp")

                dataset.setString(user.profile.email, forKey: "email")
            
                dataset.setString(user.profile.name, forKey: "name")
            
                let result = dataset.synchronize()
                result?.continueWith(block: {(task:AWSTask) -> AnyObject? in
                    if task.error != nil {
                        print(task.error)
                    } else {
                        print(task.result)
                    }

                    return nil
                    
                })
                
                return nil
                
            }

            if (task.error != nil) {
                print(task.error)
                return nil
            }
            return nil
            
        })
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().shouldFetchBasicProfile = true
    }
    
    
    
    
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
        
    }
    
    
    
}
