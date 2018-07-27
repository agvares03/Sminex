//
//  BusinessCenterData.swift
//  Sminex
//
//  Created by Anton Barbyshev on 27.07.2018.
//  Copyright © 2018 Anton Barbyshev. All rights reserved.
//

import Foundation
import Gloss

// Объект для парса json-данных по БЦ
struct Business_Center_Data: JSONDecodable {
    
    let DenyOnlinePayments: Bool?
    let DenyInvoiceFiles: Bool?
    let DenyTotalOnlinePayments: Bool?
    
    let DenyQRCode: Bool?
    
    let DenyIssuanceOfPassSingle: Bool?
    let DenyIssuanceOfPassSingleWithAuto: Bool?
    
    init?(json: JSON) {
        DenyOnlinePayments                = "denyOnlinePayments"                  <~~ json
        DenyInvoiceFiles                  = "denyInvoiceFiles"                    <~~ json
        DenyTotalOnlinePayments           = "denyTotalOnlinePayments"             <~~ json
        
        DenyQRCode                        = "denyQRCode"                          <~~ json
        
        DenyIssuanceOfPassSingle          = "denyIssuanceOfPassSingle"            <~~ json
        DenyIssuanceOfPassSingleWithAuto  = "denyIssuanceOfPassSingleWithAuto"    <~~ json
    }
}
