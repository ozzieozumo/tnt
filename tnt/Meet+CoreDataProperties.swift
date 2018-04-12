//
//  Meet+CoreDataProperties.swift
//  tnt
//
//  Created by Luke Everett on 4/12/18.
//  Copyright © 2018 ozzieozumo. All rights reserved.
//
//

import Foundation
import CoreData


extension Meet {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Meet> {
        return NSFetchRequest<Meet>(entityName: "Meet")
    }

    @NSManaged public var city: String?
    @NSManaged public var endDate: NSDate?
    @NSManaged public var events: NSObject?
    @NSManaged public var id: String?
    @NSManaged public var maxLevel: Int16
    @NSManaged public var minLevel: Int16
    @NSManaged public var sharedStatus: Bool
    @NSManaged public var sharedTeam: String?
    @NSManaged public var startDate: NSDate?
    @NSManaged public var subTitle: String?
    @NSManaged public var title: String?
    @NSManaged public var venue: String?
    @NSManaged public var shareduser: String?
    @NSManaged public var registered: Athlete?

}
