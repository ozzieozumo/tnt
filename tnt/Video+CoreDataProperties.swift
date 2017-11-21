//
//  Video+CoreDataProperties.swift
//  tnt
//
//  Created by Luke Everett on 11/20/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//
//

import Foundation
import CoreData


extension Video {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Video> {
        return NSFetchRequest<Video>(entityName: "Video")
    }

    @NSManaged public var captureDate: NSDate?
    @NSManaged public var cloudURL: String?
    @NSManaged public var duration: Double
    @NSManaged public var localIdentifier: String?
    @NSManaged public var notes: String?
    @NSManaged public var publishDate: NSDate?
    @NSManaged public var thumbImage: NSData?
    @NSManaged public var thumbKey: String?
    @NSManaged public var title: String?
    @NSManaged public var videoId: String?

}
