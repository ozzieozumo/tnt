//
//  Athlete+CoreDataProperties.swift
//  tnt
//
//  Created by Luke Everett on 8/16/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation
import CoreData


extension Athlete {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Athlete> {
        return NSFetchRequest<Athlete>(entityName: "Athlete")
    }

    @NSManaged public var eventLevels: NSObject?
    @NSManaged public var firstName: String?
    @NSManaged public var id: String?
    @NSManaged public var lastName: String?
    @NSManaged public var profileImage: NSData?
    @NSManaged public var registered: Meet?
    
    
}
