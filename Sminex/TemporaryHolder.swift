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
    
    public let SaltQueue = DispatchGroup()
    public let bcQueue   = DispatchGroup()
    public let receiptsGroup = DispatchGroup()
    public let calcsGroup = DispatchGroup()
    public var salt: Data?
    public var bcImage: UIImage? {
        didSet {
            if bcImage != nil {
                UserDefaults.standard.setValue(UIImagePNGRepresentation(bcImage!), forKey: "BCImage")
            }
        }
    }
    public var newsLastId = UserDefaults.standard.string(forKey: "newsLastId") ?? ""
    public var requestTypes:            RequestType?
    public var worker: ServiceWorkerCellData?
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
    public var menuNotifications    = 0 {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name("NotificationsMenu"), object: nil)
        }
    }
    public var news: [NewsJson]? = [] {
        didSet {
            self.news = news?.filter {
                let df = DateFormatter()
                df.dateFormat = "dd.MM.yyyy hh:mm:ss"
                let date = df.date(from: $0.dateEnd ?? "") ?? Date()
                print(date)
                if date < Date() {
                    return false
                }
                return true
            }
            if news != nil {
                let newNews = self.news?.filter { (n) in self.news?.filter{ $0.header==n.header || $0.created==n.created }.count == 1 }
                self.news = newNews
            }
        }
    }
    public var oldDeals: [DealsJson] = []
    public var newsNew: [NewsJson]? = []
    public var contactsList: [ContactsJson] = []
    public var allLS: [AllLsData] = []
    
    public var receipts:      [AccountBillsJson]        = []
    public var calcs:         [AccountCalculationsJson] = []
    public var filteredCalcs: [AccountCalculationsJson] = []
    
    public func choise(_ responce: JSON) {
        
        requestTypes = RequestType(json: responce)
        contacts = Contacts(json: responce)
    }
    
    public func getFinance() {
        getBills()
        getCalculations()
    }
    
    private func getBills() {
        let defaults = UserDefaults.standard
        if (defaults.bool(forKey: "denyInvoiceFiles")) {
            
        } else {
            let login = UserDefaults.standard.string(forKey: "login") ?? ""
            let pwd = UserDefaults.standard.string(forKey: "pwd") ?? ""
            
            let url = Server.SERVER + Server.GET_BILLS + "login=" + (login.stringByAddingPercentEncodingForRFC3986() ?? "")
            var request = URLRequest(url: URL(string: url + "&pwd=" + pwd)!)
            request.httpMethod = "GET"
            
            print(request)
            
            receiptsGroup.enter()
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                defer {
                    self.receiptsGroup.leave()
                }
                guard data != nil else { return }
                
//                #if DEBUG
//                print(String(data: data!, encoding: .utf8) ?? "")
//                
//                #endif
                self.receipts.removeAll()
                if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                    self.receipts = AccountBillsData(json: json!)!.data ?? []
                }
                
                }.resume()
        }
        
    }
    
    private func getCalculations() {
        self.calcs.removeAll()
        self.filteredCalcs.removeAll()
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = UserDefaults.standard.string(forKey: "pwd") ?? ""
        
        let url = Server.SERVER + Server.CALCULATIONS + "login=" + (login.stringByAddingPercentEncodingForRFC3986() ?? "")
        var request = URLRequest(url: URL(string: url + "&pwd=" + pwd)!)
        request.httpMethod = "GET"
        print(request)
        
        calcsGroup.enter()
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                self.calcsGroup.leave()
            }
            
            guard data != nil else { return }
            
            #if DEBUG
            print(String(data: data!, encoding: .utf8) ?? "")
            
            #endif
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                self.calcs = AccountCalculationsData(json: json!)!.data?.reversed() ?? []
                var currMonth = 0
                let currentDate = Date()
                let userCalendar = Calendar.current
                let requestedComponents: Set<Calendar.Component> = [
                    .year,
                    .month,
                    .day,
                    .hour,
                    .minute,
                    .second
                ]
                let dateTimeComponents = userCalendar.dateComponents(requestedComponents, from: currentDate)
                var k = 0
                self.calcs.forEach{
                    if $0.numYearSet! > dateTimeComponents.year!{
                        self.calcs.remove(at: k)
                    }
                    k += 1
                }
                
                self.filteredCalcs = self.calcs.filter {
                    if ($0.numMonthSet ?? 0) != currMonth {
                        currMonth = ($0.numMonthSet ?? 0)
                        return true
                    }
                    return false
                }
            }
            
            }.resume()
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





