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
import UIKit

class tntScoreItem{
    
    static let passNames: [String] = ["Event Header", "1st Pass", "2nd Pass"]
    static let unitValues = 0...30
    static let decimalValues = [".00", ".10", ".20", ".30", ".40", ".50", ".60", ".70", ".80", ".90"]
    static let eventNames: [String: String] = ["DMT": "Double Mini",
                                               "TR": "Trampoline",
                                               "TU": "Tumbling"]
    
    static let medalInfo: [String: (name: String, image: UIImage?)] = ["gold": ("Gold", #imageLiteral(resourceName: "goldmedal")),
                                                                       "silver": ("Silver", #imageLiteral(resourceName: "silvermedal")),
                                                                       "bronze": ("Bronze", #imageLiteral(resourceName: "bronzemedal")),
                                                                       "podium": ("Podium", nil),
                                                                       "other": ("Other", nil)]
    
    static let medalKeys: [String] = ["gold", "silver", "bronze", "podium", "other"]
    
    
    var event: String
    var pass: Int
    var level: Int = 0
    var score: Float?  = nil           // The net score (N) = (E) + (D) - (P) + (F) + (H)
    var execution: Float? = nil        // Execution or base score (E)
    var difficulty: Float? = nil        // Degree of difficulty bonus (D)
    var penalty: Float? = nil           // Penalty or deductions (P)
    var flight: Float? = nil           // Time of flight (F) (only scored at elite levels)
    var displacement: Float? = nil     // horizontal displacement (H) (not sccored separately in US)
    
    // applicable for event headers only
    var medal: String? = nil
    var qualified: Bool = false
    var mobilized: Bool = false
    
    init(_ event: String, _ pass: Int) {
        self.event = event
        self.pass = pass
    }

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
        medal = scoreDictionary["medal"] as! String?
        qualified = (scoreDictionary["qualifying"] as! Bool?) ?? false
        mobilized = (scoreDictionary["mobilizing"] as! Bool?) ?? false
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
        scoreDict["medal"] = medal
        scoreDict["qualifying"] = qualified
        scoreDict["mobilizing"] = mobilized
        
        return scoreDict
    }
    
}
