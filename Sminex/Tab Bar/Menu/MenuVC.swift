//
//  MenuVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/23/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class MenuVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var collection: UICollectionView!
    
    private var data =
        [
            MenuCellData(icon: UIImage(named: "menu_finance")!, title: "Финансы", notification: ""),
            MenuCellData(icon: UIImage(named: "menu_meters")!, title: "Показания счетчиков", notification: ""),
            MenuCellData(icon: UIImage(named: "menu_request")!, title: "Заявки", notification: TemporaryHolder.instance.menuRequests == 0 ? "" : "\(TemporaryHolder.instance.menuRequests)"),
            MenuCellData(icon: UIImage(named: "menu_services")!, title: "Услуги Службы комфорта", notification: ""),
            MenuCellData(icon: UIImage(named: "menu_news")!, title: "Новости", notification: ""),
            MenuCellData(icon: UIImage(named: "menu_polls")!, title: "Опросы", notification: TemporaryHolder.instance.menuQuesions == 0 ? "" : "\(TemporaryHolder.instance.menuQuesions)"),
            MenuCellData(icon: UIImage(named: "menu_sales")!, title: "Акции и предложения", notification: TemporaryHolder.instance.menuDeals == 0 ? "" : "\(TemporaryHolder.instance.menuDeals)"),
            MenuCellData(icon: UIImage(named: "menu_support")!, title: "Техподдержка приложения", notification: ""),
            MenuCellData(icon: UIImage(named: "menu_share")!, title: "Поделиться приложением", notification: "")
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        collection.dataSource = self
        collection.delegate   = self
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("DealsMenu"), object: nil, queue: nil) { (_) in
            if TemporaryHolder.instance.menuDeals != 0 {
                self.data[6] = MenuCellData(icon: UIImage(named: "menu_sales")!, title: "Акции и предложения", notification: "\(TemporaryHolder.instance.menuDeals)")
                DispatchQueue.main.async {
                    self.collection.reloadData()
                }
            }
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RequestsMenu"), object: nil, queue: nil) { (_) in
            if TemporaryHolder.instance.menuRequests != 0 {
                self.data[2] = MenuCellData(icon: UIImage(named: "menu_request")!, title: "Заявки", notification: "\(TemporaryHolder.instance.menuRequests)")
                DispatchQueue.main.async {
                    self.collection.reloadData()
                }
            }
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("QuestionsMenu"), object: nil, queue: nil) { (_) in
            if TemporaryHolder.instance.menuQuesions != 0 {
                self.data[5] = MenuCellData(icon: UIImage(named: "menu_polls")!, title: "Опросы", notification: "\(TemporaryHolder.instance.menuQuesions)")
                DispatchQueue.main.async {
                    self.collection.reloadData()
                }
            }
        }
        
        // Поправим Navigation bar
        navigationController?.navigationBar.isTranslucent   = true
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.tintColor       = .white
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16, weight: .bold) ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
        if TemporaryHolder.instance.menuDeals != 0 {
            self.data[6] = MenuCellData(icon: UIImage(named: "menu_sales")!, title: "Акции и предложения", notification: "\(TemporaryHolder.instance.menuDeals)")
            self.collection.reloadData()
        }
        if TemporaryHolder.instance.menuRequests != 0 {
            self.data[2] = MenuCellData(icon: UIImage(named: "menu_request")!, title: "Заявки", notification: "\(TemporaryHolder.instance.menuRequests)")
            self.collection.reloadData()
        }
        if TemporaryHolder.instance.menuQuesions != 0 {
            self.data[5] = MenuCellData(icon: UIImage(named: "menu_polls")!, title: "Опросы", notification: "\(TemporaryHolder.instance.menuQuesions)")
            self.collection.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 || section == 1 {
            return 2
        
        } else if section == 2 {
            return 3
        
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
            header.display("Быстрый доступ")
        
        } else {
            header.display("")
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MenuCell", for: indexPath) as! MenuCell
        let section = indexPath.section
        if section == 0 {
            cell.display(data[indexPath.row])
        
        } else if section == 1 {
            cell.display(data[indexPath.row + 2])
        
        } else if section == 2 {
            cell.display(data[indexPath.row + 4])
        
        } else if section == 3 {
            cell.display(data[indexPath.row + 7])
        
        } else {
            cell.display(data[indexPath.row + 8])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: view.frame.size.width, height: 100.0)
        
        } else {
            return CGSize(width: view.frame.size.width, height: 25.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                performSegue(withIdentifier: Segues.fromMenuVC.toFinance, sender: self)
            
            } else if indexPath.row == 1 {
                performSegue(withIdentifier: Segues.fromMenuVC.toSchet, sender: self)
            
            }
        
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                performSegue(withIdentifier: Segues.fromMenuVC.toRequest, sender: self)
            
            } else if indexPath.row == 1 {
                // TODO
            }
        
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                if TemporaryHolder.instance.news != nil {
                    performSegue(withIdentifier: Segues.fromMenuVC.toNews, sender: self)
                }
            
            } else if indexPath.row == 1 {
                performSegue(withIdentifier: Segues.fromMenuVC.toQuestions, sender: self)
            
            } else if indexPath.row == 2 {
                performSegue(withIdentifier: Segues.fromMenuVC.toDeals, sender: self)
            }
        
        } else if indexPath.section == 3 {
            // TODO
        
        } else if indexPath.section == 4 {
            // TODO
        }
    }
}

final class MenuHeader: UICollectionReusableView {
    
    @IBOutlet private weak var title: UILabel!
    
    func display(_ title: String) {
        self.title.text = title
    }
}

final class MenuCell: UICollectionViewCell {
    
    @IBOutlet private weak var icon:             UIImageView!
    @IBOutlet private weak var notification:     UILabel!
    @IBOutlet private weak var title:            UILabel!
    @IBOutlet private weak var notificationView: UIView!
    
    func display(_ item: MenuCellData) {
        title.text = item.title
        icon.image = item.icon
        
        if item.notification != "" {
            notification.text = item.notification
            notificationView.isHidden = false
        
        } else {
            notificationView.isHidden = true
        }
    }
}

struct MenuCellData {
    
    let icon:           UIImage
    let title:          String
    let notification:   String
}










