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
    let DenyManagementCompanyServices: Bool?
    
    let DenyQRCode: Bool?
    
    let DenyIssuanceOfPassSingle: Bool?
    let DenyIssuanceOfPassSingleWithAuto: Bool?
    
    let OnlyViewMeterReadings: Bool?
    
    let DayFrom: Int?
    let DayTo: Int?
    
    let DenyImportExportProperty: Bool?
    let DenyShowFine: Bool?
    
    let ParkingPlace: [String]?
    
    init?(json: JSON) {
        DenyOnlinePayments                = "denyOnlinePayments"                  <~~ json
        DenyInvoiceFiles                  = "denyInvoiceFiles"                    <~~ json
        DenyTotalOnlinePayments           = "denyTotalOnlinePayments"             <~~ json
        DenyManagementCompanyServices     = "denyManagementCompanyServices"       <~~ json
        
        DenyQRCode                        = "denyQRCode"                          <~~ json
        
        DenyIssuanceOfPassSingle          = "denyIssuanceOfPassSingle"            <~~ json
        DenyIssuanceOfPassSingleWithAuto  = "denyIssuanceOfPassSingleWithAuto"    <~~ json
        
        OnlyViewMeterReadings             = "onlyViewMeterReadings"               <~~ json
        
        DayFrom                           = "meterReadingsDayFrom"                <~~ json
        DayTo                             = "meterReadingsDayTo"                  <~~ json
        DenyImportExportProperty          = "denyImportExportPropertyRequest"     <~~ json
        DenyShowFine                      = "denyShowFine"                        <~~ json
        ParkingPlace                      = "premises"                            <~~ json
    }
}
