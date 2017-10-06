//
//  Video+TNT.swift
//  tnt
//
//  Created by Luke Everett on 9/26/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import Foundation
import CoreData

extension Video {
    
    convenience init(dbVideo: tntVideo) {
        
        self.init(context: tntLocalDataManager.shared.moc!)
        
        self.cloudURL = dbVideo.cloudURL
        self.localIdentifier = dbVideo.localIdentifier
        self.videoId = dbVideo.videoId
        self.thumbKey = dbVideo.thumbKey
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let publishDate = dbVideo.publishDate {
            self.publishDate = dateFormatter.date(from: publishDate) as NSDate?
        }
        
        if let captureDate = dbVideo.captureDate {
            self.captureDate = dateFormatter.date(from: captureDate) as NSDate?
        }
        
        self.duration = dbVideo.duration ?? 0.0

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
    

    func loadThumbImage(imageURL: String?) {
        
        precondition(!Thread.isMainThread, "tnt load thumbImage : don't call this func from the main thread")

    
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
                print("TNT: error downloading video thumb image: \(error!)")
            } else {
                if let imgData = data {
                    self.thumbImage = imgData as NSData?
                    
                    do {
                        self.saveLocal()
                        print("TNT: thumbnail image for video downloaded and set in coredata")
                        
                        let nc = NotificationCenter.default
                        nc.post(name: Notification.Name("tntVideoThumbnailLoaded"), object: nil, userInfo: ["videoId":self.videoId!])
                        
                        
                    } catch let error as NSError {
                        print("TNT: could not save video thumb image. \(error), \(error.userInfo)")
                    }
                    
                } else {
                    print("TNT: image download succeeded but data was nil")
                }
            }
            
        }
        
        downloadTask.resume()
    }

        
}

