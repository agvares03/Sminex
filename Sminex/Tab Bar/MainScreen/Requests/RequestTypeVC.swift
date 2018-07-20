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
        
        let AppsUserDelegate = self.delegate as! AppsUser
        
        if (AppsUserDelegate.isCreatingRequest_) {
            navigationController?.popToRootViewController(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    open var delegate: AppsUserDelegate?
    
    private var typeName = ""
    private var data = TemporaryHolder.instance.requestTypes?.types
    private var index = 0
    
    var flag: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        flag = false
        
        automaticallyAdjustsScrollViewInsets = false
        
        collection.delegate  = self
        collection.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = false
        
        flag = false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Исключим многократное касание
        if self.flag { return }
        self.flag = true
        
        let name = data![indexPath.row].name
        
        if  (name?.contains(find: "ропуск"))! {
            typeName = name ?? ""
            index = indexPath.row
            performSegue(withIdentifier: Segues.fromRequestTypeVC.toCreateAdmission, sender: self)
        
        } else if name == "Техническое обслуживание" {
            index = indexPath.row
            performSegue(withIdentifier: Segues.fromRequestTypeVC.toCreateServive, sender: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 60.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestTypeCell", for: indexPath) as! RequestTypeCell
        cell.display(data![indexPath.row])
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromRequestTypeVC.toCreateAdmission {
            let vc = segue.destination as! CreateRequestVC
            vc.delegate = delegate
            vc.name_ = typeName
            vc.type_ = data![index]
        
        } else if segue.identifier == Segues.fromRequestTypeVC.toCreateServive {
            let vc = segue.destination as! CreateTechServiceVC
            vc.delegate = delegate
            vc.type_ = data![index]
        }
    }
}

final class RequestTypeCell: UICollectionViewCell {
    
    @IBOutlet private weak var title: UILabel!
    
    func display(_ item: RequestTypeStruct) {
        
        title.text = item.name
    }
}
