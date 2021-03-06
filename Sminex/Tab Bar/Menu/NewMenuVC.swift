//
//  NewMenuVC.swift
//  Sminex
//
//  Created by Sergey Ivanov on 27/02/2020.
//

import UIKit

class NewMenuVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var collection: UICollectionView!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    private var data =
        [
            MenuCellData(icon: UIImage(named: "new_menu_finance")!, title: "Финансы", notification: ""),
            MenuCellData(icon: UIImage(named: "new_menu_meters")!, title: "Показания счетчиков", notification: ""),
            MenuCellData(icon: UIImage(named: "new_menu_request")!, title: "Заявки", notification: TemporaryHolder.instance.menuRequests == 0 ? "" : "\(TemporaryHolder.instance.menuRequests)"),
            MenuCellData(icon: UIImage(named: "new_menu_appeal")!, title: "Обращения", notification: ""),
            MenuCellData(icon: UIImage(named: "new_menu_services")!, title: "Каталог услуг", notification: ""),
            MenuCellData(icon: UIImage(named: "new_menu_news")!, title: "Новости", notification: ""),
            MenuCellData(icon: UIImage(named: "new_menu_polls")!, title: "Опросы", notification: TemporaryHolder.instance.menuQuesions == 0 ? "" : "\(TemporaryHolder.instance.menuQuesions)"),
            MenuCellData(icon: UIImage(named: "new_menu_sales")!, title: "Акции и предложения", notification: TemporaryHolder.instance.menuDeals == 0 ? "" : "\(TemporaryHolder.instance.menuDeals)"),
            MenuCellData(icon: UIImage(named: "new_menu_notifications")!, title: "Уведомления", notification: TemporaryHolder.instance.menuNotifications == 0 ? "" : "\(TemporaryHolder.instance.menuNotifications)"),
//            MenuCellData(icon: UIImage(named: "menu_finance")!, title: "Уведомления", notification: ""),
            MenuCellData(icon: UIImage(named: "new_menu_support")!, title: "Техподдержка приложения", notification: ""),
            MenuCellData(icon: UIImage(named: "new_menu_share")!, title: "Поделиться приложением", notification: "")
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barStyle = .black
        updateUserInterface()
        automaticallyAdjustsScrollViewInsets = false
        collection.dataSource = self
        collection.delegate   = self
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("DealsMenu"), object: nil, queue: nil) { (_) in
            if TemporaryHolder.instance.menuDeals > 0 {
                if TemporaryHolder.instance.menuDeals > 99{
                    self.data[7] = MenuCellData(icon: UIImage(named: "new_menu_sales")!, title: "Акции и предложения", notification: "99+")
                }else{
                    self.data[7] = MenuCellData(icon: UIImage(named: "new_menu_sales")!, title: "Акции и предложения", notification: "\(TemporaryHolder.instance.menuDeals)")
                }
                DispatchQueue.main.async {
                    self.collection.reloadData()
                }
            }
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RequestsMenu"), object: nil, queue: nil) { (_) in
            if TemporaryHolder.instance.menuRequests > 0 {
                if TemporaryHolder.instance.menuRequests > 99{
                    self.data[2] = MenuCellData(icon: UIImage(named: "new_menu_request")!, title: "Заявки", notification: "99+")
                }else{
                    self.data[2] = MenuCellData(icon: UIImage(named: "new_menu_request")!, title: "Заявки", notification: "\(TemporaryHolder.instance.menuRequests)")
                }
                DispatchQueue.main.async {
                    self.collection.reloadData()
                }
            }
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("QuestionsMenu"), object: nil, queue: nil) { (_) in
            if TemporaryHolder.instance.menuQuesions > 0 {
                if TemporaryHolder.instance.menuQuesions > 99{
                    self.data[6] = MenuCellData(icon: UIImage(named: "new_menu_polls")!, title: "Опросы", notification: "99+")
                }else{
                    self.data[6] = MenuCellData(icon: UIImage(named: "new_menu_polls")!, title: "Опросы", notification: "\(TemporaryHolder.instance.menuQuesions)")
                }
                DispatchQueue.main.async {
                    self.collection.reloadData()
                }
            }
        }
        
        // Поправим Navigation bar
        navigationController?.navigationBar.isTranslucent   = true
