//
//  DatePickerCell.swift
//  Sminex
//
//  Created by Anton Barbyshev on 23.07.2018.
//  Copyright © 2018 Anton Barbyshev. All rights reserved.
//

import UIKit

protocol DatePickerCellDelegate: class {
    func dateDidChange(date: Date)
}

class DatePickerCell: UITableViewCell {
    
    // MARK: Outlets

    @IBOutlet private weak var datePicker: UIDatePicker!
    
    // MARK: Properties
    
    weak var delegate: DatePickerCellDelegate?
    
    // MARK: Functions
    
    func configure(date: Date) {
        datePicker.date = date
        datePicker.minimumDate = Date()
    }
    
    // MARK: Actions
    
    @IBAction private func dateDidChange(sender: UIDatePicker) {
        delegate?.dateDidChange(date: sender.date)
    }

}
