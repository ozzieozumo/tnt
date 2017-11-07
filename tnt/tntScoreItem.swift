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
    var score: Float?            // The net score (N) = (E) + (D) - (P) + (F) + (H)
    var execution: Float?         // Execution or base score (E)
    var difficulty: Float?        // Degree of difficulty bonus (D)
    var penalty: Float?           // Penalty or deductions (P)
    var flight: Float?            // Time of flight (F) (only scored at elite levels)
    var displacement: Float?      // horizontal displacement (H) (not sccored separately in US)

    init(_ scoreDictionary: [String: Any]) {
        // inits a scoreItem from a dictionary retrieved from teh Scores managed object
        
        event = scoreDictionary["event"] as! String
        pass  = scoreDictionary["pass"] as! Int
        score = scoreDictionary["score"] as! Float?
        level = (scoreDictionary["level"] ?? 0) as! Int
        execution = scoreDictionary["execution"] as! Float?
        difficulty = scoreDictionary["difficulty"] as! Float?
        penalty = scoreDictionary["penalty"] as! Float?
        flight = scoreDictionary["flight"] as! Float?
        execution = scoreDictionary["execution"] as! Float?
        
    }
    
    func toDictionary() -> [String: Any] {
        
        var scoreDict: [String: Any] = [:]
        
        scoreDict["event"] = event
        scoreDict["pass"] = pass
        scoreDict["score"] = score
        scoreDict["level"] = level
        scoreDict["execution"] = execution
        scoreDict["difficulty"] = difficulty
        scoreDict["penalty"] = penalty
        scoreDict["flight"] = flight
        scoreDict["displacement"] = displacement
        
        return scoreDict
    }
    
}
