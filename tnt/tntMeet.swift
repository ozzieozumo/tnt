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
    
    convenience init(meetMO : NSManagedObject) {
        
        self.init()
        
        // Assumes that a valid scores MO has been received
        
        meetId = meetMO.value(forKey: "meetId") as! String?
        meetCity = meetMO.value(forKey: "meetStartDate") as! String?
        meetStartDate = meetMO.value(forKey: "meetStartDate") as! String?    // need date conversion?
        meetEndDate = meetMO.value(forKey: "meetEndDate") as! String?
        meetVenue = meetMO.value(forKey: "meetVenue") as! String?
        meetLevels = meetMO.value(forKey: "meetLevels") as! [Int]?
        meetEvents = meetMO.value(forKey: "meetEvents") as! [String]?
        meetTitle = meetMO.value(forKey: "meetTitle") as! String?
        meetSubTitle = meetMO.value(forKey: "meetSubTitle") as! String?
    
    }

}
