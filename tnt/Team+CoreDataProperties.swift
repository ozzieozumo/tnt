//
//  Team+CoreDataProperties.swift
//  tnt
//
//  Created by Luke Everett on 11/30/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//
//

import Foundation
import CoreData


extension Team {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Team> {
        return NSFetchRequest<Team>(entityName: "Team")
    }

    @NSManaged public var name: String?
    @NSManaged public var teamId: String?
    @NSManaged public var athleteIds: NSObject?
    @NSManaged public var secret: String?
    @NSManaged public var userIds: NSObject?

}
