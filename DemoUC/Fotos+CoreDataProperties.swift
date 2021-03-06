//
//  Fotos+CoreDataProperties.swift
//  
//
//  Created by Роман Тузин on 06.06.17.
//
//

import Foundation
import CoreData


extension Fotos {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Fotos> {
        return NSFetchRequest<Fotos>(entityName: "Fotos")
    }

    @NSManaged public var date: String?
    @NSManaged public var foto_path: String?
    @NSManaged public var foto_small: NSData?
    @NSManaged public var id: Int64
    @NSManaged public var name: String?
    @NSManaged public var number: String?

}
