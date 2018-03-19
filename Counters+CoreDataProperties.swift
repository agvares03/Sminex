//
//  Counters+CoreDataProperties.swift
//  DemoUC
//
//  Created by Роман Тузин on 27.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import Foundation
import CoreData


extension Counters {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Counters> {
        return NSFetchRequest<Counters>(entityName: "Counters")
    }

    @NSManaged public var count_ed_izm: String?
    @NSManaged public var count_name: String?
    @NSManaged public var diff: Float
    @NSManaged public var id: Int64
    @NSManaged public var num_month: String?
    @NSManaged public var owner: String?
    @NSManaged public var prev_value: Float
    @NSManaged public var uniq_num: String?
    @NSManaged public var value: Float
    @NSManaged public var year: String?

}
