//
//  Houses+CoreDataProperties.swift
//  
//
//  Created by Роман Тузин on 05.06.17.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Houses {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Houses> {
        return NSFetchRequest<Houses>(entityName: "Houses")
    }

    @NSManaged public var fias: String?
    @NSManaged public var id: Int64
    @NSManaged public var name: String?

}
