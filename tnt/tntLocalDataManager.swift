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
    var meets : [NSManagedObject]
    
    var videos: NSFetchedResultsController<NSManagedObject>?
    
    private init() {
    
    /* Try to load cached data from Core Data.  
       Failing that, setup an empty set of data. 
    */
    
    athletes = []
    meets = []
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
    }
    
    func clearTNTObjects () {
        
        batchDeleteEntity(name: "Athlete"); athletes = []
        batchDeleteEntity(name: "Meet"); meets = []
        batchDeleteEntity(name: "Video"); videos = nil;
        
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
        } catch {
            fatalError("Failed to initialize videos FetchedResultsController: \(error)")
        }
        
    }
    
}


