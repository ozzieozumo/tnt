//
//  Athlete+TNT.swift
//  tnt
//
//  Created by Luke Everett on 9/26/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import AWSS3

extension Athlete {
    
    convenience init(dbAthlete: tntAthlete) {
        
        self.init(context: tntLocalDataManager.shared.moc!)
        
        self.id = dbAthlete.athleteId
        self.cognitoId = dbAthlete.cognitoId
        self.firstName = dbAthlete.firstName
        self.lastName = dbAthlete.lastName
        self.eventLevels = dbAthlete.eventLevels as NSObject?
        
        
        
    }
    
    func saveLocal() {
        
        do {
            try tntLocalDataManager.shared.moc!.save()
            tntLocalDataManager.shared.athletes[id!] = self
        } catch let error as NSError {
            print("TNT: could not save athlete to core data. \(error), \(error.userInfo)")
        }
        
        // send a notification indicating that an athlete was loaded
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("tntAthleteDataLoaded"), object: nil, userInfo: ["ahtleteId":self.id!])
        
        
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
    
    func backgroundSaveImage(success: @escaping (_ result: URL?) -> Void) {
        
        // saves the current profile image from Coredata to S3
        // returns via completion handler either the URL of the saved image or an error code on failure
        
        guard let imgData = self.profileImage else {
            print("TNT Athlete: save image called but profile image data is nil")
            return
        }
        
        do {
            try FileManager.default.createDirectory(
                at: NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("upload")!,
                withIntermediateDirectories: true,
                attributes: nil)
        } catch {
            print("Creating 'upload' directory failed. Error: \(error)")
        }
        
        let filename = "profiles/" + self.id! + ".png"
        
        let localFileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("upload")?.appendingPathComponent(filename)
        
        do {
            try imgData.write(to: localFileURL!, options: [.atomic])
        } catch {
            print("TNT error creating local file for profile image upload \(error)")
            return
        }
        
        // local file is ready, now upload to S3
        
        let transferManager = AWSS3TransferManager.default()
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        
        uploadRequest!.bucket = "ozzieozumo.tnt"
        uploadRequest!.key = filename
        uploadRequest!.body = localFileURL!
        
        transferManager.upload(uploadRequest!).continueWith { (task) -> AnyObject! in
            if let error: NSError = task.error as NSError? {
                if error.domain == AWSS3TransferManagerErrorDomain as String {
                    if let errorCode = AWSS3TransferManagerErrorType(rawValue: error.code) {
                        switch (errorCode) {
                        case .cancelled, .paused:
                            // update UI on main queue
                            break;
                            
                        default:
                            print("upload() failed: [\(error)]")
                            break;
                        }
                    } else {
                        print("upload() failed: [\(error)]")
                    }
                } else {
                    print("upload() failed: [\(error)]")
                }
            } else {
                
                // Succesful Upload
                
                let remoteURL = URL(string: "https://s3.amazonaws.com/" + uploadRequest!.bucket! + "/" + filename)
                success(remoteURL)
            }
            return task
        }
        
    }
        
}

