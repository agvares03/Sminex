//
//  RequestEntity+CoreDataClass.swift
//  Sminex
//
//  Created by IH0kN3m on 3/27/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import Foundation
import CoreData

public class RequestEntity: NSManagedObject {
    
    convenience init() {
        
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "RequestEntity"), insertInto: CoreDataManager.instance.managedObjectContext)
        
    }
    
}
