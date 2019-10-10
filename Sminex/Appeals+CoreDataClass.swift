//
//  Appeals+CoreDataClass.swift
//  
//
//  Created by Sergey Ivanov on 22/07/2019.
//
//

import Foundation
import CoreData

@objc(Appeals)
public class Appeals: NSManagedObject {

    convenience init() {
        
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "Appeals"), insertInto: CoreDataManager.instance.managedObjectContext)
        
    }
}
