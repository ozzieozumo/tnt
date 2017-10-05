//
//  tntVideo.swift
//  tnt
//
//  Created by Luke Everett on 6/8/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation


import AWSDynamoDB

class tntVideo : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var videoId: String?
    var cloudURL:  String?              // AWS S3 path
    var thumbKey: String?               // AWS S3 key for thumbnail image
    var localIdentifier: String?        // PH Asset/Object identitifier
    
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
        
    }

}
