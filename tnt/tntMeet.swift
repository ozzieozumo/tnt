//
//  tntMeet.swift
//  tnt
//
//  Created by Luke Everett on 7/13/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//


import Foundation

import AWSDynamoDB

class tntMeet : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var meetId: String?
    var meetCity:  String?
    var meetStartDate: String?
    var meetEndDate: String?
    var meetVenue: String?
    var meetLevels: [Int]?
    var meetEvents: [String]?
    var meetTitle: String?
    var meetSubTitle: String?
    var sharedStatus: Int?
    var sharedTeam: String?
    var sharedUser: String?  // if set, means private to this user

    
    class func dynamoDBTableName() -> String {
        return "tntMeet"
    }
    
    class func hashKeyAttribute() -> String {
        return "meetId"
    }
    
    convenience init(meetMO : Meet) {
        
        self.init()
        
        meetId = meetMO.id
        meetCity = meetMO.city
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        meetStartDate = dateFormatter.string(from: meetMO.startDate! as Date)
        meetEndDate = dateFormatter.string(from: meetMO.endDate! as Date)
        meetVenue = meetMO.venue
        
        //convert min/max levels to array of levels
        
        var levels: [Int] = []
        for level in meetMO.minLevel ... meetMO.maxLevel {
                levels.append(Int(level))
        }
            
        meetLevels = levels
        meetEvents = meetMO.events as! [String]?
        meetTitle = meetMO.title
        meetSubTitle = meetMO.subTitle
        
        sharedStatus = meetMO.sharedStatus ? 1 : 0 
        sharedTeam = meetMO.sharedTeam
        sharedUser = meetMO.shareduser
    
    }
    
    func saveToCloud() {
        //TODO - update cloud save status and provide completion handler for errors/success
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.save(self).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as NSError? {
                print("TNT Meet DB, failed saving tntMeet object to Dynamo. Error: \(error)")
            } else {
                print("TNT Meet DB, saved meet \(self.meetId!)")
            }
            return nil
        })
    }
    
    class func scanTeamMeets(completion: @escaping ([tntMeet]?) -> Void ) {
        
        guard let teamName = tntLoginManager.shared.currentTeam?.name else { return }
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "sharedTeam = :teamName"
        scanExpression.expressionAttributeValues = [":sharedTeam": teamName]
        
        dynamoDBObjectMapper.scan(tntMeet.self, expression: scanExpression).continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>!) -> Any? in
            if let error = task.error as NSError? {
                print("TNT Meet: Dynamo DB error scanning for shared meets \(error)")
                completion(nil)
            } else {
                let meets = task.result?.items as! [tntMeet]? ?? []
                if meets.count > 0 {
                    completion(meets)
                } else {
                    completion(nil)
                }
            }
            return nil
        })
        
        
    }

}
