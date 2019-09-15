//
//  DB.swift
//  DemoUC
//
//  Created by Роман Тузин on 27.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import CoreData
import UIKit

final class DB: NSObject, XMLParserDelegate {
    
    // Глобальные переменные для парсинга
    var parser = XMLParser()
    var currYear: String = "";
    var currMonth: String = "";
    var login: String = ""
    
    // Удалить записи из таблиц
    public func del_db(table_name: String) {
        print(table_name)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: table_name)
        do {
            
            let results = try CoreDataManager.instance.managedObjectContext.fetch(fetchRequest)
            for result in results {
                CoreDataManager.instance.managedObjectContext.delete(result as! NSManagedObject)
            }
        } catch {
            #if DEBUG
                print(error)
            #endif
        }
        CoreDataManager.instance.saveContext()
    }
    
    // Обращение к серверу - получение данных
    func parse_Countrers(login: String, pass: String, history: String) {
        // Получим данные из xml
        // Потом сделать отдельный класс !!!
        let login = login
        let pass =  pass
        var urlPath = Server.SERVER + Server.GET_METERS + "login=" + login.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)! + "&pwd=" + pass;
        if (history == "0") {
            urlPath = urlPath + "&onlyCurrent=1"
        }
        var url: NSURL = NSURL(string: urlPath)!
        parser = XMLParser(contentsOf: url as URL)!
        parser.delegate = self
        let success:Bool = parser.parse()
        
        #if DEBUG
            if success {
                print("parse success!")
            } else {
                print("parse failure!")
            }
        #endif
        
        // сохраним последние значения Месяц-Год в глобальных переменных
        save_month_year(month: self.currMonth, year: self.currYear)
        
        // Сохранить типы приборов
        urlPath = Server.SERVER + Server.GET_METERS + "login=" + login.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)! + "&pwd=" + pass + "&onlyMeterTypes=1";
        url = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        print(request)
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    return
                                                } else {
                                                    
                                                    do {

                                                        var json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                                                        print("JSON",json)
                                                        
                                                        if let json_notifications = json["data"] {
                                                            let int_end = (json_notifications.count)!-1
                                                            if (int_end < 0) {
                                                            } else {
                                                                
                                                                for index in 0...int_end {
                                                                    let json_not = json_notifications.object(at: index) as! String

                                                                    self.add_type_counter(type: json_not)
                                                                    
                                                                }
                                                            }
                                                        }
                                                        
                                                    } catch let error as NSError {
                                                        print(error)
                                                    }
                                                    
                                                }
        })
        task.resume()
        
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        // ПОКАЗАНИЯ ПРИБОРОВ
        if (elementName == "Period") {
            self.currYear = attributeDict["Year"]!
            self.currMonth = attributeDict["NumMonth"]!
        } else if (elementName == "MeterValue") {
            // Запишем показание прибора
            let managedObject = Counters()
            managedObject.id            = 1
            managedObject.uniq_num      = attributeDict["MeterUniqueNum"]!
            managedObject.owner         = attributeDict["MeterType"]
            managedObject.num_month     = self.currMonth
            managedObject.year          = self.currYear
            managedObject.count_name    = attributeDict["Name"]
            managedObject.count_ed_izm  = attributeDict["Units"]
            managedObject.prev_value    = (attributeDict["PreviousValue"]! as NSString).floatValue
            managedObject.value         = (attributeDict["Value"]! as NSString).floatValue
            managedObject.diff          = (attributeDict["Difference"]! as NSString).floatValue
            CoreDataManager.instance.saveContext()
        }
        
        // Заявки с комментариями (xml)
