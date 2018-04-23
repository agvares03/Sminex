//
//  ContactsJson.swift
//  Sminex
//
//  Created by IH0kN3m on 4/23/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss

final class ContactsDataJson: JSONDecodable {
    
    let data: [ContactsJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

final class ContactsJson: JSONDecodable {
    
    let name: String?
    let description: String?
    let phone: String?
    let email: String?
    
    init?(json: JSON) {
        description = "Description" <~~ json
        phone       = "Phone"       <~~ json
        email       = "Email"       <~~ json
        name        = "Name"        <~~ json
    }
}
