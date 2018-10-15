//
//  Extensions.swift
//  Sminex
//
//  Created by IH0kN3m on 3/20/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import DeviceKit
import Gloss

extension UIDevice {
    
    var modelName: String {
        
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
            
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad6,11", "iPad6,12":                    return "iPad 5"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7 Inch"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9 Inch"
        case "iPad7,1", "iPad7,2":                      return "iPad Pro 12.9 Inch 2. Generation"
        case "iPad7,3", "iPad7,4":                      return "iPad Pro 10.5 Inch"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
}

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
                    phone:              String,
                    contactNumber:      String,
                    adress:             String,
                    roomsCount:         String,
                    residentialArea:    String,
                    totalArea:          String,
                    strah:              String,
                    buisness:           String,
                    lsNumber:           String,
                    desc:               String) {
    
    var lsList      : [String] = []
    var addressList : [String] = []
    if UserDefaults.standard.stringArray(forKey: "allLS") != nil{
        lsList = UserDefaults.standard.stringArray(forKey: "allLS")!
        addressList = UserDefaults.standard.stringArray(forKey: "allAddress")!
        var k = 0
        lsList.forEach(){
            if $0 == lsNumber{
                k = 1
            }
        }
        if k == 0{
            lsList.removeAll()
            addressList.removeAll()
            lsList.append(lsNumber)
            addressList.append(adress)
        }
    }else{
        lsList.append(lsNumber)
        addressList.append(adress)
    }
    
    let defaults = UserDefaults.standard
    defaults.setValue(lsList, forKey: "allLS")
    defaults.setValue(addressList, forKey: "allAddress")
    defaults.setValue(lsNumber, forKey: "login")
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
    defaults.setValue(phone, forKey: "phone_user")
    defaults.setValue(contactNumber, forKey: "contactNumber")
    defaults.setValue(buisness, forKey: "buisness")
    defaults.setValue(desc, forKey: "accDesc")
    defaults.synchronize()
}

// Вычисляем соленый хэш пароля
func getHash(pass: String, salt: Data) -> String {
    
    if (String(data: salt, encoding: .utf8) ?? "Unauthorized").contains(find: "Unauthorized") {
        return ""
    }
    
    guard Data(base64Encoded: salt) != nil && pass.data(using: .utf16LittleEndian) != nil else { return "" }
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

func isPlusDevices() ->  Bool {
    
    return Device().isOneOf([.iPhone6Plus,
                             .iPhone6sPlus,
                             .iPhone7Plus,
                             .iPhone8Plus,
                             .simulator(.iPhone6Plus),
                             .simulator(.iPhone6sPlus),
                             .simulator(.iPhone7Plus),
                             .simulator(.iPhone8Plus)])
}

func isXDevice() -> Bool {
    
    return Device().isOneOf([.iPhoneX,
                             .simulator(.iPhoneX)])
}

func dayDifference(from date: Date, style: String? = nil) -> String
{
    let calendar = NSCalendar.current
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "Ru-ru")
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

func resizeImageWith(image: UIImage, newSize: CGSize) -> UIImage {
    
    let horizontalRatio = newSize.width / image.size.width
    let verticalRatio = newSize.height / image.size.height
    
    let ratio = max(horizontalRatio, verticalRatio)
    let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
    var newImage: UIImage
    
    if #available(iOS 10.0, *) {
        let renderFormat = UIGraphicsImageRendererFormat.default()
        renderFormat.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: newSize.width, height: newSize.height), format: renderFormat)
        newImage = renderer.image {
            (context) in
            image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        }
    } else {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newSize.width, height: newSize.height), false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
    }
    
    return newImage
}

extension UIViewController {
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 100, y: self.view.frame.size.height-100, width: 200, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        toastLabel.adjustsFontSizeToFitWidth = true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    } }

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

func getSalt() -> Data {

    if TemporaryHolder.instance.salt != nil {
        return TemporaryHolder.instance.salt ?? Data()
    
    } else {
        TemporaryHolder.instance.SaltQueue.wait()
        if TemporaryHolder.instance.salt != nil {
            return TemporaryHolder.instance.salt ?? Data()
            
        } else {
            var salt: Data?
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + (UserDefaults.standard.string(forKey: "login") ?? ""))!)
            request.httpMethod = "GET"
            
            TemporaryHolder.instance.SaltQueue.enter()
            URLSession.shared.dataTask(with: request) {
                data, response, error in
                
                defer {
                    TemporaryHolder.instance.SaltQueue.leave()
                }
                salt = data
                TemporaryHolder.instance.salt = data
                }.resume()
            
            TemporaryHolder.instance.SaltQueue.wait()
            return salt ?? Data()
        }
    }
}

func getBCImage(id: String) {
    
    TemporaryHolder.instance.bcQueue.enter()
    DispatchQueue.global(qos: .background).async {
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_BC_IMAGE + "guid=" + id)!)
        request.httpMethod = "GET"
        
        let (data, _, _) = URLSession.shared.synchronousDataTask(with: request.url!)
        if data != nil {
            let data = String(data: data!, encoding: .utf8) ?? ""
            if !data.contains(find: "not found") && !data.contains(find: "error") {
                TemporaryHolder.instance.bcImage = UIImage(data: Data(base64Encoded: (data.replacingOccurrences(of: "data:image/png;base64,", with: "")))!)
            }
        }
        TemporaryHolder.instance.bcQueue.leave()
    }
}

extension Formatter {
    
    static let withSeparator: NumberFormatter = {
        
        let formatter = NumberFormatter()
        formatter.groupingSeparator = " "
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension Double {
    
    var formattedWithSeparator: String {
        
        return Formatter.withSeparator.string(for: self) ?? ""
    }
}

extension BinaryInteger {
    
    var formattedWithSeparator: String {
        
        return Formatter.withSeparator.string(for: self) ?? ""
    }
}



extension UIView {
    // Note: the method needs the view from which the context is taken as an argument.
    func dropShadow(superview: UIView) {
        // Get context from superview
        UIGraphicsBeginImageContext(self.bounds.size)
        superview.drawHierarchy(in: CGRect(x: -self.frame.minX, y: -self.frame.minY, width: superview.bounds.width, height: superview.bounds.height), afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Add a UIImageView with the image from the context as a subview
        let imageView = UIImageView(frame: self.bounds)
        imageView.image = image
        imageView.layer.cornerRadius = self.layer.cornerRadius
        imageView.clipsToBounds = true
        self.addSubview(imageView)
        
        // Bring the background color to the front, alternatively set it as UIColor(white: 1, alpha: 0.2)
//        let brighter = UIView(frame: self.bounds)
//        brighter.backgroundColor = self.backgroundColor ?? UIColor(white: 1, alpha: 0.05)
//        brighter.layer.cornerRadius = self.layer.cornerRadius
//        brighter.clipsToBounds = true
//        self.addSubview(brighter)
        
        // Set the shadow
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOffset = CGSize(width: 1, height: 2)
        self.layer.shadowOpacity = 0.1
        var shadowRect = bounds
        shadowRect.origin.y += 5
        shadowRect.origin.x += 10
        shadowRect.size.width -= 20
        shadowRect.size.height -= 10
        self.layer.shadowPath = UIBezierPath(roundedRect: shadowRect, cornerRadius: self.layer.cornerRadius).cgPath
    }
}







