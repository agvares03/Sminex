//
//  FinanceBarCodeVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/12/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class FinanceBarCodeVC: UIViewController {
    
    @IBOutlet private weak var topLayout:   NSLayoutConstraint!
    @IBOutlet private weak var barcode:     UIImageView!
    @IBOutlet private weak var amount:  	UILabel!
    @IBOutlet private weak var emptyLabel:  UILabel!
    
    open var data_:     AccountDebtJson?
    open var amount_:   Double?
    open var codePay_:  String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)

//        barcode.image = UIImage(ciImage: BarcodeGenerator.generate(from: "12345", symbology: .qr, size: barcode.frame.size)!)
        if data_ != nil {

            amount.text = String(Int(data_?.sumPay ?? 0.0))

            if data_?.codPay != nil && data_?.codPay != "" {
                barcode.image = UIImage(ciImage: BarcodeGenerator.generate(from: data_?.codPay ?? "", symbology: .qr, size: barcode.frame.size)!)

            } else {
                #if DEBUG
                    barcode.image = UIImage(ciImage: BarcodeGenerator.generate(from: "12345", symbology: .qr, size: barcode.frame.size)!)
                #else
                    emptyLabel.isHidden = false
                    barcode.isHidden    = true
                #endif
            }

        } else {
            amount.text = String(Int(amount_ ?? 0.0))
            if codePay_ != nil && codePay_ != "" {
                barcode.image = UIImage(ciImage: BarcodeGenerator.generate(from: codePay_ ?? "", symbology: .qr, size: barcode.frame.size)!)
            }
        }
        if isNeedToScrollMore() {
            topLayout.constant = 50
        }
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
}
