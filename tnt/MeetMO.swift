//
//  Meet+TNT.swift
//  tnt
//
//  Created by Luke Everett on 9/26/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import Foundation
import CoreData

extension Meet {
    
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
        self.sharedStatus = dbMeet.sharedStatus ?? false
        self.sharedTeam = dbMeet.sharedTeam
        
    }
    
    convenience init(name: String) {
        
        // inits a new MeetMO with a new UUID
        self.init(context: tntLocalDataManager.shared.moc!)
        
        self.id = UUID().uuidString
        self.title = name
        
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
    
    
    // MARK - Class Functions
    
    class func lastSelected() -> Meet? {
        
        // return the last selected meet or nil
        
        let defaults = UserDefaults.standard
        if let lastSelectedMeetId = defaults.string(forKey: "tntLastSelectedMeetId") {
            return tntLocalDataManager.shared.meets[lastSelectedMeetId]
        }
        
        return nil
        
    }
    
    class func setLastSelected(meetId: String?) {
        
        // set the last selected meetId
        
        let defaults = UserDefaults.standard
        
        if meetId != nil {
            defaults.set(meetId, forKey: "tntLastSelectedMeetId")
            defaults.synchronize()
        } else {
            defaults.removeObject(forKey: "tntLastSelectedMeetId")
        }
    }
    
    class func nextMeet(startDate: Date) -> Meet? {
        
        // return the next meet, starting on or after the given start date (or nil)
        
        for meet in tntLocalDataManager.shared.availableMeets() {
            
            if let meetStart = meet.startDate as Date? {
                if meetStart >= startDate {
                    return meet
                }
            }
            
        }
        return nil
    }
    
    class func fetchAllPrivateMeets(completion: @escaping () -> Void) {
        
        DispatchQueue.global().async {
    
            let request: NSFetchRequest<Meet> = Meet.fetchRequest()
            // request.predicate = NSPredicate(format: "sharedStatus == false")
            do {
                let fetchedMeetsArray = try tntLocalDataManager.shared.moc!.fetch(request)
                for meet in fetchedMeetsArray {
                    tntLocalDataManager.shared.meets[meet.id!] = meet
                    print("TNT Local Data Manager fetched meet with id : \(meet.id!)")
                }
                completion()
            } catch {
                fatalError("TNT Local Data Manager exception retrieving meets: \(error)")
            }
        }
    }
}
