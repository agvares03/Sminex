//
//  Comments+CoreDataProperties.swift
//  
//
//  Created by Роман Тузин on 05.06.17.
//
//  This file was automatically generated and should not be edited.
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
