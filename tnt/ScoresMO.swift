//
//  Scores+TNT.swift
//  tnt
//
//  Created by Luke Everett on 9/26/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//
//

import Foundation
import CoreData


extension Scores {
    
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
        
        cloudSavePending = true
        
        do {
            try tntLocalDataManager.shared.moc!.save()
            tntLocalDataManager.shared.scores[scoreId!] = self
        } catch let error as NSError {
            print("TNT: could not save scores to core data. \(error), \(error.userInfo)")
        }
        
        
        // send a notification indicating that scores data was loaded
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("tntScoresLoaded"), object: nil, userInfo: ["scoreId":self.scoreId!])
        
    }
    
    func clearCloudSavePending() {
        
        cloudSavePending = false
        cloudSaveDate = Date() as NSDate
        
        do {
            try tntLocalDataManager.shared.moc!.save()
            
        } catch let error as NSError {
            print("TNT: could not save scores to core data. \(error), \(error.userInfo)")
        }
        
    }
    
    func addVideo(relatedVideoId: String) {
        
        if !containsVideo(id: relatedVideoId) {
            
            var newVideoDicts: [[String:Any]]
            
            if let oldVideoDicts = videos as? [[String:Any]] {
                
                newVideoDicts = oldVideoDicts
            } else {
                
                newVideoDicts =  []
            }
            
            newVideoDicts.append(["videoId" : relatedVideoId])
            
            videos = newVideoDicts as NSObject
            saveLocal()
            
            // send a notification including the videoId AND the scoreId
            
            let nc = NotificationCenter.default
            nc.post(name: Notification.Name("tntScoresNewVideo"), object: nil, userInfo: ["scoreId":self.scoreId!,
                                                                                          "videoId":relatedVideoId])
            
            // background:  write the updates scores object back to Dynamo
            
            tntSynchManager.shared.saveScores(scoreId!)
        }
        
        
        
    }
    
    func deleteVideo(relatedVideoId: String) {
        
        var vDicts = videos as? [[String: Any]] ?? []
        
        
        for (i, dict) in vDicts.enumerated() {
                
                if dict["videoId"] as? String == relatedVideoId {
                        vDicts.remove(at: i)
                }
        }
        
        self.videos = vDicts as NSObject
        saveLocal()
       
        // send a notification including the videoId AND the scoreId
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("tntScoresDeletedVideo"), object: nil, userInfo: ["scoreId":self.scoreId!,
                                                                                      "videoId":relatedVideoId])
        
        // background:  write the updates scores object back to Dynamo
        
        tntSynchManager.shared.saveScores(scoreId!)
        
    }
    
    func containsVideo(id: String) -> Bool {
        
        if let vDicts = videos as? [[String:Any]] {
            
            for v in vDicts {
                if v["videoId"] as? String == id {
                    return true
                }
            }
        }
        return false
    }

        
}
