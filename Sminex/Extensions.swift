//
//  Extensions.swift
//  Sminex
//
//  Created by IH0kN3m on 3/20/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import DeviceKit

extension UIView {
    
    /* Adds shadow to view. */
    @IBInspectable var shadow: Bool {
        
        get {
            return layer.shadowOpacity > 0.0
        }
        set {
            if newValue == true {
                self.addShadow()
            }
        }
    }
    /* Or radius of view. */
    @IBInspectable var cornerRadius: CGFloat {
        
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
            
            if shadow == false {
                self.layer.masksToBounds = true
            }
        }
    }
    
    /* Func to dynamicly add shadow. */
    func addShadow(shadowColor: CGColor = UIColor.black.cgColor,
                   shadowOffset: CGSize = CGSize(width: 1.0,
                                                 height: 2.0),
                   shadowOpacity: Float = 0.4,
                   shadowRadius: CGFloat = 3.0) {
        
        layer.shadowColor   = shadowColor
        layer.shadowOffset  = shadowOffset
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius  = shadowRadius
    }
}

extension String {
    
    var length: Int {
        return self.count
    }
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
    
    func contains(find: String) -> Bool{
        return self.range(of: find) != nil
    }
    
    func containsIgnoringCase(find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    
    func sha1() -> String {
        let data = self.data(using: String.Encoding.utf8)!
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0, CC_LONG(data.count), &digest)
        }
        return Data(bytes: digest).base64EncodedString()
    }
    
    func stringByAddingPercentEncodingForRFC3986() -> String? {
        let unreserved = "-._~/?"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        return self.addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
    }
}

extension URLSession {
    func synchronousDataTask(with url: URL) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask = self.dataTask(with: url) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (data, response, error)
    }
}

// сохранениеи глобальных значений
func saveGlobalData(date1:              String,
                    date2:              String,
                    can_count:          String,
                    mail:               String,
                    id_account:         String,
                    isCons:             String,
                    name:               String,
                    history_counters:   String,
                    contactNumber:      String,
                    adress:             String,
                    roomsCount:         String,
                    residentialArea:    String,
                    totalArea:          String,
                    strah:              String) {
    
    let defaults = UserDefaults.standard
    defaults.setValue(date1, forKey: "date1")
    defaults.setValue(date2, forKey: "date2")
    defaults.setValue(can_count, forKey: "can_count")
    defaults.setValue(mail, forKey: "mail")
    defaults.setValue(id_account, forKey: "id_account")
    defaults.setValue(isCons, forKey: "isCons")
    defaults.setValue(name, forKey: "name")
    defaults.setValue(strah, forKey: "strah")
    defaults.setValue(roomsCount, forKey: "roomsCount")
    defaults.setValue(residentialArea, forKey: "residentialArea")
    defaults.setValue(totalArea, forKey: "totalArea")
    defaults.setValue(history_counters, forKey: "history_counters")
    defaults.setValue(adress, forKey: "adress")
    defaults.setValue(contactNumber, forKey: "contactNumber")
    defaults.synchronize()
}

// Вычисляем соленый хэш пароля
func getHash(pass: String, salt: Data) -> String {
    
    if (String(data: salt, encoding: .utf8) ?? "Unauthorized").contains(find: "Unauthorized") {
        return ""
    }
    
    let btl = pass.data(using: .utf16LittleEndian)!
    let bSalt = Data(base64Encoded: salt)!
    
    var bAll = bSalt + btl
    
    var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
    bAll.withUnsafeBytes {
        _ = CC_SHA1($0, CC_LONG(bAll.count), &digest)
    }
    
    let psw = Data(bytes: digest).base64String.replacingOccurrences(of: "\n", with: "")
    
    return psw.stringByAddingPercentEncodingForRFC3986()!
}

func isNeedToScroll() -> Bool {
    
    // Только если >4" экран
    return Device().isOneOf([.iPhone5,
                             .iPhone5s,
                             .iPhone5c,
                             .iPhoneSE,
                             .iPhone4,
                             .iPhone4s,
                             .simulator(Device.iPhone5),
                             .simulator(Device.iPhone5s),
                             .simulator(Device.iPhone5c),
                             .simulator(Device.iPhoneSE),
                             .simulator(Device.iPhone4),
                             .simulator(Device.iPhone4s)])
}

func isNeedToScrollMore() -> Bool {
    
    return Device().isOneOf([.iPhone4,
                             .iPhone4s,
                             .simulator(Device.iPhone4),
                             .simulator(Device.iPhone4s)])
}

func dayDifference(from date: Date, style: String? = nil) -> String
{
    let calendar = NSCalendar.current
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = style == nil ? "hh:mm:ss" : style
    if calendar.isDateInYesterday(date) { return "Вчера, \(dateFormatter.string(from: date))" }
    else if calendar.isDateInToday(date) { return "Сегодня, \(dateFormatter.string(from: date))" }
    else if calendar.isDateInTomorrow(date) { return "Завтра, \(dateFormatter.string(from: date))" }
    else {
        return dateFormatter.string(from: date)
    }
}

func getNameAndMonth(_ number_month: Int) -> String {
    
    if number_month == 1 {
        return "Январь"
    } else if number_month == 2 {
        return "Февраль"
    } else if number_month == 3 {
        return "Март"
    } else if number_month == 4 {
        return "Апрель"
    } else if number_month == 5 {
        return "Май"
    } else if number_month == 6 {
        return "Июнь"
    } else if number_month == 7 {
        return "Июль"
    } else if number_month == 8 {
        return "Август"
    } else if number_month == 9 {
        return "Сентябрь"
    } else if number_month == 10 {
        return "Октябрь"
    } else if number_month == 11 {
        return "Ноябрь"
    } else {
        return "Декабрь"
    }
}
