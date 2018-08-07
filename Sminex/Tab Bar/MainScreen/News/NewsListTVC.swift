//
//  NewsListVC_Table.swift
//  Sminex
//
//  Created by Роман Тузин on 18.07.2018.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss

class NewsListTVC: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var loader: UIActivityIndicatorView!
    
    // MARK: Properties
    
    private var data: [NewsJson] = []
    private var index = 0
    open var tappedNews: NewsJson?
    private var rControl: UIRefreshControl?
    
    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70
        tableView.register(UINib(nibName: "NewsTableCell", bundle: nil), forCellReuseIdentifier: "NewsTableCell")
        
        rControl = UIRefreshControl()
        rControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        tableView.refreshControl = rControl
        
        if TemporaryHolder.instance.news != nil {
            data = TemporaryHolder.instance.news!
        }
        
        if tappedNews != nil {
            performSegue(withIdentifier: Segues.fromNewsList.toNews, sender: self)
        }
        
        startAnimation()
        getNews()
    }
    
    @objc private func refresh(_ sender: UIRefreshControl) {
        if TemporaryHolder.instance.news != nil {
            self.data = TemporaryHolder.instance.news!
        }
        getNews()
    }
    
    // MARK: Private functions
    
    private func getNews() {
        
        let login  = UserDefaults.standard.string(forKey: "id_account") ?? ""
        let lastId = TemporaryHolder.instance.newsLastId
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_NEWS + "accID=" + login + "&lastId=" + lastId)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.sync {
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                    self.stopAnimation()
                }
            }
            
            guard data != nil else { return }
            
            print(String(data: data!, encoding: .utf8) ?? "")
            
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
                        self.data = TemporaryHolder.instance.news!
                        
                        DispatchQueue.main.sync {
                            self.tableView.refreshControl?.endRefreshing()
                            self.tableView.reloadData()
                            self.stopAnimation()
                        }
                        
                    }
                }
            }
            
            if self.data.count != 0 {
                DispatchQueue.global(qos: .background).async {
                    UserDefaults.standard.set(String(self.data.first?.newsId ?? 0), forKey: "newsLastId")
                    TemporaryHolder.instance.newsLastId = String(self.data.first?.newsId ?? 0)
                    UserDefaults.standard.synchronize()
                    let dataDict =
                        [
                            0 : self.data,
                            1 : self.data.filter { $0.isShowOnMainPage ?? false }
                    ]
                    let encoded = NSKeyedArchiver.archivedData(withRootObject: dataDict)
                    UserDefaults.standard.set(encoded, forKey: "newsList")
                    UserDefaults.standard.synchronize()
                }
            }
            
            #if DEBUG
            //print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            }.resume()
    }
    
    private func startAnimation() {
        loader.isHidden     = false
        tableView.isHidden = true
        loader.startAnimating()
    }
    
    private func stopAnimation() {
        tableView.isHidden = false
        loader.stopAnimating()
        loader.isHidden     = true
    }
    
    // MARK: Actions
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromNewsList.toNews {
            let vc = segue.destination as! CurrentNews
            vc.data_ = tappedNews == nil ? data[index] : tappedNews
            vc.isFromMain_ = tappedNews != nil
            tappedNews = nil
        }
    }

}

extension NewsListTVC: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsTableCell", for: indexPath) as! NewsTableCell
        let news = data[indexPath.row]
        cell.configure(item: news)
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        index = indexPath.row
        performSegue(withIdentifier: Segues.fromNewsList.toNews, sender: self)
    }
    
}
