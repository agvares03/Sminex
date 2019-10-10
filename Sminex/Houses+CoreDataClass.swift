//
//  Houses+CoreDataClass.swift
//  
//
//  Created by Роман Тузин on 06.06.17.
//
//

import Foundation
import CoreData

@objc(Houses)
public class Houses: NSManagedObject {

    convenience init() {
        
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "Houses"), insertInto: CoreDataManager.instance.managedObjectContext)
        
    }
    
}
