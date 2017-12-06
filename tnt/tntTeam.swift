//
//  tnt_Athlete.swift
//  tnt
//
//  Created by Luke Everett on 4/6/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation

import AWSDynamoDB

class tntTeam : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var teamId: String?
    var athleteIds: [String]?
    var userIds: [String]?
    var teamSecret: String?
    var teamName: String?
    
    class func dynamoDBTableName() -> String {
        return "tntTeam"
    }
    
    class func hashKeyAttribute() -> String {
        return "teamId"
    }
    
    class func checkNameAvailable(_ name: String, completion: @escaping (Bool) -> Void) {
        // scan all teams and return whether the name is available
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "teamName = :proposedName"
        scanExpression.expressionAttributeValues = [":proposedName": name]
        
        dynamoDBObjectMapper.scan(tntTeam.self, expression: scanExpression).continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>!) -> Any? in
            if let error = task.error as NSError? {
                print("TNT Team: Dynamo DB error checking availability of team name \(error)")
                completion(false)
            } else {
                if let teams = task.result?.items as! [tntTeam]? {
                    completion(teams.count == 0)
                } else {
                    completion(true)
                }
            }
            return nil
        })
    }
    
    convenience init(teamMO : Team) {
        
        guard teamMO.teamId != nil else {
            fatalError("TNT: team ID cannot be nil when saving to Dynamo")
        }
        
        self.init()
        
        // Dynamo DB does not allow nil or empty string, so coalesce nil strings to space
        teamId = teamMO.teamId
        teamSecret = teamMO.secret
        teamName = teamMO.name
        athleteIds = teamMO.athleteIds as! [String]?
        userIds = teamMO.userIds as! [String]?
        
    }
    
    func saveToCloud() {
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.save(self).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as NSError? {
                print("TNT Team DB, failed saving tntTeam object to Dynamo. Error: \(error)")
            } else {
                print("TNT Team DB, saved team \(self.teamId!)")
            }
            return nil
        })
    }
        
    
    
}
