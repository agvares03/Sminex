//
//  TypesCounters+CoreDataClass.swift
//  
//
//  Created by Sergey Ivanov on 01/08/2019.
//
//

import Foundation
import CoreData


public class TypesCounters: NSManagedObject {
    convenience init() {
        
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "TypesCounters"), insertInto: CoreDataManager.instance.managedObjectContext)
        
    }
}
