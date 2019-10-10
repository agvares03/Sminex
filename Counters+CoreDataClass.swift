//
//  Counters+CoreDataClass.swift
//  DemoUC
//
//  Created by Роман Тузин on 27.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import Foundation
import CoreData

@objc(Counters)
public class Counters: NSManagedObject {

    convenience init() {
        
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "Counters"), insertInto: CoreDataManager.instance.managedObjectContext)
        
    }
    
}
