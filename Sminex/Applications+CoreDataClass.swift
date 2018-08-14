//
//  Applications+CoreDataClass.swift
//  
//
//  Created by Роман Тузин on 06.06.17.
//
//

import Foundation
import CoreData


public class Applications: NSManagedObject {

    convenience init() {
        
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "Applications"), insertInto: CoreDataManager.instance.managedObjectContext)
        
    }
    
}
