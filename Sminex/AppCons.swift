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

class AppCons: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // Картинки на подмену
    @IBOutlet weak var view_btn: UIView!
    @IBOutlet weak var fon_app: UIImageView!
    
    // массивы для перевода на консультантов (один массив - имена, другой - коды)
    var names_cons: [String] = []
    var ids_cons: [String] = []
    var teck_cons = -1
    
    var delegate:ShowAppConsDelegate? = nil
    
    var responseString: String = ""
    var teckID: Int64 = 0

    @IBOutlet weak var adress: UILabel!
    @IBOutlet weak var tema: UILabel!
    @IBOutlet weak var text_app: UILabel!
    @IBOutlet weak var date_app: UILabel!
    
    var fetchedResultsController: NSFetchedResultsController<Comments>?
    
    @IBOutlet weak var table_comments: UITableView!
    
    // Аутлеты для индикации
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var btn1: UIButton!
    @IBOutlet weak var btn2: UIButton!
    @IBOutlet weak var btn3: UIButton!
    @IBOutlet weak var btn4: UIButton!
    @IBOutlet weak var btn5: UIButton!
    @IBOutlet weak var btn6: UIButton!
    @IBOutlet weak var btn_ring: UIButton!
    
    // id аккаунта текущего
    var id_author: String = ""
    var name_account: String = ""
    var id_account: String = ""
    var id_app: String = ""
    
    var txt_adress: String = ""
    var txt_phone:String = ""
    var txt_tema: String = ""
    var txt_text: String = ""
    var txt_date: String = ""
    
    @IBAction func do_call(_ sender: UIButton) {
        if (txt_phone != "") {
            let url = URL(string: "tel://\(txt_phone)")!
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
        
        adress.text = txt_adress
        tema.text = txt_tema
        text_app.text = txt_text
        date_app.text = txt_date

        table_comments.delegate = self
        table_comments.rowHeight = UITableViewAutomaticDimension
        table_comments.estimatedRowHeight = 44.0
        
        load_data()
        updateTable()
        get_cons(id_acc: id_account)
    }

    func load_data() {
        let predicateFormat = String(format: "id_app = %@", id_app)
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Comments", keysForSort: ["id"], predicateFormat: predicateFormat) as? NSFetchedResultsController<Comments>
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
            selectItemController.strings = names_cons
            selectItemController.selectedIndex = teck_cons
            selectItemController.selectHandler = { selectedIndex in
                self.teck_cons = selectedIndex
                let choice_cons = self.appConsString()
                let choice_id   = self.ids_cons[selectedIndex]
                print("User - " + choice_cons + " id - " + choice_id)
                // Переведем заявку другому консультанту
                self.ch_app(id_account: self.id_account, id_app: self.id_app, new_cons_id: choice_id, new_cons_name: choice_cons)
            }
        }
    }
    func appConsString() -> String {
        if teck_cons == -1 {
            return "не выбран"
        }
        
        if teck_cons >= 0 && teck_cons < names_cons.count {
            return names_cons[teck_cons]
        }
        
        return ""
    }

    // Действия консультанта
    // Принять заявку
    @IBAction func get_app(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Принятие заявки", message: "Принять заявку к выполнению?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .default) { (_) -> Void in }
        alert.addAction(cancelAction)
        let okAction = UIAlertAction(title: "Да", style: .default) { (_) -> Void in
            
            self.StartIndicator()
            
            let id_app_txt = self.id_app.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            
            let urlPath = Server.SERVER + Server.GET_APP + "accID=" + self.id_account + "&reqID=" + id_app_txt
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
                                                    
                                                    self.choice_get_app()
            })
            task.resume()

        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    
    }
    // Написать комментарий
    @IBAction func send_comm(_ sender: UIButton) {
        
        let alert = AddCom(main_View: self.view, title: "Добавление комментария")
        alert.delegate = self
        alert.show(animated: true)
        
    }
    // Перевести заявку
    func ch_app(id_account: String, id_app: String, new_cons_id: String, new_cons_name: String) {
        self.StartIndicator()
        let urlPath = Server.SERVER + Server.CH_CONS + "accID=" + id_account + "&reqID=" + id_app + "&chgID=" + new_cons_id
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
                                                
                                                self.choice_cons_app(name_cons: new_cons_name)
        })
        task.resume()
    }
    @IBAction func send_app(_ sender: UIButton) {
    }
    // Выполнить заявку
    @IBAction func ok_app(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Выполнение заявки", message: "Выполнить заявку?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .default) { (_) -> Void in }
        alert.addAction(cancelAction)
        let okAction = UIAlertAction(title: "Да", style: .default) { (_) -> Void in
            
            self.StartIndicator()
            
            let id_app_txt = self.id_app.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            
            let urlPath = Server.SERVER + Server.OK_APP + "accID=" + self.id_account + "&reqID=" + id_app_txt
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
                                                    
                                                    self.choice_ok_app()
            })
            task.resume()
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)

    }
    
    // Закрыть заявку
    @IBAction func close_app(_ sender: UIButton) {
        let alert = UIAlertController(title: "Закрытие заявки", message: "Действительно закрыть заявку?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .default) { (_) -> Void in }
        alert.addAction(cancelAction)
        let okAction = UIAlertAction(title: "Да", style: .default) { (_) -> Void in
            
            self.StartIndicator()
            
            let id_app_txt = self.id_app.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            
            let urlPath = Server.SERVER + Server.CLOSE_APP_CONS + "accID=" + self.id_account + "&reqID=" + id_app_txt
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
                                                    
                                                    self.choice_close_app()
            })
            task.resume()
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // ПРОЦЕДУРЫ ОТВЕТЫ ОТ СЕРВЕРА
    // Ответ - принятие заявки
    func choice_get_app() {
        if (responseString == "xxx") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString == "3"){
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Предупреждение", message: "Заявка принята специалистом", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString == "1") {
            DispatchQueue.main.async(execute: {
                let db = DB()
                db.add_comm(ID: self.teckID, id_request: Int64(self.id_app)!, text: "Заявка принята специалистом " + self.name_account, added: self.date_teck()!, id_Author: self.id_author, name: self.name_account, id_account: self.id_account)
                self.StopIndicator()
                self.load_data()
                self.updateTable()
            })
        }
    }
    
    // Ответ - комментарий
    func choice_send_comm(text: String) {
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
    
    // Ответ - перевести заявку другому консультанту
    func choice_cons_app(name_cons: String) {
        if (responseString == "xxx") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString == "1") {
            DispatchQueue.main.async(execute: {
                // Экземпляр класса DB
                let db = DB()
                db.add_comm(ID: self.teckID, id_request: Int64(self.id_app)!, text: "Заявка №" + self.id_app + " переведена специалисту - " + name_cons, added: self.date_teck()!, id_Author: self.id_author, name: self.name_account, id_account: self.id_account)
                // Подумать, как можно удалить потом
                //db.del_app(number: self.id_app)
                self.StopIndicator()
                self.load_data()
                self.updateTable()
                
            })
        } else {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        }
    }
    
    // Ответ - выполнить заявку
    func choice_ok_app() {
        if (responseString == "xxx") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else{
            DispatchQueue.main.async(execute: {
                // Экземпляр класса DB
                let db = DB()
                db.add_comm(ID: self.teckID, id_request: Int64(self.id_app)!, text: "Заявка №" + self.id_app + " выполнена специалистом - " + self.name_account, added: self.date_teck()!, id_Author: self.id_author, name: self.name_account, id_account: self.id_account)
                // Подумать, как можно удалить потом
//                db.del_app(number: self.id_app)
                self.StopIndicator()
                self.load_data()
                self.updateTable()
                
            })
        }
    }
    
    // Ответ - закрыть заявку
    func choice_close_app() {
        if (responseString == "xxx") {
            self.StopIndicator()
            DispatchQueue.main.async(execute: {
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else{
            DispatchQueue.main.async(execute: {
                // Экземпляр класса DB
                let db = DB()
                db.add_comm(ID: self.teckID, id_request: Int64(self.id_app)!, text: "Заявка №" + self.id_app + " закрыта специалистом - " + self.name_account, added: self.date_teck()!, id_Author: self.id_author, name: self.name_account, id_account: self.id_account)
                // Подумать, как можно удалить потом
//                db.del_app(number: self.id_app)
                self.StopIndicator()
                self.load_data()
                self.updateTable()
                
            })
        }
    }
    
    // ВСПОМОГАТЕЛЬНЫЕ ПРОЦЕДУРЫ
    func date_teck() -> (String)? {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        let dateString = dateFormatter.string(from: date as Date)
        return dateString
        
    }
    
    func get_cons(id_acc: String) {
        let urlPath = Server.SERVER + Server.GET_CONS + "id_account=" + id_acc
        
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
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
                                                                        self.names_cons.append(obj.value as! String)
                                                                    }
                                                                    if obj.key == "id" {
                                                                        self.ids_cons.append(String(describing: obj.value))
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    } catch let error as NSError {
                                                        print(error)
                                                    }
                                                }
                                                
        })
        task.resume()
    }
    
    func StartIndicator() {
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
    
    func StopIndicator() {
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
        if (addComm != "") {
            self.StartIndicator()
            
            let id_app_txt = self.id_app.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            let text_txt   = addComm.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            
            let urlPath = Server.SERVER + Server.SEND_COMM_CONS + "reqID=" + id_app_txt + "&text=" + text_txt + "&accID=" + self.id_account + "&isHidden=false"
            let url: NSURL = NSURL(string: urlPath)!
            let request = NSMutableURLRequest(url: url as URL)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request as URLRequest,
                                                  completionHandler: {
                                                    data, response, error in
                                                    
                                                    if error != nil {
                                                        DispatchQueue.main.async(execute: {
                                                            //                                                                self.StopIndicator()
                                                            let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                                                            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                                                            alert.addAction(cancelAction)
                                                            self.present(alert, animated: true, completion: nil)
                                                        })
                                                        return
                                                    }
                                                    
                                                    self.responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
                                                    print("responseString = \(self.responseString)")
                                                    
                                                    self.choice_send_comm(text: (addComm))
            })
            task.resume()
        }
        
        load_data()
        self.table_comments.reloadData()
    }
    
}
