//
//  CustomAlertViewController.swift
//  Sminex
//
//  Created by Sergey Ivanov on 07.09.2018.
//  Copyright © 2018 Anton Barbyshev. All rights reserved.
//

import UIKit
import Gloss
import DeviceKit

class CustomAlertViewController: UIViewController {
    private var data: [AllLSJson] = []
    open var tapped: AllLSJson?
    private var index = 0
    var edLoginText = String()
    var edPassText = String()

    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var viewConst: NSLayoutConstraint!
    @IBOutlet weak var tableConst: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func addLSBtnPressed(_ sender: UIButton) {
    }
    @IBAction func cancelBtnPressed(_ sender: UIButton) {
        self.removeFromParentViewController()
        self.view.removeFromSuperview()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(tapGestureRecognizer:)))
//        self.view.isUserInteractionEnabled = true
//        self.view.addGestureRecognizer(tapGestureRecognizer)
        if tapped != nil {
            performSegue(withIdentifier: Segues.fromNewsList.toNews, sender: self)
        }
        getAllLS()
    }
    
    @objc func viewTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        let tappedView = tapGestureRecognizer.view as! UIView
        self.removeFromParentViewController()
        self.view.removeFromSuperview()
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "newLS" {
//            let regVC = segue.destination as! AddLS
//            regVC.isNew = true
//        }
//    }
    
    func tappedCell() {
        let login1 = UserDefaults.standard.string(forKey: "login")
        tapped = data[index]
        let ident: String = (tapped?.ident)! as String
        if login1 != ident{
            let alert = UIAlertController(title: "Авторизация", message: "Введите пароль для \(ident)", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.text = ""
                textField.placeholder = "Пароль"
            }
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) -> Void in}))
            alert.addAction(UIAlertAction(title: "Войти", style: .default, handler: { (_) -> Void in
                let password = alert.textFields![0]
                self.edLoginText = ident
                self.edPassText = password.text!
                print(self.edLoginText, self.edPassText)
                self.exit()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func getAllLS(login: String? = nil, pass: String? = nil){
        TemporaryHolder.instance.allLS.removeAll()
        let login1 = UserDefaults.standard.string(forKey: "login")
        let pwd = UserDefaults.standard.string(forKey: "pass")
        let txtLogin = login == nil ? login1?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? "" : login?.stringByAddingPercentEncodingForRFC3986() ?? ""
        let txtPass = pass == nil ? pwd?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? "" : pass ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_ALL_ACCOUNTS + "login=" + txtLogin + "&pwd=" + getHash(pass: txtPass, salt: (login == nil ? getSalt() : Sminex.getSalt())))!)
        request.httpMethod = "GET"
        print(request)
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            let responseString = String(data: data!, encoding: .utf8) ?? ""
            
            #if DEBUG
            print("responseString = \(responseString)")
            #endif
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                if let lsArr = AllLSJsonData(json: json!)?.data {
                    if lsArr.count != 0 {
                        TemporaryHolder.instance.allLS.append(contentsOf: lsArr)
                        self.data = TemporaryHolder.instance.allLS
                        DispatchQueue.main.sync {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
            }.resume()
    }
    
    private func exit() {
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt())
        let deviceId = UserDefaults.standard.string(forKey: "googleToken") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.DELETE_CLIENT + "login=\(login)&pwd=\(pwd)&deviceid=\(deviceId)")!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else { return }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
            #if DEBUG
            //                print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            
            }.resume()
        
        UserDefaults.standard.setValue(UserDefaults.standard.string(forKey: "pass"), forKey: "exitPass")
        UserDefaults.standard.setValue(UserDefaults.standard.string(forKey: "login"), forKey: "exitLogin")
        UserDefaults.standard.setValue("", forKey: "pass")
        UserDefaults.standard.removeObject(forKey: "accountIcon")
        UserDefaults.standard.removeObject(forKey: "googleToken")
        UserDefaults.standard.removeObject(forKey: "newsList")
        UserDefaults.standard.removeObject(forKey: "DealsImg")
        UserDefaults.standard.removeObject(forKey: "newsList")
        UserDefaults.standard.removeObject(forKey: "newsLastId")
        UserDefaults.standard.synchronize()
        TemporaryHolder.instance.log = self.edLoginText
        TemporaryHolder.instance.pas = self.edPassText
        present(UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!, animated: true, completion: nil)
    }
}

