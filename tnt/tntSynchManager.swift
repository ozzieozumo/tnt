//
//  tntSynchManager.swift
//  
//  Manages synchronization of app data between the cloud DB (AWS DynamoDB) and the local cache (Core Data)
//
//  Created by Luke Everett on 5/11/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation
import CoreData
import AWSCore
import AWSDynamoDB
import AWSS3

class tntSynchManager {
    
    static let shared = tntSynchManager()
    
    private init(){
        
    }
    
    func loadCache() {
        // Launch tasks to populate the local cache with information for the given Cognito user ID
        
        // TODO:  probably should set some sort of context object on the singleton
        
        self.loadAthletes()
        
        // load the other stuff too .. 
        
    }

    func loadAthletes() {
        
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let startDDB = DispatchTime.now()
        
        dynamoDBObjectMapper.load(tntAthlete.self, hashKey: "1", rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as? NSError {
                print("The request failed. Error: \(error)")
            } else if let athlete = task.result as? tntAthlete {
                
                let endDDB = DispatchTime.now()
                
                let execSecs = Double(endDDB.uptimeNanoseconds - startDDB.uptimeNanoseconds) / 1000000000
                print("extime DDB get \(execSecs) seconds")
                
                print("TNT: retrieved name" + athlete.firstName! + athlete.lastName!)
                
                
                // create a managed object and store it
                
                guard let appDelegate =
                    UIApplication.shared.delegate as? AppDelegate else {
                        return nil
                }
                
                let managedContext = appDelegate.persistentContainer.viewContext
                let entity = NSEntityDescription.entity(forEntityName: "Athlete", in: managedContext)!
                
                let managedObject = NSManagedObject(entity: entity, insertInto: managedContext)
                
                managedObject.setValue(athlete.firstName, forKeyPath: "firstName")
                managedObject.setValue(athlete.lastName, forKeyPath: "lastName")
                
                do {
                    try managedContext.save()
                    tntLocalDataManager.shared.athletes.append(managedObject)
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }

                
                // send a notification indicating new athlete data
                
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name("tntMoreAthletes"), object: nil, userInfo: ["ahtleteId":athlete.athleteId])
                
                
                // load the profile image from the URL
                
                let startSign = DispatchTime.now()
                let s3imgURL = URL(string: self.tntPreSignedURL(unsignedURL: athlete.profileImageURL!))
                let endSign = DispatchTime.now()
                
                let signSecs = Double(endSign.uptimeNanoseconds - startSign.uptimeNanoseconds) / 1000000000
                print("extime URL Signing\(signSecs) seconds")

                
                let startImgGet = DispatchTime.now()
                let imgData = try? Data(contentsOf: s3imgURL!, options: [])
                
                managedObject.setValue(imgData, forKeyPath: "profileImage")
                
                do {
                    try managedContext.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }

                
                let endImgGet = DispatchTime.now()
                
                let imgSecs = Double(endImgGet.uptimeNanoseconds - startImgGet.uptimeNanoseconds) / 1000000000
                print("extime Img Get  \(imgSecs) seconds")

                // send a separate message for the image load, which can take longer
                
                nc.post(name: Notification.Name("tntProfileImageLoaded"), object: nil, userInfo: ["ahtleteId":athlete.athleteId])

                
                
                // receiver will need to switch to main thread for UI updates
        
            }
            return nil
        })
    }

    func loadVideos() {
    
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.load(tntVideo.self, hashKey: "1", rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else if let video = task.result as? tntVideo {
                
                
                print("TNT: retrieved video \(video.cloudURL ?? "no URL")")
                
                guard let context = tntLocalDataManager.shared.moc else {
                    return nil
                }
                let entity = NSEntityDescription.entity(forEntityName: "Video", in: context)!
                
                let managedObject = NSManagedObject(entity: entity, insertInto: context)
                
                managedObject.setValue(video.cloudURL, forKeyPath: "cloudURL")
                managedObject.setValue(video.localIdentifier, forKeyPath: "localIdentifier")
                
                do {
                    try context.save()
                    
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
                
                
                // send a notification indicating new athlete data
                
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name("tntVideoLoaded"), object: nil, userInfo: ["videoId":video.videoId])
                
            }
            return nil
        })

        
    }
    
    
    func tntPreSignedURL(unsignedURL: String) -> String {
                
                var preSignedURL : String? = nil
                let signingGroup = DispatchGroup()
                
                precondition(!Thread.isMainThread, "tntPreSignedURL : don't call this func from the main thread")
                
                let preSignedRequest = AWSS3GetPreSignedURLRequest()
                preSignedRequest.bucket = "ozzieozumo.tnt"
                
                // find the key (filename) starting after ozzieozumo.tnt/
                
                let keyStart = unsignedURL.index(unsignedURL.range(of: preSignedRequest.bucket)!.upperBound, offsetBy: 1)
                
                preSignedRequest.key = unsignedURL.substring(from: keyStart)
                preSignedRequest.httpMethod = .GET
                preSignedRequest.expires = Date().addingTimeInterval(48*60*60)
                
                let preSigner = AWSS3PreSignedURLBuilder.default()
                
                // not sure about this structure -- I want to treat this function as a synchronous call.
                // Using the dispatchgroup and wait is one way to to do that.  Alternatively, the function could accept a completion handler.
                // Perhaps, I should check inside the function that it is never being called on the main thread (which shouldn't wait on asynch tasks.
                // However, it seems perfectly fine to have other (non main queue) tasks wait for this call to succeeed or fail
                
                signingGroup.enter()
                
                preSigner.getPreSignedURL(preSignedRequest).continueWith {
                    (task) in
                    
                    if let error = task.error as? NSError {
                        print("Error: \(error)")
                        signingGroup.leave()
                        return nil
                    }
                    
                    preSignedURL = task.result!.absoluteString
                    print("Download presignedURL is: \(preSignedURL)")
                    signingGroup.leave()
                    return nil
                    
                }
                
                signingGroup.wait()
                return preSignedURL!
            }


}
