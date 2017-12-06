//
//  TeamMO.swift
//  tnt

import Foundation
import CoreData
import UIKit
import AWSS3

extension Team {
    
    convenience init(dbTeam: tntTeam) {
        
        self.init(context: tntLocalDataManager.shared.moc!)
        
        self.teamId = dbTeam.teamId
        self.name = dbTeam.teamName
        self.secret = dbTeam.teamSecret
        self.athleteIds = dbTeam.athleteIds as NSObject?
        self.userIds = dbTeam.userIds as NSObject?
        
    }
    
    convenience init(name: String, secret: String) {
        
        // inits a new TeamMO with a new UUID
        self.init(context: tntLocalDataManager.shared.moc!)
        
        self.teamId = UUID().uuidString
        self.name = name
        self.secret = secret
        self.athleteIds = nil
        self.userIds = nil
        
    }
    
    func saveLocal() {
        
        do {
            try tntLocalDataManager.shared.moc!.save()
            tntLocalDataManager.shared.teams[teamId!] = self
        } catch let error as NSError {
            print("TNT: could not save team to core data. \(error), \(error.userInfo)")
        }
        
        // send a notification indicating that an athlete was loaded
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("tntTeamDataLoaded"), object: nil, userInfo: ["teamId":self.teamId!])
        
    }
    
   
}