//        var id_app = ""
        if (elementName == "Row") {
            // Запишем заявку в БД
//            print(attributeDict)
            let managedObject = Applications()
            managedObject.id              = 1
            managedObject.number          = attributeDict["ID"]
            managedObject.text            = attributeDict["text"]
            managedObject.tema            = attributeDict["name"]
            managedObject.date            = attributeDict["added"]
            managedObject.adress          = attributeDict["HouseAddress"]
            managedObject.flat            = attributeDict["FlatNumber"]
            managedObject.phone           = attributeDict["PhoneNum"]
            managedObject.is_paid         = attributeDict["IsPaidService"]
            managedObject.owner           = login
            if (attributeDict["isActive"] == "1") {
                managedObject.is_close    = 1
            } else {
                managedObject.is_close    = 0
            }
            if (attributeDict["IsReaded"] == "1") {
                managedObject.is_read     = 1
            } else {
                managedObject.is_read     = 0
            }
            if (attributeDict["IsAnswered"] == "1") {
                managedObject.is_answered = 1
            } else {
                managedObject.is_answered = 0
            }
            CoreDataManager.instance.saveContext()
//            id_app                        = attributeDict["ID"]!
//            #if DEBUG
//                print(id_app)
//            #endif
        } else if (elementName == "Comm") {
            // Запишем комментарии в БД
            let managedObject = Comments()
            managedObject.id              = Int64(attributeDict["ID"]!)!
            managedObject.id_app          = Int64(attributeDict["id_request"]!)!
            managedObject.text            = attributeDict["text"]
            managedObject.date            = attributeDict["added"]
            managedObject.id_author       = attributeDict["id_Author"]
            managedObject.author          = attributeDict["Name"]
            managedObject.id_account      = attributeDict["id_account"]
            CoreDataManager.instance.saveContext()
        } else if (elementName == "File") {
            // Запишем файл в БД
//            let managedObject = Fotos()
//            managedObject.id              = Int64(attributeDict["FileID"]!)!
//            managedObject.name            = attributeDict["FileName"]
//            managedObject.number          = id_app
//            managedObject.date            = attributeDict["DateTime"]
//            CoreDataManager.instance.saveContext()
            
            // Подгрузим картинку файла
//            let imgURL: NSURL = NSURL(string: Server.SERVER + Server.DOWNLOAD_PIC + "id=" + attributeDict["FileID"]! + "&tmode=1")!
//            let request: NSURLRequest = NSURLRequest(url: imgURL as URL)
//            let task = URLSession.shared.dataTask(with: request as URLRequest,
//                                                  completionHandler: {
//                                                    data, response, error in
//                                                    
//                                                    if error != nil {
//                                                        return
//                                                    }
//                                                    
//                                                    let foto_small = data! as NSData
//                                                    self.get_foto(data: foto_small, id: Int64(attributeDict["FileID"]!)!, name: attributeDict["FileName"]!, number: id_app, date: attributeDict["DateTime"]!, id_app: id_app)
//                                                    
//            })
//            task.resume()
            
        }
        
    }
    // Получили фото - запишем в БД
    func get_foto(data: NSData, id: Int64, name: String, number: String, date: String, id_app: String) {
        let managedObject = Fotos()
        managedObject.id              = id
        managedObject.name            = name
        managedObject.number          = id_app
        managedObject.date            = date
        managedObject.foto_small      = data
        CoreDataManager.instance.saveContext()
    }
    
    
    // СОХРАНЕНИЕ ЗНАЧЕНИЙ ДЛЯ ПЕРЕДАЧИ В КОНТРОЛЛЕРЫ
    func save_month_year(month: String, year: String) {
        
        // Если нет данных о показаниях - введем текущую дату и год
        let date = NSDate()
        let calendar = NSCalendar.current
        let resultDate = calendar.component(.year, from: date as Date)
        let resultMonth = calendar.component(.month, from: date as Date)
        
        let defaults = UserDefaults.standard
        if (month == "") {
            defaults.setValue(resultMonth, forKey: "month")
        } else {
            defaults.setValue(month, forKey: "month")
        }
        if (year == "") {
            defaults.setValue(resultDate, forKey: "year")
        } else {
            defaults.setValue(year, forKey: "year")
        }

        defaults.synchronize()
    }
    
    // Ведомость
    func parse_OSV(login: String, pass: String) {
        
        var sum:Double = 0
        
        let urlPath = Server.SERVER + Server.GET_BILLS_SERVICES + "login=" + login.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)! + "&pwd=" + pass.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!;
        
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
//                                                print(String(data: data!, encoding: .utf8)!)
                                                
                                                if error != nil {
                                                    return
                                                } else {
                                                    var i_month: Int = 0
                                                    var i_year: Int = 0
                                                    do {
                                                        var bill_month    = ""
                                                        var bill_year     = ""
                                                        var bill_service  = ""
                                                        var bill_acc      = ""
                                                        var bill_debt     = ""
                                                        var bill_pay      = ""
                                                        var bill_total    = ""
                                                        var json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                                                        print("JSON",json)
                                                        
                                                        if let json_bills = json["data"] {
                                                            let int_end = (json_bills.count)!-1
                                                            if (int_end < 0) {
                                                                
                                                            } else {
                                                                
                                                                for index in 0...int_end {
                                                                    let json_bill = json_bills.object(at: index) as! [String:AnyObject]
                                                                    for obj in json_bill {
                                                                        if obj.key == "Month" {
                                                                            bill_month = String(describing: obj.value as! NSNumber)
                                                                        }
                                                                        if obj.key == "Year" {
                                                                            bill_year = String(describing: obj.value as! NSNumber)
                                                                        }
                                                                        if obj.key == "Service" {
                                                                            bill_service = obj.value as! String
                                                                        }
                                                                        if obj.key == "Accured" {
                                                                            bill_acc = String(describing: obj.value as! NSNumber)
                                                                        }
                                                                        if obj.key == "Debt" {
                                                                            bill_debt = String(describing: obj.value as! NSNumber)
                                                                        }
                                                                        if obj.key == "Payed" {
                                                                            bill_pay = String(describing: obj.value as! NSNumber)
                                                                        }
                                                                        if obj.key == "Total" {
                                                                            bill_total = String(describing: obj.value as! NSNumber)
                                                                        }
                                                                    }
                                                                        
                                                                    self.add_data_saldo(usluga: bill_service, num_month: bill_month, year: bill_year, start: bill_acc, plus: bill_debt, minus: bill_pay, end: bill_total)
                                                                    
                                                                    if (Int(bill_month)! > i_month) {
                                                                        i_month = Int(bill_month)!
                                                                    }
                                                                    if (Int(bill_year)! > i_year) {
                                                                        i_year = Int(bill_year)!
                                                                    }
                                                                    
                                                                }
                                                            }
                                                        }
                                                        
                                                    } catch let error as NSError {
                                                        print(error)
                                                    }
                                                    
                                                    // Выборка из БД последней ведомости - посчитаем сумму к оплате
                                                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Saldo")
                                                    fetchRequest.predicate = NSPredicate.init(format: "num_month = %@ AND year = %@", String(i_month), String(i_year))
                                                    do {
                                                        let results = try CoreDataManager.instance.managedObjectContext.fetch(fetchRequest)
                                                        for result in results {
                                                            let object = result as! NSManagedObject
                                                            sum = sum + Double(object.value(forKey: "end") as! String)!
                                                        }
                                                    } catch {
                                                        
//                                                        #if DEBUG
//                                                            print(error)
//                                                        #endif
                                                    }
                                                    
                                                    let defaults = UserDefaults.standard
                                                    defaults.setValue(String(i_month), forKey: "month_osv")
                                                    defaults.setValue(String(i_year), forKey: "year_osv")
                                                    defaults.setValue(String(describing: sum), forKey: "sum")
                                                    defaults.synchronize()
                                                    
                                                }
                                                
        })
        task.resume()
        
        // Тестовые данные - потом сделать запрос
