//
//  NewsTableCell.swift
//  Sminex
//
//  Created by Anton Barbyshev on 20.07.2018.
//  Copyright © 2018 Anton Barbyshev. All rights reserved.
//

import UIKit

class NewsTableCell: UITableViewCell {
    
    // MARK: Outlets

    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var desc: UILabel!
    @IBOutlet private weak var date: UILabel!
    
    func configure(item: NewsJson?) {
        
        guard let item = item else { return }
        
        title.text = item.header
        desc.text = item.shortContent
        
        if item.dateStart != "" {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "dd.MM.yyyy HH:mm:ss"
            if dayDifference(from: df.date(from: item.created ?? "") ?? Date(), style: "dd MMMM").contains(find: "Сегодня") {
                date.text = dayDifference(from: df.date(from: item.created ?? "") ?? Date(), style: "HH:mm")
                
            } else {
                date.text = dayDifference(from: df.date(from: item.created ?? "") ?? Date(), style: "dd MMMM")
            }
        }
    }

}
