//
//  NewsListVC_Table.swift
//  Sminex
//
//  Created by Роман Тузин on 18.07.2018.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

class NewsListVC_Table: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        getNews()
        
    }
    
    private func getNews() {
        
        let login  = UserDefaults.standard.string(forKey: "id_account") ?? ""
        let lastId = TemporaryHolder.instance.newsLastId
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_NEWS + "accID=" + login + "&lastId=" + lastId)!)
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
                        self.data_ = TemporaryHolder.instance.news!
                        
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
            //print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            }.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
