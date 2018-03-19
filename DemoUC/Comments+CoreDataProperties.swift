//
//  Comments+CoreDataProperties.swift
//  
//
//  Created by Роман Тузин on 06.06.17.
//
//

import Foundation
import CoreData


extension Comments {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Comments> {
        return NSFetchRequest<Comments>(entityName: "Comments")
    }

    @NSManaged public var author: String?
    @NSManaged public var date: String?
    @NSManaged public var id: Int64
    @NSManaged public var id_account: String?
    @NSManaged public var id_app: Int64
    @NSManaged public var id_author: String?
    @NSManaged public var text: String?

}