//        add_data_saldo(usluga: "ХВС", num_month: "1", year: "2017", start: "150.5", plus: "205", minus: "105.5", end: "205")
//        add_data_saldo(usluga: "ХВС", num_month: "2", year: "2017", start: "205", plus: "201", minus: "0", end: "406")
//        add_data_saldo(usluga: "ХВС", num_month: "3", year: "2017", start: "406", plus: "220", minus: "406", end: "220")
//        add_data_saldo(usluga: "ХВС", num_month: "4", year: "2017", start: "220", plus: "205", minus: "0", end: "425")
//        
//        add_data_saldo(usluga: "ГВС", num_month: "1", year: "2017", start: "203", plus: "205", minus: "180", end: "228")
//        add_data_saldo(usluga: "ГВС", num_month: "2", year: "2017", start: "228", plus: "212", minus: "200", end: "240")
//        add_data_saldo(usluga: "ГВС", num_month: "3", year: "2017", start: "240", plus: "210", minus: "0", end: "450")
//        add_data_saldo(usluga: "ГВС", num_month: "4", year: "2017", start: "450", plus: "200", minus: "450", end: "200")
//        
//        add_data_saldo(usluga: "ЭЭ", num_month: "1", year: "2017", start: "50.5", plus: "180.5", minus: "0", end: "231")
//        add_data_saldo(usluga: "ЭЭ", num_month: "2", year: "2017", start: "231", plus: "180.5", minus: "0", end: "411.5")
//        add_data_saldo(usluga: "ЭЭ", num_month: "3", year: "2017", start: "411.5", plus: "180.5", minus: "0", end: "592")
//        add_data_saldo(usluga: "ЭЭ", num_month: "4", year: "2017", start: "592", plus: "180.5", minus: "592", end: "180.5")
        
