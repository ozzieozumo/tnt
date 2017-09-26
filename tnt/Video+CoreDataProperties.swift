//
//  Video+CoreDataProperties.swift
//  tnt
//
//  Created by Luke Everett on 9/26/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import Foundation
import CoreData


extension Video {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Video> {
        return NSFetchRequest<Video>(entityName: "Video")
    }

    @NSManaged public var cloudURL: String?
    @NSManaged public var localIdentifier: String?
    @NSManaged public var publishDate: NSDate?
    @NSManaged public var videoId: String?

}
