//
//  TypesCounters+CoreDataClass.swift
//  Sminex
//
//  Created by Роман Тузин on 01/08/2019.
//
//

import Foundation
import CoreData

@objc(TypesCounters)
public class TypesCounters: NSManagedObject {
    convenience init() {
        
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "TypesCounters"), insertInto: CoreDataManager.instance.managedObjectContext)
        
    }
}
