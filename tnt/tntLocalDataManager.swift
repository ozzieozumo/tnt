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
    
    var athletes : [NSManagedObject]
    var meets : [NSManagedObject]
    
    private init() {
    
    /* Try to load cached data from Core Data.  
       Failing that, setup an empty set of data. 
    */
        
    athletes = []
    meets = []
    return
 
    }
    
    func loadLocalData() {
        // do nothing for now
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Athlete")
        
        do {
            athletes = try managedContext.fetch(fetchRequest)
            print("tntLocalDataManager: retrieve \(athletes.count) athletes")
        } catch let error as NSError {
            print("Could not fetch athletes from core data. \(error), \(error.userInfo)")
        }
    }
    
    func clearTNTObjects () {
        
        batchDeleteEntity(name: "Athlete"); athletes = []
        batchDeleteEntity(name: "Meet"); meets = []
        //batchDeleteEntity(name: "Video"); videos = []
        
    }
    
    func batchDeleteEntity(name: String) {
    
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedContext.execute(batchDelete)
            try managedContext.save()
            print("tntLocalDataManager: deleted all managed \(name) objects")
        } catch let error as NSError {
            print("Could not delete \(name) objects \(error), \(error.userInfo)")
        }
    }
    
}


