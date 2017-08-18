//
//  Athlete+CoreDataProperties.swift
//  tnt
//
//  Created by Luke Everett on 8/16/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation
import CoreData


extension Athlete {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Athlete> {
        return NSFetchRequest<Athlete>(entityName: "Athlete")
    }

    @NSManaged public var eventLevels: NSObject?
    @NSManaged public var firstName: String?
    @NSManaged public var id: String?
    @NSManaged public var lastName: String?
    @NSManaged public var profileImage: NSData?
    @NSManaged public var registered: Meet?
    
    convenience init(dbAthlete: tntAthlete, loadImage: Bool = true) {
        
        self.init(context: tntLocalDataManager.shared.moc!)
        
        self.id = dbAthlete.athleteId
        self.firstName = dbAthlete.firstName
        self.lastName = dbAthlete.lastName
        self.eventLevels = dbAthlete.eventLevels as NSObject?
        
        do {
            try tntLocalDataManager.shared.moc!.save()
            tntLocalDataManager.shared.athletes.append(self)
        } catch let error as NSError {
            print("TNT: could not save athlete to core data. \(error), \(error.userInfo)")
        }
        
        // send a notification indicating that an athlete was loaded
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("tntMoreAthletes"), object: nil, userInfo: ["ahtleteId":self.id!])

        
        // background request to fill in the image data
        
        if loadImage {
            self.backgroundLoadImage(imageURL: dbAthlete.profileImageURL)
        }
        
    }
    
    func backgroundLoadImage(imageURL: String?) {
        
        guard let url = imageURL, !url.isEmpty else {
        
            print("TNT: cannot load nil/empty image URL")
            return
        }
        
        var s3imgURL : URL?
        
        DispatchQueue.global().sync {

            s3imgURL = URL(string: tntSynchManager.shared.tntPreSignedURL(unsignedURL: url))
        }
        
        let session = URLSession(configuration: .default)
        let downloadTask = session.dataTask(with: s3imgURL!) {
            (data, response, error) in
            
            if error != nil {
                print("TNT: error downloading athlete profile picture: \(error!)")
            } else {
                if let imgData = data {
                    self.profileImage = imgData as NSData?
                    
                    do {
                        try tntLocalDataManager.shared.moc!.save()
                    } catch let error as NSError {
                        print("TNT: could not save athlete profile image to core data. \(error), \(error.userInfo)")
                    }
                    
                    // send a separate message for the image load, which can take longer
                    
                    let nc = NotificationCenter.default
                    nc.post(name: Notification.Name("tntProfileImageLoaded"), object: nil, userInfo: ["ahtleteId":self.id!])
                    
                } else {
                    print("TNT: image download succeeded but data was nil")
                }
            }
            
        }
        
        downloadTask.resume()
    }

}
