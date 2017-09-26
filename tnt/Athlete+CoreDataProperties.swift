//
//  Athlete+CoreDataProperties.swift
//  tnt
//
//  Created by Luke Everett on 9/26/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import Foundation
import CoreData


extension Athlete {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Athlete> {
        return NSFetchRequest<Athlete>(entityName: "Athlete")
    }

    @NSManaged public var dob: NSDate?
    @NSManaged public var eventLevels: NSObject?
    @NSManaged public var firstName: String?
    @NSManaged public var id: String?
    @NSManaged public var lastName: String?
    @NSManaged public var profileImage: NSData?
    @NSManaged public var recoveryKey: String?
    @NSManaged public var registered: Meet?

}
