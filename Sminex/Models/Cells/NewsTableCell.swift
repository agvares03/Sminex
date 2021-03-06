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
    @IBOutlet private weak var backView: UIView!
    @IBOutlet private weak var alertNews: UILabel!
    
    func configure(item: NewsJson?) {
        
        guard let item = item else { return }
        title.text = item.header
        if item.isImportant!{
            backView.borderColor = mainGreenColor
//            alertNews.isHidden = false
        }else{
            backView.borderColor = .white
//            alertNews.isHidden = true
        }
        desc.text = item.shortContent
        
        if item.dateStart != "" {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "dd.MM.yyyy HH:mm:ss"
            if dayDifference(from: df.date(from: item.created ?? "") ?? Date(), style: "dd MMMM").contains(find: "Сегодня") {
                date.text = dayDifference(from: df.date(from: item.created ?? "") ?? Date(), style: "HH:mm")
                
            } else {
                let dateI = df.date(from: item.created!)
                let calendar = Calendar.current
                let year = calendar.component(.year, from: dateI!)
                let curYear = calendar.component(.year, from: Date())
                if year < curYear{
                    date.text = dayDifference(from: df.date(from: item.created!) ?? Date(), style: "dd MMMM YYYY")
                }else{
                    date.text = dayDifference(from: df.date(from: item.created!) ?? Date(), style: "dd MMMM")
                }
            }
        }
    }

}
