//
//  tntLocalDataManager.swift
//  tnt
//   
//  Manages the local cache of data (in Core Data) used by the app
//
//  Created by Luke Everett on 5/11/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class tntLocalDataManager {
    
    static let shared = tntLocalDataManager()
    
    var moc: NSManagedObjectContext?
    var athletes : [String: Athlete]
    var scores : [String: Scores]
    var meets : [String: Meet]
    var videos: [String: Video]
    
    private init() {
        athletes = [:]
        scores = [:]
        meets = [:]
        videos = [:]
        moc = nil
            
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("tntLocalDataManager: could not get application delegate")
            return
        }
        
        moc = appDelegate.persistentContainer.viewContext
        return
 
    }
    
    func loadLocalData() {
        
        fetchAllAthletes()  
        fetchMeets()
    }
    
    func clearTNTObjects () {
        
        batchDeleteEntity(name: "Athlete"); athletes = [:]
        batchDeleteEntity(name: "Meet"); meets = [:]
        batchDeleteEntity(name: "Video"); videos = [:]
        batchDeleteEntity(name: "Scores"); scores = [:]
        
    }
    
    func batchDeleteEntity(name: String) {
    
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try moc!.execute(batchDelete)
            try moc!.save()
            print("tntLocalDataManager: deleted all managed \(name) objects")
        } catch let error as NSError {
            print("Could not delete \(name) objects \(error), \(error.userInfo)")
        }
    }
    
    func fetchVideo(videoId: String) {
    
        let request: NSFetchRequest<Video> = Video.fetchRequest()
        request.predicate = NSPredicate(format: "videoId == %@", videoId)
        
        do {
            let videoArray = try moc!.fetch(request)
            if videoArray.count > 0 {
                
                videos[videoId] = videoArray[0]
                print("TNT fetched video with id : \(videoId)")
                
            }
        } catch {
            fatalError("Failed to initialize videos FetchedResultsController: \(error)")
        }
        
    }
    
    func fetchAthlete(athleteId: String) {
    
        let request: NSFetchRequest<Athlete> = Athlete.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", athleteId)
        
        do {
            let athleteArray = try moc!.fetch(request)
            if athleteArray.count > 0 {
                
                athletes[athleteId] = athleteArray[0]
                print("TNT Local Data Manager fetched athlete with id : \(athleteId)")
            }
        } catch {
            print("TNT Local Data Manager failed fetching athlete with id : \(athleteId)")
        }
    }
    
    func fetchAllAthletes() {
        
        let request: NSFetchRequest<Athlete> = Athlete.fetchRequest()
        
        do {
            let athleteArray = try moc!.fetch(request)
            
            for athlete in athleteArray {
                athletes[athlete.id!] = athlete
                print("TNT Local Data Manager fetched athlete \(athlete.id!) in fetch ALL")
            }
            
        } catch {
            print("TNT Local Data Manager failed fetching ALL athletes in init")
        }
    }

    
    func loadNewVideo(video: tntVideo) {
        
        // create a videoMO and cache entry for a newly created Dynamo video entry
        
        let videoMO = Video(dbVideo: video)
        videoMO.saveLocal()
        
        // send a notification indicating new video data
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("tntVideoLoaded"), object: nil, userInfo: ["videoId" : videoMO.videoId!])

    }
    
    func fetchMeets() {
        
        let request: NSFetchRequest<Meet> = Meet.fetchRequest()
        
        do {
            let fetchedMeetsArray = try moc!.fetch(request)
            for meet in fetchedMeetsArray {
                meets[meet.id!] = meet
                print("TNT Local Data Manager fetched meet with id : \(meet.id!)")
            }
        } catch {
            fatalError("TNT Local Data Manager exception retrieving meets: \(error)")
        }
        
    }
    
    func availableMeets() -> [Meet] {
        // returns an array of meets available to this athlete; meets are in start date order
        
        let request: NSFetchRequest<Meet> = Meet.fetchRequest()
        let dateSort = NSSortDescriptor(key: "startDate", ascending: true)
        request.sortDescriptors = [dateSort]
        
        do {
            let fetchedMeetsArray = try moc!.fetch(request)
            return fetchedMeetsArray
        } catch {
            fatalError("TNT Local Data Manager exception retrieving meets: \(error)")
        }
    }
    
    func fetchScores(_ scoreId: String) {
        
        let fetchRequest: NSFetchRequest<Scores> = Scores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "scoreId == %@", scoreId)
        
        do {
            let scoresArray = try moc!.fetch(fetchRequest)
            if scoresArray.count > 0 {
                
                self.scores[scoreId] = scoresArray[0]
                
                // TODO: check the timestamp of the item retrieved from core data
                //       if the age exceeds the cahe expiration limit then initiate a 
                //       a synchmanager task to check for a newer item
                
            }
            print("tntLocalDataManager: retrieve \(scoreId) score data")
            
        } catch let error as NSError {
            print("Could not fetch scores from core data. \(error), \(error.userInfo)")
        }
    }
    
    func getPendingScoreUpdates() -> [Scores] {
        
        // return an array of MOs for each Score in a pending upload state
        
        let fetchRequest: NSFetchRequest<Scores> = Scores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cloudSavePending == true")
        
        do {
            let scoresArray = try moc!.fetch(fetchRequest)
            if scoresArray.count > 0 {
                
                return scoresArray
                
            } else {
                return []
            }
            
        } catch let error as NSError {
            print("TNT: getPendingScoreUpdates. \(error), \(error.userInfo)")
        }
        return []
    }
    
    func getAthleteById(athleteId: String) -> Athlete? {
        
        // look in the cache dictionary
        
        if let athlete = athletes[athleteId] {
            return athlete
        } else {
            // try to fetch from coredata
            fetchAthlete(athleteId: athleteId)
            
            if let athlete = athletes[athleteId] {
                return athlete
            } else {
                
                // background request to get from Dyanmo
                tntSynchManager.shared.loadAthletes()
                return nil
                
            }
        }
    }
    
    func getVideoById(videoId: String) -> Video? {
        
        // look in the cache dictionary
        
        if let video = videos[videoId] {
            return video
        } else {
            // try to fetch from coredata 
            fetchVideo(videoId: videoId)
            
            if let video = videos[videoId] {
                return video
            } else {
                
                // background request to get from Dyanmo
                tntSynchManager.shared.loadVideo(videoId: videoId)
                return nil
                
            }
        }
    }
    
    
}


