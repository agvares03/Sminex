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
    
    // MARK: Functions
    
    func configure(title: String, counterName: String) {
        titleLbl.text = title
        counterNameLbl.text = counterName
    }

}
