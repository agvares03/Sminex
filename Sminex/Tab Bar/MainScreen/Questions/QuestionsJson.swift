//
//  QuestionsJson.swift
//  Sminex
//
//  Created by IH0kN3m on 3/31/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import Foundation
import Gloss

struct QuestionsJson: JSONDecodable {
    
    let data: [QuestionDataJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
    
}

struct QuestionDataJson: JSONDecodable {
    
    let questions:  [QuestionJson]?
    let name:       String?
    let id:         Int?
    let dateStart:  String?
    let dateStop:   String?
    let isReaded:   Bool?
    
    init?(json: JSON) {
        questions   = "Questions"   <~~ json
        name        = "Name"        <~~ json
        id          = "ID"          <~~ json
        dateStart   = "DateStart"   <~~ json
        dateStop    = "DateStop"    <~~ json
        isReaded    = "IsReaded"    <~~ json
    }
}

struct QuestionJson: JSONDecodable {
    
    let answers:                [QuestionsTextJson]?
    let question:               String?
    let isCompleteByUser:       Bool?
    let isAcceptSomeAnswers:    Bool?
    let id:                     Int?
    let groupId:                Int?
    
    init?(json: JSON) {
        
        isAcceptSomeAnswers = "IsAcceptSomeAnswers" <~~ json
        isCompleteByUser    = "IsCompleteByUser"    <~~ json
        question            = "Question"            <~~ json
        groupId             = "GroupID"             <~~ json
        answers             = "Answers"             <~~ json
        id                  = "ID"                  <~~ json
    }
}

struct QuestionsTextJson: JSONDecodable {
    
    let comment:        String?
    let text:           String?
    let isUserAnswer:   Bool?
    let id:             Int?
    
    init?(json: JSON) {
        
        isUserAnswer = "IsUserAnswer"   <~~ json
        comment      = "Comment"        <~~ json
        text         = "Text"           <~~ json
        id           = "ID"             <~~ json
    }
}




