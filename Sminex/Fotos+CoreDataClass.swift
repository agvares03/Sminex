//
//  Fotos+CoreDataClass.swift
//  
//
//  Created by Роман Тузин on 06.06.17.
//
//

import Foundation
import CoreData


public class Fotos: NSManagedObject {
    
    convenience init() {
        
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "Fotos"), insertInto: CoreDataManager.instance.managedObjectContext)
        
    }
    
}