//        navigationController?.navigationBar.backgroundColor = .white
//        navigationController?.navigationBar.tintColor       = .white
//        navigationController?.navigationBar.barTintColor          = .white
        //navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16, weight: .bold) ]
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключенние к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.viewDidLoad()
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        case .wifi: break
            
        case .wwan: break
            
        }
    }
    @objc func statusManager(_ notification: Notification) {
        updateUserInterface()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
//        self.navigationController?.isNavigationBarHidden = true
        notifiPressed = false
        if TemporaryHolder.instance.menuDeals > 0 {
            if TemporaryHolder.instance.menuDeals > 99{
                self.data[7] = MenuCellData(icon: UIImage(named: "new_menu_sales")!, title: "Акции и предложения", notification: "99+")
            }else{
                self.data[7] = MenuCellData(icon: UIImage(named: "new_menu_sales")!, title: "Акции и предложения", notification: "\(TemporaryHolder.instance.menuDeals)")
            }
            self.collection.reloadData()
        }else{
            self.data[7] = MenuCellData(icon: UIImage(named: "new_menu_sales")!, title: "Акции и предложения", notification: "")
            self.collection.reloadData()
        }
        if TemporaryHolder.instance.menuNotifications > 0 {
            notifiBtn.image = UIImage(named: "new_notifi1")!
            if TemporaryHolder.instance.menuNotifications > 99{
                self.data[8] = MenuCellData(icon: UIImage(named: "new_menu_notifications")!, title: "Уведомления", notification: "99+")
            }else{
                self.data[8] = MenuCellData(icon: UIImage(named: "new_menu_notifications")!, title: "Уведомления", notification: "\(TemporaryHolder.instance.menuNotifications)")
            }
            self.collection.reloadData()
        }else{
            notifiBtn.image = UIImage(named: "new_notifi0")!
            self.data[8] = MenuCellData(icon: UIImage(named: "new_menu_notifications")!, title: "Уведомления", notification: "")
            self.collection.reloadData()
        }
        if TemporaryHolder.instance.menuRequests > 0 {
            if TemporaryHolder.instance.menuRequests > 99{
                self.data[2] = MenuCellData(icon: UIImage(named: "new_menu_request")!, title: "Заявки", notification: "99+")
            }else{
                self.data[2] = MenuCellData(icon: UIImage(named: "new_menu_request")!, title: "Заявки", notification: "\(TemporaryHolder.instance.menuRequests)")
            }
            self.collection.reloadData()
        }else{
            self.data[2] = MenuCellData(icon: UIImage(named: "new_menu_request")!, title: "Заявки", notification: "")
            self.collection.reloadData()
        }
        if TemporaryHolder.instance.menuQuesions > 0 {
            if TemporaryHolder.instance.menuQuesions > 99{
                self.data[6] = MenuCellData(icon: UIImage(named: "new_menu_polls")!, title: "Опросы", notification: "99+")
            }else{
                self.data[6] = MenuCellData(icon: UIImage(named: "new_menu_polls")!, title: "Опросы", notification: "\(TemporaryHolder.instance.menuQuesions)")
            }
            self.collection.reloadData()
        }else{
            self.data[6] = MenuCellData(icon: UIImage(named: "new_menu_polls")!, title: "Опросы", notification: "")
            self.collection.reloadData()
        }
        navigationController?.isNavigationBarHidden = false
        tabBarController?.tabBar.tintColor = mainGreenColor
        tabBarController?.tabBar.selectedItem?.title = "Меню"
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
//        self.navigationController?.isNavigationBarHidden = false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        
        } else if section == 1{
            return 3
        } else if section == 2{
            return 4
        } else {
            return 1
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "MenuHeader", for: indexPath) as! MenuHeader
        if indexPath.section == 0 {
            header.display("")
            header.backgroundColor = mainBeigeColor
        } else {
            header.display("")
            header.backgroundColor = mainBeigeColor
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MenuCell", for: indexPath) as! MenuCell
        let section = indexPath.section
        if section == 0 {
            cell.display(data[indexPath.row])
            cell.backgroundColor = .white
        } else if section == 1 {
            cell.display(data[indexPath.row + 2])
            cell.backgroundColor = .white
        } else if section == 2 {
            cell.display(data[indexPath.row + 5])
            cell.backgroundColor = .white
        } else if section == 3 {
            cell.display(data[indexPath.row + 9])
            cell.backgroundColor = mainBeigeColor
        } else {
            cell.display(data[indexPath.row + 10])
            cell.backgroundColor = mainBeigeColor
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 60.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: view.frame.size.width, height: 8)
        } else if section == 4 {
            return CGSize(width: view.frame.size.width, height: 6)
        } else {
            return CGSize(width: view.frame.size.width, height: 8)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
//                if UserDefaults.standard.string(forKey: "typeBuilding") != "commercial"{
                    performSegue(withIdentifier: Segues.fromMainScreenVC.toFinanceComm, sender: self)
//                }else{
//                    performSegue(withIdentifier: Segues.fromMainScreenVC.toFinance, sender: self)
//                }
            } else if indexPath.row == 1 {
                performSegue(withIdentifier: Segues.fromMenuVC.toSchet, sender: self)
            
            }
        
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                performSegue(withIdentifier: Segues.fromMenuVC.toRequest, sender: self)
            } else if indexPath.row == 1 {
                performSegue(withIdentifier: Segues.fromMenuVC.toAppeal, sender: self)
            } else if indexPath.row == 2 {
                performSegue(withIdentifier: Segues.fromMenuVC.toServicesUK, sender: self)
            }
        
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                if TemporaryHolder.instance.newsNew != nil {
                    performSegue(withIdentifier: Segues.fromMenuVC.toNews, sender: self)
                }
            
            } else if indexPath.row == 1 {
                performSegue(withIdentifier: Segues.fromMenuVC.toQuestions, sender: self)
            
            } else if indexPath.row == 2 {
                performSegue(withIdentifier: Segues.fromMenuVC.toDeals, sender: self)
            } else if indexPath.row == 3 {
                performSegue(withIdentifier: Segues.fromMenuVC.toNotification, sender: self)
            }
        
        } else if indexPath.section == 3 {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction( UIAlertAction(title: "Позвонить", style: .default, handler: { (_) in
                if let url = URL(string: "tel://+74957266791") {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
                } } ) )
            alert.addAction( UIAlertAction(title: "Написать письмо", style: .default, handler: { (_) in
//                self.performSegue(withIdentifier: Segues.fromMenuVC.toSupport, sender: self)
//                UserDefaults.standard.set(true, forKey: "fromMenu")
                self.addRequestPressed()
            } ) )
            alert.addAction( UIAlertAction(title: "Отменить", style: .cancel, handler: { (_) in } ) )
            present(alert, animated: true, completion: nil)
        
        } else if indexPath.section == 4 {
            let url: URL = URL(string:"https://itunes.apple.com/ru/app/sminex-comfort/id1350615149?mt=8")!
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    func addRequestPressed() {
        DispatchQueue.global(qos: .userInteractive).async {
            if let types = TemporaryHolder.instance.requestTypes?.types {
                for i in 0...types.count - 1{
                    if types[i].name == "Обращение"{
                        self.typeName = types[i].name!
                    }
                }
                self.dataType = types
            }
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "addAppeal", sender: self)
            }
        }
    }
    var typeName = ""
    private var dataType = [RequestTypeStruct]()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addAppeal"{
            let vc = segue.destination as! CreateAppeal
            vc.typeReq = "В техподдержку приложения"
            let dat = TemporaryHolder.instance.contactsList
            var selEmail = ""
            dat.forEach{
                if ($0.name?.contains(find: "оддержка"))!{
                    selEmail = $0.email ?? ""
                }
            }
            vc.selEmail = selEmail
            vc.name_ = typeName
            vc.fromMenu = true
            for i in 0...dataType.count - 1{
                if dataType[i].name == "Обращение"{
                    vc.type_ = dataType[i]
                }
            }
        }
        if segue.identifier == Segues.fromMenuVC.toSupport {
            let vc = segue.destination as! AuthSupportVCNew
            vc.login_ = UserDefaults.standard.string(forKey: "login") ?? ""
            vc.fromMenu = true
        }
    }
}
