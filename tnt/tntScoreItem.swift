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
    
    static let passNames: [String] = ["1st Pass", "2nd Pass"]
    static let unitValues = 0...30
    static let decimalValues = [".00", ".10", ".20", ".30", ".40", ".50", ".60", ".70", ".80", ".90"]
    static let eventNames: [String: String] = ["DMT": "Double Mini",
                                               "TR": "Trampoline",
                                               "TU": "Tumbling"]
    
    var event: String
    var pass: Int
    var level: Int
    var score: Float?

    init(_ scoreDictionary: [String: Any]) {
        // inits a scoreItem from a dictionary retrieved from teh Scores managed object
        
        event = scoreDictionary["event"] as! String
        pass  = scoreDictionary["pass"] as! Int
        score = scoreDictionary["score"] as! Float?
        level = (scoreDictionary["level"] ?? 0) as! Int
        
    }
    
    func toDictionary() -> [String: Any] {
        
        var scoreDict: [String: Any] = [:]
        
        scoreDict["event"] = event
        scoreDict["pass"] = pass
        scoreDict["score"] = score
        scoreDict["level"] = level
        
        return scoreDict
    }
    
}
