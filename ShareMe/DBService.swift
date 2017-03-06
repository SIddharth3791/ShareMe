//
//  DBService.swift
//  ShareMe
//
//  Created by Siddharth Patel on 3/5/17.
//  Copyright © 2017 Siddharth Patel. All rights reserved.
//

import Foundation
import UIKit

class DBService {
    
    
    func findFollowings(follower: String, map: AWSDynamoDBObjectMapper) -> AWSTask<AnyObject>    {
        let scan = AWSDynamoDBScanExpression()
        scan.filterExpression = "follower = :val"
        scan.expressionAttributeValues = [":val":follower]
        
        return map.scan(Follower.self, expression: scan).continueWith { (task: AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error!)
            }
            
            if (task.description != nil){
                print(task.description)
            }
            
            if (task.result != nil) {
                let result = task.result! as! AWSDynamoDBPaginatedOutput
                return result.items as! [Follower] as AnyObject?
            }
            
            return nil
        }
    }
    
    func findFollower(follower: String, following: String, map: AWSDynamoDBObjectMapper) -> AWSTask<AnyObject> {
        let scan = AWSDynamoDBScanExpression()
        scan.filterExpression = "follower = :follower AND following = :following"
        scan.expressionAttributeValues = [":follower":follower,":following":following]
        
        return map.scan(Follower.self, expression: scan).continueWith { (task: AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error)
            }
            
            if (task.description != nil){
                print(task.description)
            }
            
            if (task.result != nil) {
                let result = task.result! as! AWSDynamoDBPaginatedOutput
                return result.items as! [Follower] as AnyObject?
            }
            
            return nil
        }
        
    }
    
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }

}
