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
        self.loadMeets()
        
                
    }

    func loadAthletes() {
        
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.load(tntAthlete.self, hashKey: "1", rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as? NSError {
                print("The request failed. Error: \(error)")
            } else if let athlete = task.result as? tntAthlete {
                
                print("TNT: retrieved name" + athlete.firstName! + athlete.lastName!)
                
                // create a managed object and store it
                
                guard let appDelegate =
                    UIApplication.shared.delegate as? AppDelegate else {
                        return nil
                }
                
                let managedContext = appDelegate.persistentContainer.viewContext
                let entity = NSEntityDescription.entity(forEntityName: "Athlete", in: managedContext)!
                
                let managedObject = NSManagedObject(entity: entity, insertInto: managedContext)
                managedObject.setValue(athlete.athleteId, forKeyPath: "id")
                managedObject.setValue(athlete.firstName, forKeyPath: "firstName")
                managedObject.setValue(athlete.lastName, forKeyPath: "lastName")
                managedObject.setValue(athlete.eventLevels, forKeyPath: "eventLevels")
                
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
        
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.limit = 100
        
        dynamoDBObjectMapper.scan(tntVideo.self, expression: scanExpression).continueWith(block: { (task) -> Void in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else if let paginatedOutput:AWSDynamoDBPaginatedOutput = task.result {
                
                for video in paginatedOutput.items as! [tntVideo] {
                    
                    print("TNT: retrieved video \(video.cloudURL ?? "no URL")")
                    
                    let context = tntLocalDataManager.shared.moc
                    let entity = NSEntityDescription.entity(forEntityName: "Video", in: context!)!
                    let managedObject = NSManagedObject(entity: entity, insertInto: context)
                    
                    managedObject.setValue(video.cloudURL, forKeyPath: "cloudURL")
                    managedObject.setValue(video.localIdentifier, forKeyPath: "localIdentifier")
                    
                    do {
                        try context?.save()
                        
                    } catch let error as NSError {
                        print("Could not save. \(error), \(error.userInfo)")
                    }
                    
                }
                
                // fetch the results in coredata
                
                tntLocalDataManager.shared.fetchRelatedVideos()
                
                // send a notification indicating new athlete data
                
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name("tntVideoLoaded"), object: nil, userInfo: nil)
                
            }
    
        })

        
    }
    
    func loadMeets() {
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.limit = 100
        
        dynamoDBObjectMapper.scan(tntMeet.self, expression: scanExpression).continueWith(block: { (task) -> Void in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else if let paginatedOutput = task.result as? AWSDynamoDBPaginatedOutput {
                
                
                for meet in paginatedOutput.items as! [tntMeet] {
                    
                    print("TNT: retrieved meet \(meet.meetTitle ?? "no URL")")
                    
                    let context = tntLocalDataManager.shared.moc
                    let entity = NSEntityDescription.entity(forEntityName: "Meet", in: context!)!
                    let managedObject = NSManagedObject(entity: entity, insertInto: context)
                    
                    managedObject.setValue(meet.meetId, forKeyPath: "id")
                    managedObject.setValue(meet.meetTitle, forKeyPath: "Title")
                    managedObject.setValue(meet.meetSubTitle, forKeyPath: "SubTitle")
                    
                    do {
                        try context?.save()
                        
                    } catch let error as NSError {
                        print("TNT: Could not save meet to CoreData. \(error), \(error.userInfo)")
                    }
                    
                }
                
                // fetch the results in coredata
                
                tntLocalDataManager.shared.fetchMeets()
                
                // send a notification indicating new meet data
                
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name("tntMeetLoaded"), object: nil, userInfo: nil)
                
            }
            
        })
        
        
    }
    
    func loadScores(athleteId: String, meetId: String) {
        
        // load score data from cloud DB to core data
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.load(tntScores.self, hashKey: "1:1", rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else if let scores = task.result as? tntScores {
                
                print("TNT: retrieved scores for" + scores.scoreId!)
                
                // create a managed object and store it
                
                guard let appDelegate =
                    UIApplication.shared.delegate as? AppDelegate else {
                        return nil
                }
                
                let managedContext = appDelegate.persistentContainer.viewContext
                let entity = NSEntityDescription.entity(forEntityName: "Scores", in: managedContext)!
                
                let managedObject = NSManagedObject(entity: entity, insertInto: managedContext)
                managedObject.setValue(scores.athleteId, forKeyPath: "athleteId")
                managedObject.setValue(scores.meetId, forKeyPath: "meetId")
                managedObject.setValue(scores.scoreId, forKeyPath: "scoreId")
                managedObject.setValue(scores.events, forKeyPath: "events")
                managedObject.setValue(scores.scores, forKeyPath: "scores")
                
                do {
                    try managedContext.save()
                    tntLocalDataManager.shared.scores[scores.scoreId!] = managedObject
                } catch let error as NSError {
                    print("Could not save scores to CoreData. \(error), \(error.userInfo)")
                }
                
                
                // send a notification indicating new scores data
                
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name("tntScoresLoaded"), object: nil, userInfo: ["ahtleteId":scores.athleteId!,
                                                                                            "meetId": scores.meetId!])
                
            }
            return nil
        })

        
        
    }
    

    
    func createVideo(s3VideoKey: String) {
    
        guard let newVideo = tntVideo() else {
            print("Could not create TNT video")
            return
        }
        newVideo.cloudURL = s3VideoKey
        newVideo.localIdentifier  = "NIL"
        newVideo.videoId = s3VideoKey
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()

        dynamoDBObjectMapper.save(newVideo).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else {
                print("TNT synch manager created video item")
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
