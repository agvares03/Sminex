//
//  RequestEntity+CoreDataProperties.swift
//  Sminex
//
//  Created by IH0kN3m on 3/27/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import Foundation
import CoreData

extension RequestEntity {
   
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RequestEntity> {
        return NSFetchRequest<RequestEntity>(entityName: "RequestEntity")
    }
    
    @NSManaged var date: 	String?
    @NSManaged var desc:    String?
    @NSManaged var icon:    Data?
    @NSManaged var isBack:  Bool
    @NSManaged var status:  String?
    @NSManaged var title:   String?
    
}
