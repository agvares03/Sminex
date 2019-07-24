//
//  Appeals+CoreDataProperties.swift
//  
//
//  Created by Sergey Ivanov on 22/07/2019.
//
//

import Foundation
import CoreData


extension Appeals {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Appeals> {
        return NSFetchRequest<Appeals>(entityName: "Appeals")
    }

    @NSManaged public var adress: String?
    @NSManaged public var customer_id: String?
    @NSManaged public var date: String?
    @NSManaged public var flat: String?
    @NSManaged public var id: Int64
    @NSManaged public var is_answered: Int64
    @NSManaged public var is_close: Int64
    @NSManaged public var is_paid: String?
    @NSManaged public var is_read: Int64
    @NSManaged public var number: String?
    @NSManaged public var owner: String?
    @NSManaged public var phone: String?
    @NSManaged public var tema: String?
    @NSManaged public var text: String?

}
