//
//  tntVideo.swift
//  tnt
//
//  Created by Luke Everett on 6/8/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation
import Photos


import AWSDynamoDB

class tntVideo : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var videoId: String?
    var cloudURL:  String?              // AWS S3 path
    var thumbKey: String?               // AWS S3 key for thumbnail image
    var localIdentifier: String?        // PH Asset/Object identitifier
    var publishDate: String?            // yyyy-MM-dd
    var captureDate: String?            // yyyy-MM-dd
    var duration: Double?               // duration in seconds
    
    class func dynamoDBTableName() -> String {
        return "tntVideo"
    }
    
    class func hashKeyAttribute() -> String {
        return "videoId"
    }
    
    convenience init(videoMO : Video) {
        
        self.init()
        
                
        videoId = videoMO.videoId
        cloudURL = videoMO.cloudURL
        localIdentifier = videoMO.localIdentifier
        thumbKey = videoMO.thumbKey
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let captureDate = videoMO.captureDate {
            self.captureDate = dateFormatter.string(from: captureDate as Date)
        }
        
        if let publishDate = videoMO.publishDate {
            self.publishDate = dateFormatter.string(from: publishDate as Date)
        }
        
        duration = videoMO.duration
    }
    
    
    public func setAssetMetadata(from: PHAsset) {
        
        // set the capture date and duration from the PHAsset metadata
        
        duration = from.duration as Double
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let captureDate = from.creationDate {
            self.captureDate = dateFormatter.string(from: captureDate as Date)
        }
        
    }
    
    public func setPublishDate() {
        
        // sets the publish date to today in yyyy-MM-dd format
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        publishDate = dateFormatter.string(from: Date())
        
    }

}