extension CustomAlertViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) || Device() == .iPhone5s || Device() == .simulator(.iPhone5s) || Device() == .iPhone5 || Device() == .simulator(.iPhone5) || Device() == .iPhone5c || Device() == .simulator(.iPhone5c) || Device() == .simulator(.iPhone5) || Device() == .iPhone4 || Device() == .simulator(.iPhone4) || Device() == .simulator(.iPhone4s) || Device() == .iPhone5c || Device() == .simulator(.iPhone4s){
            if data.count == 0{
                self.tableView.isHidden = true
                self.backView.isHidden = true
            }else if data.count == 1{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 110 + 5
                self.tableConst.constant = 110
            }else if data.count == 2{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 41 + 5
                self.tableConst.constant = 41
            }else if data.count >= 3{
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }
        }else if Device() == .iPhoneX || Device() == .simulator(.iPhoneX){
            if data.count == 0{
                self.tableView.isHidden = true
                self.backView.isHidden = true
            }else if data.count == 1{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 207 + 87 + 5
                self.tableConst.constant = 207 + 87
            }else if data.count == 2{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 138 + 87 + 5
                self.tableConst.constant = 138 + 87
            }else if data.count == 3{
                self.viewConst.constant = 69 + 87 + 5
                self.tableConst.constant = 69 + 87
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }else if data.count >= 4{
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }
        }else if Device() == .iPhone7Plus || Device() == .simulator(.iPhone7Plus) || Device() == .iPhone8Plus || Device() == .simulator(.iPhone8Plus) || Device() == .iPhone6Plus || Device() == .simulator(.iPhone6Plus) || Device() == .iPhone6sPlus || Device() == .simulator(.iPhone6sPlus){
            if data.count == 0{
                self.tableView.isHidden = true
                self.backView.isHidden = true
            }else if data.count == 1{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 207 + 69 + 5
                self.tableConst.constant = 207 + 69
            }else if data.count == 2{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.tableConst.constant = 138 + 69
                self.viewConst.constant = 138 + 69 + 5
            }else if data.count == 3{
                self.tableConst.constant = 69 + 69
                self.viewConst.constant = 69 + 69 + 5
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }else if data.count == 4{
                self.tableConst.constant = 69
                self.viewConst.constant = 69 + 5
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }else if data.count >= 4{
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }
        }else{
            if data.count == 0{
                self.tableView.isHidden = true
                self.backView.isHidden = true
            }else if data.count == 1{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 207 + 5
                self.tableConst.constant = 207
            }else if data.count == 2{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 138 + 5
                self.tableConst.constant = 138
            }else if data.count == 3{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 69 + 5
                self.tableConst.constant = 69
            }else if data.count >= 4{
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }
        }
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AllLsTableCell", for: indexPath) as! AllLsTableCell
        let news = data[indexPath.row]
        cell.configure(item: news)
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        index = indexPath.row
        self.tappedCell()
    }
    
}

class AllLsTableCell: UITableViewCell {
    
    // MARK: Outlets
    
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var desc: UILabel!
    @IBOutlet private var checkImg: UIImageView!
    
    func configure(item: AllLSJson?) {
        checkImg.isHidden = true
        let login = UserDefaults.standard.string(forKey: "login")
        guard let item = item else { return }
        
        title.text = item.ident
        desc.text = item.address
        
        if item.ident == login {
            checkImg.isHidden = false
        }
    }
    
}

struct AllLSJsonData: JSONDecodable {
    
    let data: [AllLSJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

final class AllLSJson: NSObject, JSONDecodable, NSCoding {
    
    let address:       String?
    let ident:        String?
    
    init(json: JSON) {
        address    = "Address"  <~~ json
        ident        = "Ident"    <~~ json
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(address, forKey: "Address")
        aCoder.encode(ident, forKey: "Ident")
    }
    
    required init?(coder aDecoder: NSCoder) {
        address       = aDecoder.decodeObject(forKey: "address")      as? String
        ident        = aDecoder.decodeObject(forKey: "ident")       as? String
    }
}
//{"data":["1172","2688","2732","2745","2746"]}
//{"data":[{"Ident":"1478","Address":"-"},{"Ident":"2740","Address":""},{"Ident":"2744","Address":""},{"Ident":"2742","Address":""}]}