//        let defaults = UserDefaults.standard
//        defaults.setValue("4", forKey: "month_osv")
//        defaults.setValue("2017", forKey: "year_osv")
//        defaults.synchronize()
        
    }
    func add_data_saldo(usluga: String, num_month: String, year: String, start: String, plus: String, minus: String, end: String) {
        let managedObject = Saldo()
        managedObject.id               = 1
        managedObject.usluga           = usluga
        managedObject.num_month        = num_month
        managedObject.year             = year
        managedObject.start            = start
        managedObject.plus             = plus
        managedObject.minus            = minus
        managedObject.end              = end
        
        CoreDataManager.instance.saveContext()
    }
    
    // Типы приборов
    func add_type_counter(type: String) {
        let managedObject = TypesCounters()
        managedObject.name = type
        
        CoreDataManager.instance.saveContext()
    }
    
    // Уведомления
    func parse_Notifications(id_account: String, readed: Bool = false) {
        var readedKol = 0
        let urlPath = Server.SERVER + Server.GET_NOTIFICATIONS + "accID=" + id_account.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        print(request)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
//                                                print(String(data: data!, encoding: .utf8) ?? "")
                                                
                                                if error != nil {
                                                    return
                                                } else {
                                                    
                                                    // Запишем в БД данные по уведомлениям
                                                    do {
                                                        var id            = 1
                                                        var name          = ""
                                                        var type          = ""
                                                        var ident         = ""
                                                        var date          = ""
                                                        var isReaded      = false
                                                        var json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
//                                                        print("JSON",json)
                                                        
                                                        if let json_notifications = json["data"] {
                                                            let int_end = (json_notifications.count)!-1
                                                            if (int_end < 0) {
                                                            } else {
                                                                
                                                                for index in 0...int_end {
                                                                    let json_not = json_notifications.object(at: index) as! [String:AnyObject]
                                                                    for obj in json_not {
                                                                        if obj.key == "ID" {
                                                                            id = obj.value as! Int
                                                                        }
                                                                        if obj.key == "Name" {
                                                                            name = obj.value as! String
                                                                        }
                                                                        if obj.key == "Type" {
                                                                            type = obj.value as! String
                                                                        }
                                                                        if obj.key == "Ident" {
                                                                            ident = obj.value as! String
                                                                        }
                                                                        if obj.key == "Date" {
                                                                            date = obj.value as! String
                                                                        }
                                                                        if obj.key == "IsReaded" {
                                                                            isReaded = obj.value as! Bool
                                                                        }
                                                                    }
                                                                    if !isReaded{
                                                                        if readed{
                                                                            self.readNotifi(id: id)
                                                                        }else{
                                                                            readedKol += 1
                                                                        }
                                                                    }
                                                                    self.add_data_notification(id: id, name: name, type: type, ident: ident, date: date, isReaded: isReaded)

                                                                    
                                                                }
                                                            }
                                                        }
                                                        
                                                        UserDefaults.standard.set(true, forKey: "successParse")
                                                        TemporaryHolder.instance.menuNotifications = readedKol
                                                    } catch let error as NSError {
                                                        print(error)
                                                    }
                                                    
                                                }
        })
        task.resume()
    }
    func add_data_notification(id: Int, name: String, type: String, ident: String, date: String, isReaded: Bool) {
        let managedObject = Notifications()
        managedObject.id               = Int64(id)
        managedObject.name             = name
        managedObject.type             = type
        managedObject.ident            = ident
        let df = DateFormatter()
        managedObject.date             = date
        df.dateFormat = "dd.MM.yyyy HH:mm:ss"
        managedObject.date1            = df.date(from: date)
        managedObject.isReaded         = isReaded
        
        CoreDataManager.instance.saveContext()
    }
    
    private func readNotifi(id: Int) {
        //        let push = (self.fetchedResultsController?.object(at: self.select))! as Notifications
        var request = URLRequest(url: URL(string: Server.SERVER + "SetNotificationReadedState.ashx?id=" + String(id))!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            guard data != nil else { return }
            let responseString = String(data: data!, encoding: .utf8)!
            if responseString == "ok"{
                
            }else{
                return
            }
            }.resume()
    }
    
    // Заявки с комментариями
    func parse_Apps(login: String, pass: String, isCons: String) {
        
        // Если в БД нет заявок - получаем все заявки
        //        let fetchedResultsController: NSFetchedResultsController<Applications>?
        //        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Applications", keysForSort: ["date"], predicateFormat: nil) as? NSFetchedResultsController<Applications>
        //        if (fetchedResultsController?.sections?.count)! > 0 {
        //
        //        } else {
        
        self.login = login
        let pass  = pass
        var TextCons = ""
        if (isCons == "1") {
            TextCons = "&isConsultant=true&isActive=1;isPerformed=0"
        }
        let urlPath = Server.SERVER + Server.GET_APPS_COMM + "login=" + login.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)! + "&pwd=" + pass.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)! + TextCons;
        let url: NSURL = NSURL(string: urlPath)!
        
        parser = XMLParser(contentsOf: url as URL)!
        parser.delegate = self
