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
    var athletes : [NSManagedObject]
    var scores : [String: NSManagedObject]
    var meets : NSFetchedResultsController<NSManagedObject>?
    
    var videos: NSFetchedResultsController<NSManagedObject>?
    
    private init() {
    
    /* Try to load cached data from Core Data.  
       Failing that, setup an empty set of data. 
    */
    
    athletes = []
    scores = [:]
    meets = NSFetchedResultsController()
    videos = NSFetchedResultsController()
    moc = nil
        
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        print("tntLocalDataManager: could not get application delegate")
        return
    }
    
    moc = appDelegate.persistentContainer.viewContext
    return
 
    }
    
    func loadLocalData() {
        // do nothing for now
        
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Athlete")
        
        do {
            athletes = try moc!.fetch(fetchRequest)
            print("tntLocalDataManager: retrieve \(athletes.count) athletes")
        } catch let error as NSError {
            print("Could not fetch athletes from core data. \(error), \(error.userInfo)")
        }
        
        fetchRelatedVideos()
        fetchMeets()
    }
    
    func clearTNTObjects () {
        
        batchDeleteEntity(name: "Athlete"); athletes = []
        batchDeleteEntity(name: "Meet"); meets = nil
        batchDeleteEntity(name: "Video"); videos = nil
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
    
    func fetchRelatedVideos() {
    
        let request = NSFetchRequest<NSManagedObject>(entityName: "Video")
        let dateSort = NSSortDescriptor(key: "publishDate", ascending: true)
        request.sortDescriptors = [dateSort]
        
        self.videos = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc!, sectionNameKeyPath: nil, cacheName: nil)
        // videos.delegate = self
        
        do {
            try videos?.performFetch()
            let videoCount = videos?.fetchedObjects?.count ?? 0
            print("TNT Local Data Manager:  fetched \(videoCount) videos")
        } catch {
            fatalError("Failed to initialize videos FetchedResultsController: \(error)")
        }
        
    }
    
    func fetchMeets() {
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "Meet")
        let dateSort = NSSortDescriptor(key: "startDate", ascending: true)
        request.sortDescriptors = [dateSort]
        
        self.meets = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc!, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try meets?.performFetch()
            let meetCount = meets?.fetchedObjects?.count ?? 0
            print("TNT Local Data Manager:  fetched \(meetCount) meets")
        } catch {
            fatalError("Failed to initialize meets FetchedResultsController: \(error)")
        }
        
    }
    
    func fetchScores(_ scoreId: String) {
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Scores")
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
    
    func getPendingScoreUpdates() -> [NSManagedObject] {
        
        // return an array of MOs for each Score in a pending upload state
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Scores")
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

    
}


