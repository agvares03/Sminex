//
//  TypesCounters+CoreDataProperties.swift
//  Sminex
//
//  Created by Роман Тузин on 01/08/2019.
//
//

import Foundation
import CoreData


extension TypesCounters {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TypesCounters> {
        return NSFetchRequest<TypesCounters>(entityName: "TypesCounters")
    }

    @NSManaged public var name: String?

}
