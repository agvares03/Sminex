//
//  RequestTypeVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/23/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class RequestTypeVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    var data = TemporaryHolder.instance.requestTypes?.types
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        
        #if DEBUG
            data?.append(RequestTypeStruct(id: "54254132", name: "Пропуск"))
        #endif
        
        collection.delegate  = self
        collection.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let name = data![indexPath.row].name
        
        if  name == "Пропуск" {
            performSegue(withIdentifier: Segues.fromRequestTypeVC.toCreateAdmission, sender: self)
        
        } else if name == "Техническое обслуживание" {
            performSegue(withIdentifier: Segues.fromRequestTypeVC.toCreateServive, sender: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 50.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestTypeCell", for: indexPath) as! RequestTypeCell
        cell.display(data![indexPath.row])
        return cell
    }
}

final class RequestTypeCell: UICollectionViewCell {
    
    @IBOutlet private weak var title: UILabel!
    
    func display(_ item: RequestTypeStruct) {
        
        title.text = item.name
    }
}
