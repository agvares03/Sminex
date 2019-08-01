//
//  Notifications+CoreDataProperties.swift
//  
//
//  Created by Sergey Ivanov on 01/08/2019.
//
//

import Foundation
import CoreData


extension Notifications {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Notifications> {
        return NSFetchRequest<Notifications>(entityName: "Notifications")
    }

    @NSManaged public var id: Int64
    @NSManaged public var name: String?
    @NSManaged public var type: String?
    @NSManaged public var date: String?
    @NSManaged public var isReaded: Bool

}
