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
}
