//
//  tntMeet.swift
//  tnt
//
//  Created by Luke Everett on 7/13/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//


import Foundation

import AWSDynamoDB

class tntMeet : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var meetId: String?
    var meetCity:  String?
    var meetStartDate: String?
    var meetEndDate: String?
    var meetVenue: String?
    var meetLevels: [Int]?
    var meetEvents: [String]?
    var meetTitle: String?
    var meetSubTitle: String?

    
    class func dynamoDBTableName() -> String {
        return "tntMeet"
    }
    
    class func hashKeyAttribute() -> String {
        return "meetId"
    }
    
    convenience init(meetMO : Meet) {
        
        self.init()
        
        meetId = meetMO.id
        meetCity = meetMO.city
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        meetStartDate = dateFormatter.string(from: meetMO.startDate! as Date)
        meetEndDate = dateFormatter.string(from: meetMO.endDate! as Date)
        meetVenue = meetMO.venue
        
        //convert min/max levels to array of levels
        
        var levels: [Int] = []
        for level in meetMO.minLevel ... meetMO.maxLevel {
                levels.append(Int(level))
        }
            
        meetLevels = levels
        meetEvents = meetMO.events as! [String]?
        meetTitle = meetMO.title
        meetSubTitle = meetMO.subTitle
    
    }

}
