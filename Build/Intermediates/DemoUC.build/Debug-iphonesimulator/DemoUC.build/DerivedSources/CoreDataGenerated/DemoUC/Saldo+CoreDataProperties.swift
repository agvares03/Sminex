//
//  Saldo+CoreDataProperties.swift
//  
//
//  Created by Роман Тузин on 04.06.17.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Saldo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Saldo> {
        return NSFetchRequest<Saldo>(entityName: "Saldo")
    }

    @NSManaged public var id: Int64
    @NSManaged public var num_month: String?
    @NSManaged public var usluga: String?
    @NSManaged public var year: String?

}
