//
//  tntScoreItem.swift
//  tnt
//  Model class for a single scored event, e.g. Trampoline 1st pass.
//  Typically, each athlete will have multiple scoreItems for each meet.
//  The Scores managed object stores the scoreItems as an array of dictionaries.
//  The same representation is used in the cloud DB.
//  This class unwraps the [String: Any] dictionary into a model object.
//
//  Created by Luke Everett on 10/31/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import Foundation

class tntScoreItem{
    var event: String
    var pass: UInt
    var score: Float

    init(_ scoreDictionary: [String: Any]) {
        // inits a scoreItem from a dictionary retrieved from teh Scores managed object
        
        event = scoreDictionary["event"] as! String
        pass  = scoreDictionary["pass"] as! UInt
        score = scoreDictionary["score"] as! Float
        
    }
    
    func toDictionary() -> [String: Any] {
        
        var scoreDict: [String: Any] = [:]
        
        scoreDict["event"] = event
        scoreDict["pass"] = pass
        scoreDict["score"] = score
        
        return scoreDict
    }
    
}
