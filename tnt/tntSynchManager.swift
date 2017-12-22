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
import Photos
import AWSCore
import AWSDynamoDB
import AWSS3

class tntSynchManager {
    
    static let shared = tntSynchManager()
    
    private init(){
        
    }
    
    func loadStandardData() {
        
        guard tntLoginManager.shared.loggedIn else {
            print("TNT Synch Manager: loadStandardData called while not logged in. No action")
            return
        }
        // Launch tasks to populate the local cache with information considered standard for all users
        loadMeets()
    }

    func loadAthletes() {
        
        // TODO - this should be converted to a func that takes an athleteId and loads from Dynamo one at a time
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.load(tntAthlete.self, hashKey: "1", rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else if let athlete = task.result as? tntAthlete {
                
                let moAthlete = Athlete(dbAthlete: athlete)
                moAthlete.saveLocal()
                moAthlete.backgroundLoadImage(imageURL: athlete.profileImageURL)
                
            }
            return nil
        })
    }
    
    func loadAthleteById(athleteId: String, success: @escaping (Athlete) -> Void ) {
        // TODO; maybe this should load all related data for the athlete:  all scoress & video data for all meets
        // or maybe there needs to be a "deep load" function which could be called from Athlete Setup / Reconnecct
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.load(tntAthlete.self, hashKey: athleteId, rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else if let athlete = task.result as? tntAthlete {
                
                // what happens if coredata already has an athlete with this ID?  should overwrite
                
                let moAthlete = Athlete(dbAthlete: athlete)
                moAthlete.saveLocal()
                moAthlete.backgroundLoadImage(imageURL: athlete.profileImageURL)
                success(moAthlete)
            }
            return nil
        })
    }
    
    func athletesSavedByUser(cognitoId: String, handler: @escaping (_ result: [tntAthlete], _ error: NSError?) -> Void) {
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.filterExpression = "cognitoId = :userid"
        scanExpression.expressionAttributeValues = [":userid": cognitoId]
        
        dynamoDBObjectMapper.scan(tntAthlete.self, expression: scanExpression).continueWith(block: { (task:AWSTask<AWSDynamoDBPaginatedOutput>!) -> Any? in
            if let error = task.error as NSError? {
                print("TNT SynchManager: athletesSavedByUser failed to scan athletes \(error)")
                handler([],error)
            } else if let paginatedOutput = task.result {
                handler(paginatedOutput.items as! [tntAthlete], nil)
            }
            return nil
        })
    }
    
    func saveAthlete(athleteId: String) {
        
        if let athleteMO = tntLocalDataManager.shared.athletes[athleteId] {
            
            saveAthleteImage(athleteMO: athleteMO) { (result: URL?) in
            
                let athleteDB = tntAthlete(athleteMO: athleteMO)
                athleteDB.profileImageURL = result?.absoluteString
                
                let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
                
                dynamoDBObjectMapper.save(athleteDB).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
                    if let error = task.error as NSError? {
                        print("TNT synch manager, failed saving athlete object. Error: \(error)")
                        return nil
                    } else {
                        print("TNT synch manager saved athlete item")
                        
                        // clear cloudSavePending flag
                        
                        return nil
                    }
                })
            }
            
        }
        
    }
    
    
    func saveAthleteImage(athleteMO: Athlete, success: @escaping (_ result: URL?) -> Void) {
        
        // saves the current profile image from Coredata to S3
        // returns via completion handler either the URL of the saved image or an error code on failure
        
        guard let imgData = athleteMO.profileImage else {
            print("TNT Athlete: save image called but profile image data is nil")
            success(nil)
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
        
        let filename = athleteMO.id! + ".png"
        
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
        uploadRequest!.key = "profiles/" + filename
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
                
                let remoteURL = URL(string: "https://s3.amazonaws.com/" + uploadRequest!.bucket! + "/profiles/" + filename)
                success(remoteURL)
            }
            return task
        }
        
    }
    
    


    func loadAllVideos() {
            
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.limit = 100
        
        dynamoDBObjectMapper.scan(tntVideo.self, expression: scanExpression).continueWith(block: { (task) -> Void in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else if let paginatedOutput:AWSDynamoDBPaginatedOutput = task.result {
                
                for video in paginatedOutput.items as! [tntVideo] {
                    
                    print("TNT: retrieved video \(video.cloudURL ?? "no URL")")
                    
                    let videoMO = Video(dbVideo: video)
                    videoMO.saveLocal()
                    
                    // send a notification indicating new video data
                    
                    let nc = NotificationCenter.default
                    nc.post(name: Notification.Name("tntVideoLoaded"), object: nil, userInfo: ["videoId" : videoMO.videoId!])
                }
                
            }
    
        })

        
    }
    
    func loadVideo(videoId: String) {
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.load(tntVideo.self, hashKey: videoId, rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
                return nil
                
            } else if let videoDB = task.result as? tntVideo {
                
                print("TNT: synch manager retrieved video for \(videoId)")
                
                let exists = tntLocalDataManager.shared.videos[videoId] != nil
                
                if !exists {
                    // Create a coredata video object
                    let videoMO = Video(dbVideo: videoDB)
                    videoMO.saveLocal()
                    
                } else {
                    print("TNT SynchManager: videoId already exists in CoreData, attempt to load duplicate ignored")
                }
                
            }
            return nil
        })
    }
    
    func queryVideo(videoId: String) {
        
        // queries Dynamo for a matching video but doesn't update CoreData cache
        // if found, sends a notification containing the DB object
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.load(tntVideo.self, hashKey: videoId, rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
                return nil
                
            } else if let videoDB = task.result as? tntVideo {
                
                print("TNT: synch manager queried video for \(videoId)")
                
                // send a notification including the returned DB object
                
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name("tntVideoQueried"), object: nil, userInfo: ["videoObject": videoDB])
                
            }
            return nil
        })
        
        
        
        
    }
    
    func loadMeets() {
        
        // load all relevant meets from the cloud DB into CoreData, if they are not there already
        // TODO: add filtering options, e.g. exclude meets from past seasons
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.limit = 100
        
        dynamoDBObjectMapper.scan(tntMeet.self, expression: scanExpression).continueWith(block: { (task) -> Void in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else if let paginatedOutput = task.result as AWSDynamoDBPaginatedOutput? {
                
                for meet in paginatedOutput.items as! [tntMeet] {
                    
                    print("TNT: retrieved meet \(meet.meetTitle ?? "no URL")")
                    
                    if tntLocalDataManager.shared.meets[meet.meetId!] == nil {
                        // not in coredata cache, so ok to add a new MO
                        
                        let meetMO = Meet(dbMeet: meet)
                        meetMO.saveLocal()  // needs exception handling?
                    }
                }
                
                // send a notification indicating new meet data
                
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name("tntMeetLoaded"), object: nil, userInfo: nil)
                
            }
        })
        
    }
    
    func loadScores(athleteId: String, meetId: String) {
        
        
        // load score data from cloud DB to core data
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let scoreId = athleteId + ":" + meetId
        
        dynamoDBObjectMapper.load(tntScores.self, hashKey: scoreId, rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
                return nil
                
            } else if let scores = task.result as? tntScores {
                
                print("TNT: retrieved scores for" + scores.scoreId!)
                
                // create a managed object and store it
                
                let moScores = Scores(dbScores: scores)
                moScores.saveLocal()
                return nil
                
            }
            // send a notification indicating that a scores object was not found (a normal situation - the VC will create one in response)
            
            let nc = NotificationCenter.default
            nc.post(name: Notification.Name("tntScoresNotFound"), object: nil, userInfo: ["scoreId":scoreId])
            
            return nil
        })

    }
    
    func loadTeamScores(teamScoreIds: [String]) -> AWSTask<tntTeamScores> {
    
        // For a given list of score Ids (all relevant athletes and meets), query Dyanamo
        // Return a task which completes when all queries are done, returning the scores in an array (tntTeamScores)
        
        let taskCompletion = AWSTaskCompletionSource<tntTeamScores>()
        var subTasks: [AWSTask<AnyObject>] = []
        var dbObjects: [tntScores] = []
        let updateQueue = DispatchQueue(label: "tasks.exclusive")  // serial queue to ensure exclusive access during array updates
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        for scoreId in teamScoreIds {
            
            let loadTask = dynamoDBObjectMapper.load(tntScores.self, hashKey: scoreId, rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
                    if let error = task.error as NSError? {
                        print("TNT Team Scores: Error loading \(scoreId). Error: \(error)")
                    } else if let dbScores = task.result as? tntScores {
                        print("TNT Team Scores: retrieved scores for " + scoreId)
                        updateQueue.sync { dbObjects.append(dbScores) }  // append in a thread-safe way
                    }
                    print("TNT Team Scores: retrieved no score DB object with id \(scoreId)")
                    return nil
                })
            subTasks.append(loadTask)
        }
        
        let whenAllTask = AWSTask(forCompletionOfAllTasks: subTasks).continueWith(block: { (task:AWSTask<AnyObject>) -> AWSTask<AnyObject>? in
            if let error = task.error as NSError? {
                taskCompletion.set(error: error)
            } else {
                let result = tntTeamScores()
                result.teamScores = dbObjects
                taskCompletion.set(result: result)
            }
            return nil
        })
        
        return taskCompletion.task
    }
    
    func saveScores(_ scoreId: String) {
        
        if let scoresMO = tntLocalDataManager.shared.scores[scoreId] {
        
            let scoresDB = tntScores(scoresMO: scoresMO)
        
            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
            
            dynamoDBObjectMapper.save(scoresDB).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
                if let error = task.error as NSError? {
                    print("TNT synch manager, failed saving scores object. Error: \(error)")
                    return nil
                } else {
                    print("TNT synch manager saved scores item")
                    scoresMO.clearCloudSavePending()
                    return nil
                }
            })
        }

    }
    

    
    func createVideo(s3VideoKey: String, thumbKey: String, pha: PHAsset) {
        
        
        guard let newVideo = tntVideo() else {
            print("Could not create TNT video")
            return
        }
        
        newVideo.cloudURL = s3VideoKey
        newVideo.localIdentifier  = "NIL"
        newVideo.videoId = s3VideoKey
        newVideo.thumbKey = thumbKey
        
        newVideo.setAssetMetadata(from: pha)
        newVideo.setPublishDate()
        
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()

        dynamoDBObjectMapper.save(newVideo).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
                return nil
            } else {
                print("TNT synch manager created video item")
                tntLocalDataManager.shared.loadNewVideo(video: newVideo)
                return nil
            }
        })
        
            }
    
    
    func tntPreSignedURL(unsignedURL: String) -> String {
                
                var preSignedURL : String? = nil
                let signingGroup = DispatchGroup()
                
                precondition(!Thread.isMainThread, "tntPreSignedURL : don't call this func from the main thread")
                
                let preSignedRequest = AWSS3GetPreSignedURLRequest()
                preSignedRequest.bucket = "ozzieozumo.tnt"
                
                // find the key (filename) starting after ozzieozumo.tnt/ if it is present otherwise start at beginning
        
                var keyStart: String.Index
                if let bucketRange = unsignedURL.range(of: preSignedRequest.bucket) {
                    keyStart = unsignedURL.index(bucketRange.upperBound, offsetBy: 1)
                } else {
                    keyStart = unsignedURL.startIndex
                }
        
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
                    
                    if let error = task.error as NSError? {
                        print("Error: \(error)")
                        signingGroup.leave()
                        return nil
                    }
                    
                    preSignedURL = task.result!.absoluteString
                    print("Download presignedURL is: \(String(describing: preSignedURL))")
                    signingGroup.leave()
                    return nil
                    
                }
                
                signingGroup.wait()
                return preSignedURL!
            }

    
    // Synchronization background task:  check for pending updates and retry
    
    func startRetryTask() {
    
        // should be called in background, not on main thread
        precondition(!Thread.isMainThread, "tntSynchManager : retryTask must not run on main thread")
        
        // check to see if task already started
        
        let queue = DispatchQueue(label: "cloudRetryQueue")
        let group = DispatchGroup()
        

        // start a polling loop looking for pending updates
        
        
        while true {
                // setup a group with a timer and the polling task
                // when both have finished, start again 
                
                group.enter()
                queue.async {
                    
                    print("TNT Synch Manager : Polling")
                    
                    // Execute code to look for pending items and initiate background updates
                    // (this code should be guaranteed to finish after a certain timeout)
                    
                    for pendingScore in tntLocalDataManager.shared.getPendingScoreUpdates() {
                        
                        // make a tntScores mapping object
                        
                        let scoresDB = tntScores(scoresMO: pendingScore)
                        
                        // use object mapper to attempt an update
                        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
                        
                        dynamoDBObjectMapper.save(scoresDB).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
                            if let error = task.error as NSError? {
                                print("TNT synch manager, failed saving scores object. Error: \(error)")
                                
                                // TODO:  analysis of error codes
                        
                                
                            } else {
                                print("TNT synch manager saved scores item to cloud DB")
                                
                                pendingScore.clearCloudSavePending()
                            }
                            return nil
                        })

                    }
                    group.leave()  // leave the group after polling and starting the save tasks (which will complete in background)
                }
                
                
                group.enter()
                queue.asyncAfter(deadline: .now() + .seconds(Constants.cloudDBRetryInterval)) {
                    
                    
                    print("TNT Synch Manager : Timer Done")
                    group.leave()
                }
                
                group.wait()
                print("TNT Synch Manager : Polling and Timer Done, Looping")
                
            }
        
    }
    
    func s3VideoUpload(url: URL, asset: PHAsset, scores: Scores? = nil) {
        
        let transferManager = AWSS3TransferManager.default()
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        
        uploadRequest!.bucket = "ozzieozumo.tnt"
        let videoUUID = UUID().uuidString.lowercased()
        let videoKey = "videos/" + videoUUID + ".mov"
        uploadRequest!.key = videoKey
        uploadRequest!.body = url
        
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
            }
            print("video upload success")
            
            // video and thumb upload can occur in parallel, but updating coredata and dynamo db should happen after both uploads
            
            self.uploadVideoThumbnail(forAsset: asset, partialKey: videoUUID) { (error, result) in
                if let thumbError = error {
                    return
                } else {
                    tntSynchManager.shared.createVideo(s3VideoKey: videoKey, thumbKey: result, pha: asset)
                    
                    // a scores object is provided when this is a new file upload and the new video
                    // should be added as a related video of athlete/meet
                    
                    if let scoresMO = scores {
                        
                        scoresMO.addVideo(relatedVideoId: videoKey)
                    }
                }
            }
            
            return nil
            
        }
        
    }
    
    func uploadVideoThumbnail(forAsset: PHAsset, partialKey: String, completion: @escaping (NSError?, String)->()) {
    
    // obtains a thumbnail sized image from PHImageManager, writes it to disk as a JPEG, uploads to S3
    // TODO: cconvert this to work like AWS functions, i.e. returning AWS task
    
        var thumbSize = CGSize()
        thumbSize.height = 60
        thumbSize.width = 60
        
        var imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isSynchronous = true
        var thumbImage: UIImage? = nil
        
        PHImageManager.default().requestImage(for: forAsset, targetSize: thumbSize, contentMode: .aspectFill, options: imageRequestOptions) { (result: UIImage?, info: [AnyHashable : Any]?) in
            if let img = result {
                print("TNT Synch Manager: retrieved non nil image via PHImageManager")
                thumbImage = img
            } else {
                // return an error
                let error = NSError(domain: "TNT", code: 0, userInfo: ["reason": "failed to retrieve thumbnail image from PHImageManager"])
                completion(error, "")
            }
        }
        
        // write the image to disk locally
        
        let fileName = partialKey + ".png"
        var fileURL: URL
        if let img = thumbImage {
            
            do {
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                fileURL = documentsURL.appendingPathComponent("\(fileName)")
                if let pngImageData = UIImagePNGRepresentation(img) {
                    try pngImageData.write(to: fileURL, options: .atomic)
                }
            } catch {
                // return an error
                let error = NSError(domain: "TNT", code: 0, userInfo: ["reason": "failed writing thumbnail image to local storage"])
                completion(error, "")            }
            
            // make an S3 request to upload the thumbnail image file
            
            let transferManager = AWSS3TransferManager.default()
            let uploadRequest = AWSS3TransferManagerUploadRequest()
            
            uploadRequest!.bucket = "ozzieozumo.tnt"
            let imageKey = "thumbs/" + fileName
            uploadRequest!.key = imageKey
            uploadRequest!.body = fileURL
            
            transferManager.upload(uploadRequest!).continueWith { (task) -> AnyObject! in
                if let error = task.error as NSError? {
                    print("TNT Synch Manager : failed uploading video thumbnail image \(imageKey)")
                    // return an error
                    let error = NSError(domain: "TNT", code: 0, userInfo: ["reason": "failed to upload thumb image to S3 via transfer manager"])
                    completion(error, "")
                } else {
                    print("TNT Synch Manager : uploaded video thumbnail image \(imageKey)")
                    completion(nil, imageKey)
                }
                return nil
            }
            
        }
    }
    
}