//        let success     = parser.parse()
        
//        #if DEBUG
//            if success {
//                print("parse success!")
//            } else {
//                print("parse failure!")
//            }
//        #endif
        
        //        }
    }

    func parse_Houses() {
        let urlPath = Server.SERVER + Server.GET_HOUSES
        
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    return
                                                } else {
                                                    do {
                                                        let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
//                                                        if let jsonDict = json as? [String: AnyObject] {
                                                            // Получим дома
                                                            if let houses = json["Houses"] as? [String: AnyObject] {
                                                                let id_house = houses["ID"] as? String
                                                                let name_house = houses["Address"] as? String
                                                                self.add_house(ID: Int64(id_house!)!, name: name_house!)
                                                                
                                                                // Получим квартиры
                                                                if let flats = houses["Premises"] as? [String: AnyObject] {
                                                                    let id_flat = flats["ID"] as? String
                                                                    var flat_name = flats["Number"] as? String
                                                                    if (flat_name?.count == 1) {
                                                                        flat_name = "00" + flat_name!
                                                                    } else if (flat_name?.count == 2) {
                                                                        flat_name = "0" + flat_name!
                                                                    }
                                                                    self.add_flat(ID: Int64(id_flat!)!, id_house: Int64(id_house!)!, name: flat_name! + " кв.")
                                                                    
                                                                    // Получим лицевые счета
                                                                    if let ls = flats["Account"] as? [String: AnyObject] {
                                                                        let ls_number = ls["Ident"] as? String
                                                                        let ls_fio = ls["FIO"] as? String
                                                                        self.add_ls(ID: Int64(ls_number!)!, id_flat: Int64(id_flat!)!, fio: ls_fio!)
                                                                    }
                                                                }
                                                            }
//                                                        }
                                                    } catch let error as NSError {
                                                        
                                                        #if DEBUG
                                                            print(error)
                                                        #endif
                                                    }
                                                }
                                 
        })
        task.resume()
    }
    
    // Получение комментарий по отдельной заявке
    func getComByID(login: String, pass: String, number: String) {
        let urlPath = Server.SERVER + Server.GET_COMM_ID +
            "id=" + number.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)! +
            "&login=" + login.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)! +
            "&pwd=" + pass.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!;
        let url: NSURL = NSURL(string: urlPath)!
        
        parser = XMLParser(contentsOf: url as URL)!
        parser.delegate = self
