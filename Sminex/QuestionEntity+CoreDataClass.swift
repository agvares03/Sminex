//
//  QuestionEntity+CoreDataClass.swift
//  Sminex
//
//  Created by IH0kN3m on 4/2/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import Foundation
import CoreData


public class QuestionEntity: NSManagedObject {
    
    convenience init() {
        
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "QuestionEntity"), insertInto: CoreDataManager.instance.managedObjectContext)        
    }
}

