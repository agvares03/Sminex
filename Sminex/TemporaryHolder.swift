//
//  TemporaryHolder.swift
//  Sminex
//
//  Created by IH0kN3m on 3/23/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import Foundation
import Gloss

final class TemporaryHolder {
    
    static let instance = TemporaryHolder()
    
    public var newsLastId = UserDefaults.standard.string(forKey: "newsLastId") ?? ""
    public var requestTypes:            RequestType?
    public var contacts:                Contacts?
    public var menuQuesions = 0 {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name("QuestionsMenu"), object: nil)
        }
    }
    public var menuRequests = 0 {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name("RequestsMenu"), object: nil)
        }
    }
    public var menuDeals    = 0 {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name("DealsMenu"), object: nil)
        }
    }
    public var news: [NewsJson]? {
        didSet {
            self.news = news?.filter {
                let df = DateFormatter()
                df.dateFormat = "dd.MM.yyyy hh:mm:ss"
                let date = df.date(from: $0.dateEnd ?? "") ?? Date()
                if date < Date() {
                    return false
                }
                return true
            }
        }
    }
    public var contactsList: [ContactsJson] = []
    
    func choise(_ responce: JSON) {
        
        requestTypes = RequestType(json: responce)
        contacts = Contacts(json: responce)
    }
    
    private init() { }
}

struct RequestType: JSONDecodable {
    
    let types: [RequestTypeStruct]?
    
    init?(json: JSON) {
        types = "requestTypes" <~~ json
    }
}

struct RequestTypeStruct: JSONDecodable {
    
    let id:     String?
    let name:   String?
    
    init?(json: JSON) {
        
        id      = "ID"      <~~ json
        name    = "Name"    <~~ json
    }
    
    init(id: String, name: String) {
        self.id     = id
        self.name   = name
    }
}

struct Contacts: JSONDecodable {
    
    let contacts: [String]?
    
    init?(json: JSON) {
        
        contacts = "contacts" <~~ json
    }
}





