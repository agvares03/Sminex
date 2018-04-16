//
//  BarcodeGenerator.swift
//  Sminex
//
//  Created by IH0kN3m on 4/12/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import Foundation

class BarcodeGenerator {
    enum Symbology: String {
        case code128 = "CICode128BarcodeGenerator"
        case pdf417 = "CIPDF417BarcodeGenerator"
        case aztec = "CIAztecCodeGenerator"
        case qr = "CIQRCodeGenerator"
    }
    
    class func generate(from string: String,
                        symbology: Symbology,
                        size: CGSize) -> CIImage? {
        let filterName = symbology.rawValue
        
        guard let data = string.data(using: .ascii),
            let filter = CIFilter(name: filterName) else {
                return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        
        guard let image = filter.outputImage else {
            return nil
        }
        
        let imageSize = image.extent.size
        
        let transform = CGAffineTransform(scaleX: size.width / imageSize.width,
                                          y: size.height / imageSize.height)
        let scaledImage = image.transformed(by: transform)
        
        return scaledImage
    }
}
