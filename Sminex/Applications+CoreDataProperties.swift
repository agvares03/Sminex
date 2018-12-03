//
//  Applications+CoreDataProperties.swift
//  
//
//  Created by Роман Тузин on 06.06.17.
//
//

import Foundation
import CoreData


extension Applications {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Applications> {
        return NSFetchRequest<Applications>(entityName: "Applications")
    }

    @NSManaged public var adress:       String?
    @NSManaged public var customer_id:  String?
    @NSManaged public var date:         String?
    @NSManaged public var flat:         String?
    @NSManaged public var id:           Int64
    @NSManaged public var is_answered:  Int64
    @NSManaged public var is_close:     Int64
    @NSManaged public var is_read:      Int64
    @NSManaged public var number:       String?
    @NSManaged public var owner: 	    String?
    @NSManaged public var phone:        String?
    @NSManaged public var tema:         String?
    @NSManaged public var text: 	    String?
    @NSManaged public var is_paid:         String?

}
