//
//  UserViewController.swift
//  ShareMe
//
//  Created by Siddharth Patel on 3/5/17.
//  Copyright © 2017 Siddharth Patel. All rights reserved.
//

import Foundation
import UIKit


class UserViewController: UITableViewController
{
    
    let databaseService = DatabaseService()
    var credentialsProvider:AWSCognitoCredentialsProvider = AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    
    var users = [User]()
    var isFollowing = ["":false]
    
    var refresher: UIRefreshControl!
    
    func refresh() {
        let identityId = credentialsProvider.identityId! as String
        
        let mapper = AWSDynamoDBObjectMapper.default()
        let scan = AWSDynamoDBScanExpression()
        
        mapper.scan(User.self, expression: scan).continueWith { (dynamoTask:AWSTask) -> AnyObject? in
            if (dynamoTask.error != nil) {
                print(dynamoTask.error)
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
            
            self.databaseService.findFollowings(follower: identityId, map: mapper).continueWith(block: { (task:AWSTask) -> AnyObject? in
                
                if (task.error != nil) {
                    print(task.error)
                }

                
                if (task.result != nil) {
                    for item in task.result as! [Follower] {
                        self.isFollowing[item.following] = true
                    }
                }
                
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                    self.refresher.endRefreshing()
                })
                
                return nil
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
    
     public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
     {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath)
        
        cell.textLabel?.text = users[indexPath.row].name
        
        let followedObjectId = users[indexPath.row].id
        
        if isFollowing[followedObjectId] == true {
            
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
            
        }
        
        return cell
    }
    
    func addFollowing(following: String) {
        let identityId = credentialsProvider.identityId! as String
        
        let mapper = AWSDynamoDBObjectMapper.default()
        let add = Follower()
        
        add?.id = NSUUID().uuidString
        add?.follower = identityId
        add?.following = following
        
        mapper.save(add!)
    }
    
    func removeFollowing(following: String) {
        let identityId = credentialsProvider.identityId! as String
        
        let map = AWSDynamoDBObjectMapper.default()
        self.databaseService.findFollower(follower: identityId, following: following, map: map)?.continueWith(block: { (task:AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error)
            }
            
            
            if (task.result != nil) {
                let followings = task.result as! [Follower]
                
                for following in followings {
                    map.remove(following)
                }
            }
            
            return nil
        })
    }
    
    

        public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        let cell:UITableViewCell = tableView.cellForRow(at: indexPath as IndexPath)!
        
        let followedObjectId = users[indexPath.row].id
        
        if isFollowing[followedObjectId] == nil || isFollowing[followedObjectId] == false {
            
            isFollowing[followedObjectId] = true
            
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
            
            addFollowing(following: users[indexPath.row].id)
        } else {
            
            isFollowing[followedObjectId] = false
            
            cell.accessoryType = UITableViewCellAccessoryType.none
            
            removeFollowing(following: users[indexPath.row].id)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    //override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    public override func numberOfSections(in tableView: UITableView) -> Int {
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
