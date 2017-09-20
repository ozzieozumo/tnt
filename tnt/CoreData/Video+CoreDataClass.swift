//
//  Video+CoreDataClass.swift
//  tnt
//
//  Created by Luke Everett on 8/16/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation
import CoreData


public class Video: NSManagedObject {
    
    convenience init(dbVideo: tntVideo) {
        
        self.init(context: tntLocalDataManager.shared.moc!)
        
        self.cloudURL = dbVideo.cloudURL
        self.localIdentifier = dbVideo.localIdentifier
        self.videoId = dbVideo.videoId
        
    }
    
    func saveLocal() {
        
        do {
            try tntLocalDataManager.shared.moc!.save()
            tntLocalDataManager.shared.videos[videoId!] = self
            
        } catch let error as NSError {
            print("TNT: could not save video to core data. \(error), \(error.userInfo)")
        }
        
        
        // send a notification indicating that video data was saved to CoreData
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("tntVideoDataLoaded"), object: nil, userInfo: ["videoId":self.videoId!])
        
    }


}
