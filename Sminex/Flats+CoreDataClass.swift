//
//  Flats+CoreDataClass.swift
//  
//
//  Created by Роман Тузин on 06.06.17.
//
//

import Foundation
import CoreData

@objc(Flats)
public class Flats: NSManagedObject {

    convenience init() {
        
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "Flats"), insertInto: CoreDataManager.instance.managedObjectContext)
        
    }
    
}
