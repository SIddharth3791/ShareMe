//
//  UserViewController.swift
//  ShareMe
//
//  Created by Siddharth Patel on 3/5/17.
//  Copyright © 2017 Siddharth Patel. All rights reserved.
//

import Foundation
import UIKit


class UserViewController: UITableViewController {
    
    let databaseService = DatabaseService()
    var credentialsProvider:AWSCognitoCredentialsProvider = AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    
    var users = [User]()
    
    var refresher: UIRefreshControl!
    
    func refresh() {
        let identityId = credentialsProvider.identityId! as String
        
        let mapper = AWSDynamoDBObjectMapper.default()
        let scan = AWSDynamoDBScanExpression()
        
        mapper.scan(User.self, expression: scan).continueWith { (dynamoTask:AWSTask) -> AnyObject? in
            if (dynamoTask.error != nil) {
                print(dynamoTask.error as Any)
            }
            
            if (dynamoTask.result != nil) {
                self.users.removeAll(keepingCapacity: true)
                
                let dynamoResults = dynamoTask.result as AWSDynamoDBPaginatedOutput!
                
                for user in dynamoResults?.items as! [User] {
                    
                    if user.id != identityId {
                        self.users.append(user)
                    }
                }
            }
            
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
                return
            })
            
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresher = UIRefreshControl()
        
        refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
        
        refresher.addTarget(self, action: #selector(UserViewController.refresh), for: UIControlEvents.valueChanged)
        
        self.tableView.addSubview(refresher)
        
        refresh()
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
     {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath as IndexPath)
        
        cell.textLabel?.text = users[indexPath.row].name
        
        return cell
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return users.count
    }
}
