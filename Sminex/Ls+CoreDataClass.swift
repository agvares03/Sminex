//
//  Ls+CoreDataClass.swift
//  
//
//  Created by Роман Тузин on 06.06.17.
//
//

import Foundation
import CoreData


public class Ls: NSManagedObject {

    convenience init() {
        
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "Ls"), insertInto: CoreDataManager.instance.managedObjectContext)
        
    }
    
}
