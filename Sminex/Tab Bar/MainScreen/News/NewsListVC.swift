//
//  NewsListVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/18/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss

final class NewsListCell: UICollectionViewCell {
    
    @IBOutlet private weak var title: 	UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet private weak var date:    UILabel!
    
    func display(_ item: NewsJson?) {
        
        guard item != nil else { return }
        
        title.text  = item?.header
        desc.text   = item?.shortContent
        
        if item?.dateStart != "" {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "dd.MM.yyyy HH:mm:ss"
            if dayDifference(from: df.date(from: item?.created ?? "") ?? Date(), style: "dd MMMM").contains(find: "Сегодня") {
                date.text = dayDifference(from: df.date(from: item?.created ?? "") ?? Date(), style: "hh:mm")
                
            } else {
                date.text = dayDifference(from: df.date(from: item?.created ?? "") ?? Date(), style: "dd MMMM")
            }
        }
    }
    
    class func fromNib() -> NewsListCell? {
        var cell: NewsListCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? NewsListCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        cell?.desc.preferredMaxLayoutWidth = cell?.desc.bounds.size.width ?? 0.0
        
        return cell
    }
}

struct NewsJsonData: JSONDecodable {
    
    let data: [NewsJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

final class NewsJson: NSObject, JSONDecodable, NSCoding {
    
    let shortContent:       String?
    let headerImage:        String?
    let dateStart:          String?
    let dateEnd:            String?
    let created:            String?
    let header:             String?
    let text:               String?
    let isShowOnMainPage: 	Bool?
    let isReaded:           Bool?
    let isDraft: 	        Bool?
    let newsId:             Int?
    
    init(json: JSON) {
        isShowOnMainPage    = "ShowOnMainPage"  <~~ json
        shortContent        = "ShortContent"    <~~ json
        headerImage         = "HeaderImage"     <~~ json
        dateStart           = "DateStart"       <~~ json
        isReaded            = "IsReaded"        <~~ json
        dateEnd             = "DateEnd"         <~~ json
        isDraft             = "IsDraft"         <~~ json
        created             = "Created"         <~~ json
        header              = "Header"          <~~ json
        newsId              = "NewsID"          <~~ json
        text                = "Text"            <~~ json
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(shortContent, forKey: "shortContent")
        aCoder.encode(headerImage, forKey: "headerImage")
        aCoder.encode(dateStart, forKey: "dateStart")
        aCoder.encode(dateEnd, forKey: "dateEnd")
        aCoder.encode(created, forKey: "created")
        aCoder.encode(header, forKey: "header")
        aCoder.encode(text, forKey: "text")
        aCoder.encode(isShowOnMainPage, forKey: "isShowOnMainPage")
        aCoder.encode(isReaded, forKey: "isReaded")
        aCoder.encode(isDraft, forKey: "isDraft")
        aCoder.encode(newsId, forKey: "newsId")
    }
    
    required init?(coder aDecoder: NSCoder) {
        shortContent       = aDecoder.decodeObject(forKey: "shortContent")      as? String
        headerImage        = aDecoder.decodeObject(forKey: "headerImage")       as? String
        dateStart          = aDecoder.decodeObject(forKey: "dateStart")         as? String
        dateEnd            = aDecoder.decodeObject(forKey: "dateEnd")           as? String
        created            = aDecoder.decodeObject(forKey: "created")           as? String
        header             = aDecoder.decodeObject(forKey: "header")            as? String
        text               = aDecoder.decodeObject(forKey: "text")              as? String
        isShowOnMainPage   = aDecoder.decodeObject(forKey: "isShowOnMainPage")  as? Bool
        isReaded           = aDecoder.decodeObject(forKey: "isReaded")          as? Bool
        isDraft            = aDecoder.decodeObject(forKey: "isDraft")           as? Bool
        newsId             = aDecoder.decodeObject(forKey: "newsId")            as? Int
    }
}















