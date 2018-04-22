//
//  NewsListVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/18/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss

final class NewsListVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var collection:  UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    open var data_: [NewsJson] = []
    private var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        collection.dataSource = self
        collection.delegate   = self
        startAnimation()
        getNews()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data_.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsListCell", for: indexPath) as! NewsListCell
        cell.display(data_[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cell = NewsListCell.fromNib()
        cell?.display(data_[indexPath.row])
        let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
        return CGSize(width: view.frame.size.width, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        index = indexPath.row
        performSegue(withIdentifier: Segues.fromNewsList.toNews, sender: self)
    }
    
    private func getNews() {
        
        let login  = UserDefaults.standard.string(forKey: "id_account") ?? ""
        let lastId = UserDefaults.standard.string(forKey: "newsLastId") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_NEWS + "accID=" + login + "&lastId=" + (lastId != "0" ? lastId : ""))!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.sync {
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
            
            self.data_.append(contentsOf: NewsJsonData(json: try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! JSON)!.data!)
            
            DispatchQueue.global(qos: .background).async {
                let dataDict =
                    [
                    0 : self.data_,
                    1 : self.data_.filter { $0.isShowOnMainPage ?? false }
                    ]
                let encoded = NSKeyedArchiver.archivedData(withRootObject: dataDict)
                UserDefaults.standard.set(encoded, forKey: "newsList")
                UserDefaults.standard.set(String(self.data_.last?.newsId ?? 0), forKey: "newsLastId")
                UserDefaults.standard.synchronize()
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
            vc.data_ = data_[index]
        }
    }
}

final class NewsListCell: UICollectionViewCell {
    
    @IBOutlet private weak var title: 	UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet private weak var date:    UILabel!
    
    func display(_ item: NewsJson) {
        
        title.text  = item.header
        desc.text   = item.shortContent
        date.text   = item.dateStart
    }
    
    class func fromNib() -> NewsListCell? {
        var cell: NewsListCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? NewsListCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 25.0) - 25
        cell?.desc.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 25.0) - 25
        return cell
    }
}

struct NewsJsonData: JSONDecodable {
    
    let data: [NewsJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

struct NewsJson: JSONDecodable {
    
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
    
    init?(json: JSON) {
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
}















