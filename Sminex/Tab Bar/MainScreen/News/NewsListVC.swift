//
//  NewsListVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/18/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss
import DeviceKit

final class NewsListVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var collection:  UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    open var tappedNews: NewsJson?
    open var data_: [NewsJson] = []
    private var index = 0
    private var refreshControl: UIRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if TemporaryHolder.instance.news != nil {
            data_ = TemporaryHolder.instance.news!
        }
        
        automaticallyAdjustsScrollViewInsets = false
        collection.dataSource = self
        collection.delegate   = self
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            collection.refreshControl = refreshControl
        } else {
            collection.addSubview(refreshControl!)
        }
        
        if tappedNews != nil {
            performSegue(withIdentifier: Segues.fromNewsList.toNews, sender: self)
        }
        
        startAnimation()
        getNews()
    }
    
    @objc private func refresh(_ sender: UIRefreshControl) {
        if TemporaryHolder.instance.news != nil {
            self.data_ = TemporaryHolder.instance.news!
        }
        getNews()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data_.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsListCell", for: indexPath) as! NewsListCell
        cell.display(data_[safe: indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cell = NewsListCell.fromNib()
        cell?.display(data_[indexPath.row])
        let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
        return CGSize(width: view.frame.size.width, height: !isNeedToScroll() ? size.height : size.height + 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        index = indexPath.row
        performSegue(withIdentifier: Segues.fromNewsList.toNews, sender: self)
    }
    
    private func getNews() {
        
        let login  = UserDefaults.standard.string(forKey: "id_account") ?? ""
        let lastId = TemporaryHolder.instance.newsLastId
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_NEWS + "accID=" + login + ((lastId != "" && lastId != "0") ? "&lastId=" + lastId : ""))!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.sync {
                    if #available(iOS 10.0, *) {
                        self.collection.refreshControl?.endRefreshing()
                    } else {
                        self.refreshControl?.endRefreshing()
                    }
                    self.collection.reloadData()
                    self.stopAnimation()
                }
            }
            
            guard data != nil else { return }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                if let newsArr = NewsJsonData(json: json!)?.data {
                    if newsArr.count != 0 {
                        TemporaryHolder.instance.news?.append(contentsOf: newsArr)
                        self.data_ = TemporaryHolder.instance.news!
                        
                    }
                }
            }
            
            if self.data_.count != 0 {
                DispatchQueue.global(qos: .background).async {
                    UserDefaults.standard.set(String(self.data_.first?.newsId ?? 0), forKey: "newsLastId")
                    TemporaryHolder.instance.newsLastId = String(self.data_.first?.newsId ?? 0)
                    UserDefaults.standard.synchronize()
                    let dataDict =
                        [
                            0 : self.data_,
                            1 : self.data_.filter { $0.isShowOnMainPage ?? false }
                    ]
                    let encoded = NSKeyedArchiver.archivedData(withRootObject: dataDict)
                    UserDefaults.standard.set(encoded, forKey: "newsList")
                    UserDefaults.standard.synchronize()
                }
            }
            
            #if DEBUG
                print(String(data: data!, encoding: .utf8) ?? "")
            #endif
        }.resume()
    }
    
    private func startAnimation() {
        loader.isHidden     = false
        collection.isHidden = true
        loader.startAnimating()
    }
    
    private func stopAnimation() {
        collection.isHidden = false
        loader.stopAnimating()
        loader.isHidden     = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromNewsList.toNews {
            let vc = segue.destination as! CurrentNews
            vc.data_ = tappedNews == nil ? data_[index] : tappedNews
            vc.isFromMain_ = tappedNews != nil
            tappedNews = nil
        }
    }
}

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
            df.dateFormat = "dd.MM.yyyy hh:mm:ss"
            if dayDifference(from: df.date(from: item?.dateStart ?? "") ?? Date(), style: "dd MMMM").contains(find: "Сегодня") {
                date.text = dayDifference(from: df.date(from: item?.dateStart ?? "") ?? Date(), style: "hh:mm")
                
            } else {
                date.text = dayDifference(from: df.date(from: item?.dateStart ?? "") ?? Date(), style: "dd MMMM")
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















