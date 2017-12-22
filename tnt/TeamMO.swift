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
    
    // not sure about this function
    class func fetchAndCache(_ teamId: String) {
        
        let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "teamId == %@", teamId)
        
        do {
            let moc = tntLocalDataManager.shared.moc!
            let teams = try moc.fetch(fetchRequest)
            if teams.count > 0 {
                
                tntLocalDataManager.shared.teams[teamId] = teams[0]
                
            }
            print("TNT: fetch and cache team \(teamId)")
            
        } catch let error as NSError {
            print("Could not fetch team from core data. \(error), \(error.userInfo)")
        }
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
    
   
    func addCurrentUser() {
        // add the cognito ID of the currently logged in user
        
        guard tntLoginManager.shared.loggedIn else {
            print("TNT TeamMO: addCurrentUser, not logged in")
            return
        }
        
        if let currentUserId = tntLoginManager.shared.cognitoId {
            addUser(userId: currentUserId)
        }
        
    }
    
    func addUser(userId: String) {
   
        var userArray = userIds as! [String]? ?? []
    
        
        if !userArray.contains(userId) {
            userArray.append(userId)
        }
        
        userIds = userArray as NSObject
    }
    
    func addAthlete(athleteId: String) {
        
        var athleteArray = athleteIds as! [String]? ?? []
        
        
        if !athleteArray.contains(athleteId) {
            athleteArray.append(athleteId)
        }
        
        athleteIds = athleteArray as NSObject
    }
    
    func updateFromCloud(dbTeam: tntTeam) {
        // like init from db but doesn't create a new managed object in the context
        self.teamId = dbTeam.teamId
        self.name = dbTeam.teamName
        self.secret = dbTeam.teamSecret
        self.athleteIds = dbTeam.athleteIds as NSObject?
        self.userIds = dbTeam.userIds as NSObject?
    }

   
}
