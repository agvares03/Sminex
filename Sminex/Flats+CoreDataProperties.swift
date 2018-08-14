//
//  Flats+CoreDataProperties.swift
//  
//
//  Created by Роман Тузин on 06.06.17.
//
//

import Foundation
import CoreData


extension Flats {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Flats> {
        return NSFetchRequest<Flats>(entityName: "Flats")
    }

    @NSManaged public var id:       Int64
    @NSManaged public var id_house: Int64
    @NSManaged public var name:     String?

}
