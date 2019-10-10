//
//  Comments+CoreDataClass.swift
//  
//
//  Created by Роман Тузин on 06.06.17.
//
//

import Foundation
import CoreData

@objc(Comments)
public class Comments: NSManagedObject {
    
    convenience init() {
        
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "Comments"), insertInto: CoreDataManager.instance.managedObjectContext)
        
    }

}
