//
//  Scores+CoreDataClass.swift
//  tnt
//
//  Created by Luke Everett on 8/16/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation
import CoreData


public class Scores: NSManagedObject {
    
    convenience init(dbScores: tntScores) {
        
        self.init(context: tntLocalDataManager.shared.moc!)
        
        self.scoreId = dbScores.scoreId
        self.athleteId = dbScores.athleteId
        self.meetId = dbScores.meetId
        self.events = dbScores.events as NSObject?
        self.scores = dbScores.scores as NSObject?
        self.videos = dbScores.videos as NSObject?
        
        
        
    }
    
    func saveLocal() {
        
        do {
            try tntLocalDataManager.shared.moc!.save()
            tntLocalDataManager.shared.scores[scoreId!] = self
        } catch let error as NSError {
            print("TNT: could not save scores to core data. \(error), \(error.userInfo)")
        }
        
        
        // send a notification indicating that scores data was loaded
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("tntScoresDataLoaded"), object: nil, userInfo: ["scoreId":self.scoreId!])

        
    }

}
