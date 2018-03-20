//
//  AppCons.swift
//  DemoUC
//
//  Created by Роман Тузин on 13.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import CoreData

protocol ShowAppConsDelegate : class {
    func showAppDone(showAppCons: AppCons)
}

final class AppCons: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Картинки на подмену
    @IBOutlet private weak var view_btn:    UIView!
    @IBOutlet private weak var fon_app:     UIImageView!
    
    // массивы для перевода на консультантов (один массив - имена, другой - коды)
    private var namesConsArray: [String] = []
    private var idsConsArray:   [String] = []
    private var teckCons = -1
    
    open var delegate: ShowAppConsDelegate?
    
    private var responseString: String = ""
    private var teckID:         Int64  = 0

    @IBOutlet private weak var adress:   UILabel!
    @IBOutlet private weak var tema:     UILabel!
    @IBOutlet private weak var text_app: UILabel!
    @IBOutlet private weak var date_app: UILabel!
    
    private var fetchedResultsController: NSFetchedResultsController<Comments>?
    
    @IBOutlet private weak var table_comments: UITableView!
    
    // Аутлеты для индикации
    @IBOutlet private weak var indicator:   UIActivityIndicatorView!
    @IBOutlet private weak var btn1:        UIButton!
    @IBOutlet private weak var btn2: 	    UIButton!
    @IBOutlet private weak var btn3:        UIButton!
    @IBOutlet private weak var btn4:        UIButton!
    @IBOutlet private weak var btn5:        UIButton!
    @IBOutlet private weak var btn6: 	    UIButton!
    @IBOutlet private weak var btn_ring:    UIButton!
    
    // id аккаунта текущего
    private var idAuthor    = ""
    private var nameAccount = ""
    private var idAccount   = ""
    open var idApp_         = ""
    
    open var txtAdress_ = ""
    open var txtPhone_  = ""
    open var txtTema_   = ""
    open var txtText_   = ""
    open var txtDate_   = ""
    
    @IBAction private func do_call(_ sender: UIButton) {
        if txtPhone_ != "" {
            let url = URL(string: "tel://\(txtPhone_)")!
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        } else {
            let alert = UIAlertController(title: "Ошибка", message: "Не обнаружен номер телефона", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.stopIndicator()
        
        // Установим общий стиль
        let navigationBar           = self.navigationController?.navigationBar
        navigationBar?.tintColor    = UIColor.white
        navigationBar?.barTintColor = UIColor.blue
        
        // получим id текущего аккаунта
        let defaults = UserDefaults.standard
        idAuthor    = defaults.string(forKey: "id_account")!
        nameAccount = defaults.string(forKey: "name")!
        idAccount   = defaults.string(forKey: "id_account")!
        
        adress.text   = txtAdress_
        tema.text     = txtTema_
        text_app.text = txtText_
        date_app.text = txtDate_

        table_comments.delegate  = self
        table_comments.rowHeight = UITableViewAutomaticDimension
        table_comments.estimatedRowHeight = 44.0
        
        loadData()
        updateTable()
        getCons(id_acc: idAccount)
    }

    private func loadData() {
        let predicateFormat = String(format: "id_app = %@", idApp_)
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Comments", keysForSort: ["id"], predicateFormat: predicateFormat) as? NSFetchedResultsController<Comments>
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
            let cell = self.table_comments.dequeueReusableCell(withIdentifier: "CommConsCell_cons") as! CommConsCell_cons
            cell.author.text     = comm.author
            cell.date.text       = comm.date
            cell.text_comm.text  = comm.text
            self.teckID = comm.id + 1
            
            return cell
        } else {
            let cell = self.table_comments.dequeueReusableCell(withIdentifier: "CommConsCell") as! CommConsCell
            cell.author.text     = comm.author
            cell.date.text       = comm.date
            cell.text_comm.text  = comm.text
            self.teckID = comm.id + 1
            
            return cell
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "select_cons" {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings_ = namesConsArray
            selectItemController.selectedIndex_ = teckCons
            selectItemController.selectHandler_ = { selectedIndex in
                self.teckCons = selectedIndex
                let choice_cons = self.appConsString()
                let choice_id   = self.idsConsArray[selectedIndex]
                print("User - " + choice_cons + " id - " + choice_id)
                
                // Переведем заявку другому консультанту
                self.chApp(id_account: self.idAccount, id_app: self.idApp_, new_cons_id: choice_id, new_cons_name: choice_cons)
            }
        }
    }
    private func appConsString() -> String {
        if teckCons == -1 {
            return "не выбран"
        }
        
        if teckCons >= 0 && teckCons < namesConsArray.count {
            return namesConsArray[teckCons]
        }
        
        return ""
    }

    // Действия консультанта
    // Принять заявку
    @IBAction private func getApp(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Принятие заявки", message: "Принять заявку к выполнению?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .default) { (_) -> Void in }
        alert.addAction(cancelAction)
        let okAction = UIAlertAction(title: "Да", style: .default) { (_) -> Void in
            
            self.startIndicator()
            
            let id_app_txt = self.idApp_.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_APP + "accID=" + self.idAccount + "&reqID=" + id_app_txt)!)
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
                    print("responseString = \(self.responseString)")
                #endif
                
                self.choiceGetApp()
                }.resume()

        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    
    }
    // Написать комментарий
    @IBAction private func send_comm(_ sender: UIButton) {
        
        let alert       = AddCom(main_View: self.view, title: "Добавление комментария")
        alert.delegate  = self
        alert.show(animated: true)
        
    }
    // Перевести заявку
    private func chApp(id_account: String, id_app: String, new_cons_id: String, new_cons_name: String) {
        
        self.startIndicator()
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.CH_CONS + "accID=" + id_account + "&reqID=" + id_app + "&chgID=" + new_cons_id)!)
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
                print("responseString = \(self.responseString)")
            #endif
            self.choiceConsApp(name_cons: new_cons_name)
            }.resume()
    }
    @IBAction private func send_app(_ sender: UIButton) {}
    
    // Выполнить заявку
    @IBAction private func ok_app(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Выполнение заявки", message: "Выполнить заявку?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .default) { (_) -> Void in }
        alert.addAction(cancelAction)
        let okAction = UIAlertAction(title: "Да", style: .default) { (_) -> Void in
            
            self.startIndicator()
            
            let id_app_txt = self.idApp_.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.OK_APP + "accID=" + self.idAccount + "&reqID=" + id_app_txt)!)
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
                    print("responseString = \(self.responseString)")
                #endif
                
                self.choiceOkApp()
            }.resume()
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)

    }
    
    // Закрыть заявку
    @IBAction private func close_app(_ sender: UIButton) {
        let alert = UIAlertController(title: "Закрытие заявки", message: "Действительно закрыть заявку?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .default) { (_) -> Void in }
        alert.addAction(cancelAction)
        let okAction = UIAlertAction(title: "Да", style: .default) { (_) -> Void in
            
            self.startIndicator()
            
            let id_app_txt = self.idApp_.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.CLOSE_APP_CONS + "accID=" + self.idAccount + "&reqID=" + id_app_txt)!)
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
                    print("responseString = \(self.responseString)")
                #endif
                
                self.choiceCloseApp()
                }.resume()
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // ПРОЦЕДУРЫ ОТВЕТЫ ОТ СЕРВЕРА
    // Ответ - принятие заявки
    private func choiceGetApp() {
        DispatchQueue.main.async {
        
        if self.responseString == "xxx" {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else if self.responseString == "3" {
                self.stopIndicator()
                let alert = UIAlertController(title: "Предупреждение", message: "Заявка принята специалистом", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else if self.responseString == "1" {
                let db = DB()
                db.add_comm(ID: self.teckID, id_request: Int64(self.idApp_)!, text: "Заявка принята специалистом " + self.nameAccount, added: self.dateTeck()!, id_Author: self.idAuthor, name: self.nameAccount, id_account: self.idAccount)
                self.stopIndicator()
                self.loadData()
                self.updateTable()
            }
        }
    }
    
    // Ответ - комментарий
    private func choiceSendComm(text: String) {
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
    
    // Ответ - перевести заявку другому консультанту
    private func choiceConsApp(name_cons: String) {
        DispatchQueue.main.async {
        
        if self.responseString == "xxx" {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else if self.responseString == "1" {
                // Экземпляр класса DB
                let db = DB()
                db.add_comm(ID: self.teckID, id_request: Int64(self.idApp_)!, text: "Заявка №" + self.idApp_ + " переведена специалисту - " + name_cons, added: self.dateTeck()!, id_Author: self.idAuthor, name: self.nameAccount, id_account: self.idAccount)
                // Подумать, как можно удалить потом
                //db.del_app(number: self.id_app)
                self.stopIndicator()
                self.loadData()
                self.updateTable()
            
        } else {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // Ответ - выполнить заявку
    private func choiceOkApp() {
        DispatchQueue.main.async {
        
        if self.responseString == "xxx" {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else{
                // Экземпляр класса DB
                let db = DB()
                db.add_comm(ID: self.teckID, id_request: Int64(self.idApp_)!, text: "Заявка №" + self.idApp_ + " выполнена специалистом - " + self.nameAccount, added: self.dateTeck()!, id_Author: self.idAuthor, name: self.nameAccount, id_account: self.idAccount)
                // Подумать, как можно удалить потом
//                db.del_app(number: self.id_app)
                self.stopIndicator()
                self.loadData()
                self.updateTable()
                
            }
        }
    }
    
    // Ответ - закрыть заявку
    private func choiceCloseApp() {
        DispatchQueue.main.async {
        
        if self.responseString == "xxx" {
            self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else{
                // Экземпляр класса DB
                let db = DB()
                db.add_comm(ID: self.teckID, id_request: Int64(self.idApp_)!, text: "Заявка №" + self.idApp_ + " закрыта специалистом - " + self.nameAccount, added: self.dateTeck()!, id_Author: self.idAuthor, name: self.nameAccount, id_account: self.idAccount)
                // Подумать, как можно удалить потом
//                db.del_app(number: self.id_app)
                self.stopIndicator()
                self.loadData()
                self.updateTable()
                
            }
        }
    }
    
    // ВСПОМОГАТЕЛЬНЫЕ ПРОЦЕДУРЫ
    private func dateTeck() -> (String)? {
        let dateFormatter        = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        return dateString
        
    }
    
    private func getCons(id_acc: String) {
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_CONS + "id_account=" + id_acc)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                return
            } else {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                    
                    // Получим список консультантов
                    if let houses = json["data"] {
                        for index in 0...(houses.count)!-1 {
                            let obj_cons = houses.object(at: index) as! [String:AnyObject]
                            for obj in obj_cons {
                                if obj.key == "name" {
                                    self.namesConsArray.append(obj.value as! String)
                                }
                                if obj.key == "id" {
                                    self.idsConsArray.append(String(describing: obj.value))
                                }
                            }
                        }
                    }
                } catch let error {
                    
                    #if DEBUG
                        print(error)
                    #endif
                }
            }
        }.resume()
    }
    
    private func startIndicator() {
        self.btn1.isEnabled = false
        self.btn1.isHidden  = true
        
        self.btn2.isEnabled = false
        self.btn2.isHidden  = true
        
        self.btn3.isEnabled = false
        self.btn3.isHidden  = true
        
        self.btn4.isEnabled = false
        self.btn4.isHidden  = true
        
        self.btn5.isEnabled = false
        self.btn5.isHidden  = true
        
        self.btn6.isEnabled = false
        self.btn6.isHidden  = true
        
        self.btn_ring.isEnabled = false
        self.btn_ring.isHidden  = true
        
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
        
        self.btn4.isEnabled = true
        self.btn4.isHidden  = false
        
        self.btn5.isEnabled = true
        self.btn5.isHidden  = false
        
        self.btn6.isEnabled = true
        self.btn6.isHidden  = false
        
        self.btn_ring.isEnabled = true
        self.btn_ring.isHidden  = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
    
    func addCommDone(addApp: AddCom, addComm: String) {
        
        if addComm != "" {
            self.startIndicator()
            
            let id_app_txt = self.idApp_.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            let text_txt   = addComm.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.SEND_COMM_CONS + "reqID=" + id_app_txt + "&text=" + text_txt + "&accID=" + self.idAccount + "&isHidden=false")!)
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
                    print("responseString = \(self.responseString)")
                #endif
                
                self.choiceSendComm(text: (addComm))
            }.resume()
        }
        
        loadData()
        self.table_comments.reloadData()
    }
}

// MARK: -CELLS

private final class CommConsCell: UITableViewCell {
    
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var text_comm: UILabel!
    
}

private final class CommConsCell_cons: UITableViewCell {
    
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var text_comm: UILabel!
    
}
