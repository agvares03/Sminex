//
//  Extensions.swift
//  Sminex
//
//  Created by IH0kN3m on 3/20/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

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
    
    func urlencode() -> String {
        let stringToEncode = self.replacingOccurrences(of: " ", with: "+")
        return stringToEncode.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!
    }
    
    func hmacsha1(key: String) -> Data {
        let dataToDigest = self.data(using: String.Encoding.utf8)
        let keyData = key.data(using: String.Encoding.utf8)
        
        let digestLength = Int(CC_SHA1_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<Any>.allocate(capacity: digestLength)
        
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), (keyData! as NSData).bytes, keyData!.count, (dataToDigest! as NSData).bytes, dataToDigest!.count, result)
        
        return Data(bytes: UnsafePointer(result), count: digestLength)
    }
}
