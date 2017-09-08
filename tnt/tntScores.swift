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
    var videos: [NSDictionary]?
    
    convenience init(scoresMO : Scores) {
    
        self.init()
        
        scoreId = scoresMO.scoreId
        athleteId = scoresMO.athleteId
        meetId = scoresMO.meetId
        events = scoresMO.events as! Set<String>?
        scores = scoresMO.scores as! [NSDictionary]?
        videos = scoresMO.videos as! [NSDictionary]?
        

    }
    
    class func dynamoDBTableName() -> String {
        return "tntScores"
    }
    
    class func hashKeyAttribute() -> String {
        return "scoreId"
    }
}
