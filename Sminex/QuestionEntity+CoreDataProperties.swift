//
//  QuestionEntity+CoreDataProperties.swift
//  Sminex
//
//  Created by IH0kN3m on 4/2/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import Foundation
import CoreData

extension QuestionEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuestionEntity> {
        return NSFetchRequest<QuestionEntity>(entityName: "QuestionEntity")
    }
    
    @NSManaged var answerId:    [Int]?
    @NSManaged var id:          String?
    @NSManaged var questionId:  [Int]?
}
