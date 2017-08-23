//
//  Meet+CoreDataClass.swift
//  tnt
//
//  Created by Luke Everett on 8/16/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation
import CoreData


public class Meet: NSManagedObject {
    
    convenience init(dbMeet: tntMeet) {
        
        self.init(context: tntLocalDataManager.shared.moc!)
        
        self.id = dbMeet.meetId
        self.city = dbMeet.meetCity
        self.venue = dbMeet.meetVenue
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        self.startDate = dateFormatter.date(from: dbMeet.meetStartDate!)! as NSDate
        self.endDate = dateFormatter.date(from: dbMeet.meetEndDate!)! as NSDate
        self.minLevel = Int16((dbMeet.meetLevels!)[0])
        self.maxLevel = Int16((dbMeet.meetLevels!)[dbMeet.meetLevels!.count - 1])
        self.events = dbMeet.meetEvents as NSObject?
        self.title = dbMeet.meetTitle
        self.subTitle = dbMeet.meetSubTitle
        
    }
    
    func saveLocal() {
        
        do {
            try tntLocalDataManager.shared.moc!.save()
            tntLocalDataManager.shared.fetchMeets()
            
        } catch let error as NSError {
            print("TNT: could not save scores to core data. \(error), \(error.userInfo)")
        }
        
        
        // send a notification indicating that meet data was saved to CoreData
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("tntMeetDataLoaded"), object: nil, userInfo: ["meetId":self.id!])
        
        
    }
    


}
