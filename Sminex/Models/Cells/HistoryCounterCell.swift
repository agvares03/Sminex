//
//  HistoryCounterCell.swift
//  Sminex
//
//  Created by Anton Barbyshev on 28.07.2018.
//  Copyright © 2018 Anton Barbyshev. All rights reserved.
//

import UIKit

class HistoryCounterCell: UITableViewCell {
    
    // MARK: Outlets

    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var counterNameLbl: UILabel!
    @IBOutlet private weak var topFon:    UIView!
    @IBOutlet private weak var botFon:    UIView!
    
    // MARK: Functions
    
    func configure(title: String, counterName: String, indexCell: String) {
        titleLbl.text = title
        counterNameLbl.text = counterName
        if indexCell == "first"{
            self.topFon.isHidden = false
            self.botFon.isHidden = true
        }else if indexCell == "last"{
            self.topFon.isHidden = true
            self.botFon.isHidden = false
        }else{
            self.topFon.isHidden = false
            self.botFon.isHidden = false
        }
    }

}