//        let success:Bool = parser.parse()
        
//        #if DEBUG
//            if success {
//                print("parse success!")
//            } else {
//                print("parse failure!")
//            }
//        #endif
    }
    
    // ОТДЕЛЬНЫЕ ПРОЦЕДУРЫ РАБОТЫ С БД
    
    // Добавить заявку
    func add_app(id: Int64, number: String, text: String, tema: String, date: String, adress: String, flat: String, phone: String, owner: String, is_close: Int64, is_read: Int64, is_answered: Int64) {
        
        let managedObject = Applications()
        managedObject.id              = 1
        managedObject.number          = number
        managedObject.text            = text
        managedObject.tema            = tema
        managedObject.date            = date
        managedObject.adress          = adress
        managedObject.flat            = flat
        managedObject.phone           = phone
        managedObject.owner           = owner
        managedObject.is_close        = is_close
        managedObject.is_read         = is_read
        managedObject.is_answered     = is_answered

        CoreDataManager.instance.saveContext()
    }
    
    // Добавить комментарий
    func add_comm(ID: Int64, id_request: Int64, text: String, added: String, id_Author: String, name: String, id_account: String) {
        let managedObject = Comments()
        managedObject.id              = ID
        managedObject.id_app          = id_request
        managedObject.text            = text
        managedObject.date            = added
        managedObject.id_author       = id_Author
        managedObject.author          = name
        managedObject.id_account      = id_account
        CoreDataManager.instance.saveContext()
        
    }
    
    // Добавить дом
    func add_house(ID: Int64, name: String) {
        let managedObject = Houses()
        managedObject.id = ID
        managedObject.name = name
        CoreDataManager.instance.saveContext()
    }
    
    // Добавим квартиру
    func add_flat(ID: Int64, id_house: Int64, name: String) {
        let managedObject = Flats()
        managedObject.id = ID
        managedObject.id_house = id_house
        managedObject.name = name
        CoreDataManager.instance.saveContext()
    }
    
    // Добавим лиц. счет
    func add_ls(ID: Int64, id_flat: Int64, fio: String) {
        let managedObject = Ls()
        managedObject.id = ID
        managedObject.id_flat = id_flat
        managedObject.fio = fio
        managedObject.name = fio
        CoreDataManager.instance.saveContext()
    }
    
    // Удалить заявку
    func del_app(number: String) {        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Applications")
        fetchRequest.predicate = NSPredicate.init(format: "number==\(number)")
        do {
            let results = try CoreDataManager.instance.managedObjectContext.fetch(fetchRequest)
            for result in results {
                CoreDataManager.instance.managedObjectContext.delete(result as! NSManagedObject)
            }
        } catch {
            
//            #if DEBUG
//                print(error)
//            #endif
        }
        CoreDataManager.instance.saveContext()
    }
    
    func getQuestions() -> [QuestionEntity] {
        
        let fetchRequest =  NSFetchRequest<NSFetchRequestResult>(entityName: "QuestionEntity")
        var arr: [QuestionEntity] = []
        
        do {
            
            let results = try CoreDataManager.instance.managedObjectContext.fetch(fetchRequest)
            
            for result in results {
                arr.append(result as! QuestionEntity)
            }
            
        } catch let error {
            
            #if DEBUG
                print(error)
            #endif
        }
        
        return arr
    }
    
    func setQuestions(answerId: [Int], questionId: [Int], id: String) {
        
        let managedObject = QuestionEntity()
        
        managedObject.questionId    = questionId
        managedObject.answerId      = answerId
        managedObject.id            = id
        
        CoreDataManager.instance.saveContext()
    }
    
    func deleteQuestions() {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QuestionEntity")
        
        do {
            
            let results = try CoreDataManager.instance.managedObjectContext.fetch(fetchRequest)
            for result in results {
                CoreDataManager.instance.managedObjectContext.delete(result as! NSManagedObject)
            }
        
        } catch let error {
            
            #if DEBUG
                print(error)
            #endif
        }
        CoreDataManager.instance.saveContext()
    }
}

struct RequestEntityData {
    let title:  String
    let desc:   String
    let icon:   UIImage
    let date:   String
    let status: String
    let isBack: Bool
    let id:     String
}
