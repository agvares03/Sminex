//
//  Ls+CoreDataProperties.swift
//  
//
//  Created by Роман Тузин on 06.06.17.
//
//

import Foundation
import CoreData


extension Ls {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Ls> {
        return NSFetchRequest<Ls>(entityName: "Ls")
    }

    @NSManaged public var fio:      String?
    @NSManaged public var id:       Int64
    @NSManaged public var id_flat:  Int64
    @NSManaged public var name:     String?

}
