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
    return Device().isOneOf([Device.iPhone5,
                             Device.iPhone5s,
                             Device.iPhone5c,
                             Device.iPhoneSE,
                             Device.iPhone4,
                             Device.iPhone4s,
                             Device.simulator(Device.iPhone5),
                             Device.simulator(Device.iPhone5s),
                             Device.simulator(Device.iPhone5c),
                             Device.simulator(Device.iPhoneSE),
                             Device.simulator(Device.iPhone4),
                             Device.simulator(Device.iPhone4s)])
}

func isNeedToScrollMore() -> Bool {
    
    return Device().isOneOf([Device.iPhone4,
                             Device.iPhone4s,
                             Device.simulator(Device.iPhone4),
                             Device.simulator(Device.iPhone4s)])
}
