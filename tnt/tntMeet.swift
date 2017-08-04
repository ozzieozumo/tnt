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

    
    class func dynamoDBTableName() -> String {
        return "tntMeet"
    }
    
    class func hashKeyAttribute() -> String {
        return "meetId"
    }
}
