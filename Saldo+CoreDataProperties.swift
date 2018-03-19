//
//  Saldo+CoreDataProperties.swift
//  DemoUC
//
//  Created by Роман Тузин on 04.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import Foundation
import CoreData


extension Saldo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Saldo> {
        return NSFetchRequest<Saldo>(entityName: "Saldo")
    }

    @NSManaged public var id: Int64
    @NSManaged public var usluga: String?
    @NSManaged public var num_month: String?
    @NSManaged public var year: String?
    @NSManaged public var start: String?
    @NSManaged public var plus: String?
    @NSManaged public var minus: String?
    @NSManaged public var end: String?

}
