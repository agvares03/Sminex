//
//  AppUser.swift
//  DemoUC
//
//  Created by Роман Тузин on 07.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import CoreData

protocol ShowAppDelegate : class {
    func showAppDone(showApp: AppUser)
}

class AppUser: UIViewController, UITableViewDelegate, UITableViewDataSource, CloseAppDelegate {
    // Картинки на подмену
    @IBOutlet weak var view_btn: UIView!
    @IBOutlet weak var fon_app: UIImageView!
    
    var delegate:ShowAppDelegate? = nil
    var App: Applications? = nil
    
    var txt_tema: String = ""
    var txt_text: String = ""
    var txt_date: String = ""
    
    var responseString: String = ""
    
    var fetchedResultsController: NSFetchedResultsController<Comments>?
    
    // id аккаунта текущего
    var id_author: String = ""
    var name_account: String = ""
    var id_account: String = ""
    var id_app: String = ""
    var teck_id: Int64 = 1

    @IBOutlet weak var tema_txt: UILabel!
    @IBOutlet weak var text_txt: UILabel!
    @IBOutlet weak var date_txt: UILabel!
    @IBOutlet weak var table_comments: UITableView!
    
    // Аутлеты для индикации процесса
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var btn1: UIButton!
    @IBOutlet weak var btn2: UIButton!
    @IBOutlet weak var btn3: UIButton!    

    @IBAction func send_comm(_ sender: UIButton) {
        
        let alert = AddCom(main_View: self.view, title: "Добавление комментария")
        alert.delegate_user = self
        alert.show(animated: true)
        
    }
    
    func addCommDone(addApp: AddCom, addComm: String) {
        if (addComm != "") {
            self.StartIndicator()
            
            let id_app_txt = self.id_app.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            let text_txt: String   = addComm.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            
            let urlPath = Server.SERVER + Server.SEND_COMM + "reqID=" + id_app_txt + "&text=" + text_txt;
            let url: NSURL = NSURL(string: urlPath)!
            let request = NSMutableURLRequest(url: url as URL)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request as URLRequest,
                                                  completionHandler: {
                                                    data, response, error in
                                                    
                                                    if error != nil {
                                                        DispatchQueue.main.async(execute: {
                                                            self.StopIndicator()
                                                            let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                                                            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                                                            alert.addAction(cancelAction)
                                                            self.present(alert, animated: true, completion: nil)
                                                        })
                                                        return
                                                    }
                                                    
                                                    self.responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
                                                    print("responseString = \(self.responseString)")
                                                    
                                                    self.choice(text: addComm)
            })
            task.resume()
            
        }
    }
    
    func choice(text: String) {
        if (responseString == "xxx") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else {
            DispatchQueue.main.async(execute: {
                
                // Экземпляр класса DB
                let db = DB()
                db.add_comm(ID: Int64(self.responseString)!, id_request: Int64(self.id_app)!, text: text, added: self.date_teck()!, id_Author: self.id_author, name: self.name_account, id_account: self.id_account)
                self.StopIndicator()
                self.load_data()
                self.updateTable()
            })
        }
        
    }
    
    @IBAction func close_app(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let myAlert = storyboard.instantiateViewController(withIdentifier: "close_alert") as! CloseAppAlert
        myAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        myAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        myAlert.number = self.id_app
        myAlert.id_author = self.id_author
        myAlert.name_account = self.name_account
        myAlert.id_account = self.id_account
        myAlert.delegate = self
        myAlert.App = self.App
        myAlert.teck_id = self.teck_id
        self.present(myAlert, animated: true, completion: nil)
    }
    
    @IBAction func files_app(_ sender: UIButton) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.StopIndicator()
        
        // Установим общий стиль
        let navigationBar = self.navigationController?.navigationBar
        //        navigationBar?.barStyle = UIBarStyle.black
        //        navigationBar?.backgroundColor = UIColor.blue
        navigationBar?.tintColor = UIColor.white
        navigationBar?.barTintColor = UIColor.blue
        
        // получим id текущего аккаунта
        let defaults = UserDefaults.standard
        id_author    = defaults.string(forKey: "id_account")!
        name_account = defaults.string(forKey: "name")!
        id_account   = defaults.string(forKey: "id_account")!

        tema_txt.text = txt_tema
        text_txt.text = txt_text
        date_txt.text = txt_date
        
        table_comments.delegate = self
        table_comments.rowHeight = UITableViewAutomaticDimension
        table_comments.estimatedRowHeight = 44.0
        
        load_data()
        updateTable()
        
        // Определим интерфейс для разных ук
        #if isGKRZS
            let server = Server()
            navigationBar?.barTintColor = server.hexStringToUIColor(hex: "#1f287f")
            view_btn.backgroundColor = server.hexStringToUIColor(hex: "#1f287f")
            fon_app.image = UIImage(named: "fon_app_gkrzs.jpg")
            view_btn.backgroundColor = server.hexStringToUIColor(hex: "#1f287f")
            fon_app.image = UIImage(named: "fon_app_gkrzs.jpg")
            let image1 = UIImage(named: "ic_comm_action_white")
            btn1.setImage(image1, for: UIControlState.normal)
            let image2 = UIImage(named: "ic_close_action_white")
            btn2.setImage(image2, for: UIControlState.normal)
            let image3 = UIImage(named: "ic_action_files_white")
            btn3.setImage(image3, for: UIControlState.normal)
        #else
            // Оставим текущуий интерфейс
        #endif
        
    }
    
    func load_data() {
        let predicateFormat = String(format: "id_app = %@", id_app)
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Comments", keysForSort: ["date"], predicateFormat: predicateFormat) as? NSFetchedResultsController<Comments>
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
    }
    
    func updateTable() {
        table_comments.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comm = (fetchedResultsController?.object(at: indexPath))! as Comments
        if (comm.id_author != id_account) {
            let cell = self.table_comments.dequeueReusableCell(withIdentifier: "CommCellCons") as! CommCellCons
            cell.author.text     = comm.author
            cell.date.text       = comm.date
            cell.text_comm.text  = comm.text
            self.teck_id = comm.id + 1
            
            #if isGKRZS
                let server = Server()
                cell.author.textColor = server.hexStringToUIColor(hex: "#1f287f")
            #else
            #endif
            
            return cell
        } else {
            let cell = self.table_comments.dequeueReusableCell(withIdentifier: "CommCell") as! CommCell
            cell.author.text     = comm.author
            cell.date.text       = comm.date
            cell.text_comm.text  = comm.text
            self.teck_id = comm.id + 1
            
            #if isGKRZS
                let server = Server()
                cell.author.textColor = server.hexStringToUIColor(hex: "#1f287f")
            #else
            #endif
            
            return cell
        }        
    }
    
    func closeAppDone(closeApp: CloseAppAlert) {
        self.load_data()
        self.table_comments.reloadData()
        self.delegate?.showAppDone(showApp: self)
    }
    
    func date_teck() -> (String)? {
        let date = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        let dateString = dateFormatter.string(from: date as Date)
        return dateString
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func StartIndicator() {
        self.btn1.isEnabled = false
        self.btn1.isHidden  = true
        
        self.btn2.isEnabled = false
        self.btn2.isHidden  = true
        
        self.btn3.isEnabled = false
        self.btn3.isHidden  = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    func StopIndicator() {
        self.btn1.isEnabled = true
        self.btn1.isHidden  = false
        
        self.btn2.isEnabled = true
        self.btn2.isHidden  = false
        
        self.btn3.isEnabled = true
        self.btn3.isHidden  = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }

}
