//
//  Scores+CoreDataProperties.swift
//  tnt
//
//  Created by Luke Everett on 8/16/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation
import CoreData


extension Scores {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Scores> {
        return NSFetchRequest<Scores>(entityName: "Scores")
    }

    @NSManaged public var athleteId: String?
    @NSManaged public var cloudSaveDate: NSDate?
    @NSManaged public var cloudSavePending: Bool
    @NSManaged public var events: NSObject?
    @NSManaged public var meetId: String?
    @NSManaged public var scoreId: String?
    @NSManaged public var scores: NSObject?
    @NSManaged public var videos: NSObject?
    @NSManaged public var timeStamp: NSDate?

}
