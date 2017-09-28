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
    var dob: String?  // YYYY-MM-DD
    var recoveryKey: String?
    
    class func dynamoDBTableName() -> String {
        return "tntAthlete"
    }
    
    class func hashKeyAttribute() -> String {
        return "athleteId"
    }
    
    convenience init(athleteMO : Athlete) {
        
        guard athleteMO.id != nil else {
            fatalError("TNT: athlete ID cannot be nil when saving to Dynamo")
        }
        
        self.init()
        
        // Dynamo DB does not allow nil or empty string, so coalesce nil strings to space
        athleteId = athleteMO.id
        firstName = athleteMO.firstName ?? " "
        lastName = athleteMO.lastName ?? " "
        
        eventLevels = athleteMO.eventLevels as! [String : Int]?
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        
        if let birthdate = athleteMO.dob as Date? {
            dob = dateFormatter.string(from: birthdate)
        }
        
        recoveryKey = athleteMO.recoveryKey ?? " "
        
        //cognitoId = athleteMO.cognitoId
        //profileImageURL = athleteMO.profileImageURL
        
    }

}
