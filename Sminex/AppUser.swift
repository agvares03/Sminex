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
@available(*, deprecated, message: "Класс нигде не используется. Будет удалён в будущих сборках")
final class AppUser: UIViewController, UITableViewDelegate, UITableViewDataSource, CloseAppDelegate {
    // Картинки на подмену
    @IBOutlet private weak var view_btn:  UIView!
    @IBOutlet private weak var fon_app:   UIImageView!
    
    var delegate:   ShowAppDelegate?
    open var apps_: Applications?
    
    open var txtTema_  = ""
    open var txtText_  = ""
    open var txtDate_  = ""
    
    open var idApp_    = ""
    
    private var responseString = ""
    
    private var fetchedResultsController: NSFetchedResultsController<Comments>?
    
    // id аккаунта текущего
    private var idAuthor     = ""
    private var nameAccount  = ""
    private var idAccount    = ""
    private var teckId       = 1
    
    @IBOutlet private weak var tema_txt:        UILabel!
    @IBOutlet private weak var text_txt:        UILabel!
    @IBOutlet private weak var date_txt:        UILabel!
    @IBOutlet private weak var table_comments:  UITableView!
    
    // Аутлеты для индикации процесса
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    @IBOutlet private weak var btn1:      UIButton!
    @IBOutlet private weak var btn2:      UIButton!
    @IBOutlet private weak var btn3:      UIButton!
    
    @IBAction private func send_comm(_ sender: UIButton) {
        
        let alert = AddCom(main_View: self.view, title: "Добавление комментария")
        alert.delegate_user = self
        alert.show(animated: true)
        
    }
    
    func addCommDone(addApp: AddCom, addComm: String) {
        if addComm != "" {
            self.startIndicator()
            
            let id_app_txt = idApp_.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
            let text_txt   = addComm.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.SEND_COMM + "reqID=" + id_app_txt + "&text=" + text_txt)!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) {
                data, response, error in
                
                if error != nil {
                    DispatchQueue.main.async {
                        self.stopIndicator()
                        let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                    return
                }
                
                self.responseString = String(data: data!, encoding: .utf8) ?? ""
                
                #if DEBUG
//                    print("responseString = \(self.responseString)")
                #endif
                
                self.choice(text: addComm)
                }.resume()
        }
    }
    
    private func choice(text: String) {
        DispatchQueue.main.async {
            
            if self.responseString == "xxx" {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else {
                // Экземпляр класса DB
                let db = DB()
                db.add_comm(ID: Int64(self.responseString)!, id_request: Int64(self.idApp_)!, text: text, added: self.dateTeck()!, id_Author: self.idAuthor, name: self.nameAccount, id_account: self.idAccount)
                self.stopIndicator()
                self.loadData()
                self.updateTable()
            }
        }
        
    }
    
    @IBAction func closeApp(_ sender: UIButton) {
        let storyboard  = UIStoryboard(name: "Main", bundle: nil)
        let myAlert     = storyboard.instantiateViewController(withIdentifier: "close_alert") as! CloseAppAlert
        myAlert.modalPresentationStyle  = UIModalPresentationStyle.overCurrentContext
        myAlert.modalTransitionStyle    = UIModalTransitionStyle.crossDissolve
        myAlert.number_          = idApp_
        myAlert.idAuthor_       = idAuthor
        myAlert.nameAccount_    = nameAccount
        myAlert.idAccount_      = idAccount
        myAlert.delegate        = self
        myAlert.apps_             = apps_
        myAlert.teckId_         = Int64(self.teckId)
        self.present(myAlert, animated: true, completion: nil)
    }
    
    @IBAction private func files_app(_ sender: UIButton) {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.stopIndicator()
        
        // Установим общий стиль
        let navigationBar           = self.navigationController?.navigationBar
        navigationBar?.tintColor    = UIColor.white
        navigationBar?.barTintColor = UIColor.blue
        
        // получим id текущего аккаунта
        let defaults = UserDefaults.standard
        idAuthor     = defaults.string(forKey: "id_account")!
        nameAccount  = defaults.string(forKey: "name")!
        idAccount    = defaults.string(forKey: "id_account")!
        
        tema_txt.text = txtTema_
        text_txt.text = txtText_
        date_txt.text = txtDate_
        
        table_comments.delegate = self
        table_comments.rowHeight = UITableViewAutomaticDimension
        table_comments.estimatedRowHeight = 44.0
        
        loadData()
        updateTable()
        
    }
    
    private func loadData() {
        let predicateFormat = String(format: "id_app = %@", idApp_)
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Comments", keysForSort: ["date"], predicateFormat: predicateFormat) as? NSFetchedResultsController<Comments>
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            
            #if DEBUG
                print(error)
            #endif
        }
    }
    
    private func updateTable() {
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
        if comm.id_author != idAccount {
            let cell = table_comments.dequeueReusableCell(withIdentifier: "CommCellCons") as! CommCellCons
            cell.author.text     = comm.author
            cell.date.text       = comm.date
            cell.text_comm.text  = comm.text
            self.teckId = Int(comm.id + 1)
            
            return cell
        } else {
            let cell = table_comments.dequeueReusableCell(withIdentifier: "CommCell") as! CommCell
            cell.author.text     = comm.author
            cell.date.text       = comm.date
            cell.text_comm.text  = comm.text
            self.teckId = Int(comm.id + 1)
            
            return cell
        }        
    }
    
    func closeAppDone(closeApp: CloseAppAlert) {
        self.loadData()
        self.table_comments.reloadData()
        self.delegate?.showAppDone(showApp: self)
    }
    
    private func dateTeck() -> (String)? {
        let dateFormatter           = DateFormatter()
        dateFormatter.dateFormat    = "dd.MM.yyyy HH:mm:ss"
        let dateString              = dateFormatter.string(from: Date())
        return dateString
        
    }
    
    private func startIndicator() {
        self.btn1.isEnabled = false
        self.btn1.isHidden  = true
        
        self.btn2.isEnabled = false
        self.btn2.isHidden  = true
        
        self.btn3.isEnabled = false
        self.btn3.isHidden  = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    private func stopIndicator() {
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



private final class CommCell: UITableViewCell {
    
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var text_comm: UILabel!
    
}

private final class CommCellCons: UITableViewCell {
    
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var text_comm: UILabel!
    
}

