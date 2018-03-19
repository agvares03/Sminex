//
//  Saldo+CoreDataClass.swift
//  DemoUC
//
//  Created by Роман Тузин on 04.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import Foundation
import CoreData


public class Saldo: NSManagedObject {

    convenience init() {
        
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "Saldo"), insertInto: CoreDataManager.instance.managedObjectContext)
        
    }
    
}
