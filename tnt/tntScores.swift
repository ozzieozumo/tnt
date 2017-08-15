//
//  tntScores.swift
//  tnt
//
//  Created by Luke Everett on 8/3/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation

import AWSDynamoDB

class tntScores : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var scoreId: String?   // compound key athleteId:meetId
    var athleteId: String?
    var meetId: String?
    var events:  Set<String>?
    var scores: [NSDictionary]?
    
    convenience init(scoresMO : NSManagedObject) {
    
        self.init()
        
        // Assumes that a valid scores MO has been received
        
        scoreId = scoresMO.value(forKey: "scoreId") as! String?
        athleteId = scoresMO.value(forKey: "athleteId") as! String?
        meetId = scoresMO.value(forKey: "meetId") as! String?
        events = scoresMO.value(forKey: "events") as! Set<String>?
        scores = scoresMO.value(forKey: "scores") as! [NSDictionary]?

    }
    
    class func dynamoDBTableName() -> String {
        return "tntScores"
    }
    
    class func hashKeyAttribute() -> String {
        return "scoreId"
    }
}
