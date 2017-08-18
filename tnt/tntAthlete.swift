//
//  tnt_Athlete.swift
//  tnt
//
//  Created by Luke Everett on 4/6/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation

import AWSDynamoDB

class tntAthlete : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var athleteId: String?
    var firstName:  String?
    var lastName: String?
    var eventLevels: [String: Int]?
    var cognitoId: String?
    var profileImageURL: String?
    
    class func dynamoDBTableName() -> String {
        return "tntAthlete"
    }
    
    class func hashKeyAttribute() -> String {
        return "athleteId"
    }
    
    convenience init(athleteMO : NSManagedObject) {
        
        self.init()
        
        athleteId = athleteMO.value(forKey: "id") as! String?
        firstName = athleteMO.value(forKey: "firstName") as! String?
        lastName = athleteMO.value(forKey: "lastName") as! String?
        eventLevels = athleteMO.value(forKey: "eventLevels") as! [String: Int]?
        cognitoId = athleteMO.value(forKey: "cognitoId") as! String?
        profileImageURL = athleteMO.value(forKey: "profileImageURL") as! String?
        
    }

}
