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
    
    class func loadTeamById(teamId: String?, success: @escaping (tntTeam) -> Void ) {
        
        guard teamId != nil else {
            return
        }
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.load(tntTeam.self, hashKey: teamId!, rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as NSError? {
                print("AWS Dynamo error loading team item. Error: \(error)")
            } else if let team = task.result as? tntTeam {
                success(team)
            }
            return nil
        })
    }
    
    // better version of the above (option to add to cache, completion handler with error and result
    
    class func cacheTeamById(teamId: String?, updateCache: Bool, completion: @escaping (NSError?, tntTeam?) -> Void ) {
        
        guard teamId != nil else {
            return
        }
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.load(tntTeam.self, hashKey: teamId!, rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as NSError? {
                print("AWS Dynamo error loading team item. Error: \(error)")
                completion(error, nil)
                
            } else if let team = task.result as? tntTeam {
                if updateCache {
                    
                    if let teamMO = tntLocalDataManager.shared.teams[teamId!] {
                        
                        teamMO.updateFromCloud(dbTeam: team)
                        teamMO.saveLocal()
                        
                    } else {
                        let newMO = Team(dbTeam: team)
                        newMO.saveLocal()
                        
                    }
                    
                }
                
                completion(nil, team)
            } else {
                // No team found in cloud DB, so remove from cache
                
            }
            return nil
        })
    }
    
    
    class func validateTeamSecret(teamName: String, teamSecret: String, completion: @escaping (tntTeam?) -> Void ) {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "teamName = :teamName and teamSecret = :teamSecret"
        scanExpression.expressionAttributeValues = [":teamName": teamName,
                                                    ":teamSecret": teamSecret]
        
        dynamoDBObjectMapper.scan(tntTeam.self, expression: scanExpression).continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>!) -> Any? in
            if let error = task.error as NSError? {
                print("TNT Team: Dynamo DB error validating team/secret \(error)")
                completion(nil)
            } else {
                let teams = task.result?.items as! [tntTeam]? ?? []
                if teams.count > 0 {
                    completion(teams[0])
                } else {
                    completion(nil)
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
    
    func mergeDeviceData(team: Team) {
        
        // merge the users and athletes from a device (core data object) with the DB object
        
        let deviceUsers = team.userIds as! [String]? ?? []
        let deviceAthletes = team.athleteIds as! [String]? ?? []
        
        let mergedUsers: Set<String> = Set(deviceUsers).union(Set(self.userIds ?? []))
        let mergedAthletes: Set<String> = Set(deviceAthletes).union(Set(self.athleteIds ?? []))
        
        // DynamoDB doesn't like empty arrays/sets, so force them back to nil if empty
        self.userIds = mergedUsers.isEmpty ? nil : Array(mergedUsers)
        self.athleteIds = mergedAthletes.isEmpty ? nil : Array(mergedAthletes)
        
    }
    
    
}
