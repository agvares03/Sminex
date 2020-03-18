//
//  FinanceBarCodeVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/12/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import DeviceKit

final class FinanceBarCodeVC: UIViewController {
    
    @IBOutlet weak var qrView: UIView!
    @IBOutlet private weak var topLayout:   NSLayoutConstraint!
    @IBOutlet private weak var barcode:     UIImageView!
    @IBOutlet private weak var amount:  	UILabel!
    
    public var data_:     AccountDebtJson?
    public var amount_:   Double?
    public var codePay_:  String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        if data_ != nil {

            amount.text = String(Double(data_?.sumPay ?? 0.0))
            barcode.image = UIImage(ciImage: BarcodeGenerator.generate(from: data_?.codPay?.stringByAddingPercentEncodingForRFC3986() ?? "", symbology: .qr, size: barcode.frame.size)!)

        } else {
            amount.text = String(Double(amount_ ?? 0.0))
            if codePay_ != nil && codePay_ != "" {
                let img: CIImage? = BarcodeGenerator.generate(from: codePay_ ?? "", symbology: .qr, size: barcode.frame.size)!
                if img != nil {
                    barcode.image = UIImage(ciImage: img!)
                }
            }
        }
        self.topLayout.constant = 62
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
}
