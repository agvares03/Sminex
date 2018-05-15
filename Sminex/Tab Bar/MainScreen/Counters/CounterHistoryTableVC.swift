//
//  CounterHistoryTableVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/29/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class CounterHistoryTableVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    open var data_: [MeterValue] = []
    open var period_: [CounterPeriod]?
    
    private var row = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        tabBarController?.tabBar.selectedItem?.title = "Главная"
        collection.delegate   = self
        collection.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        tabBarController?.tabBar.selectedItem?.title = "Главная"
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data_.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CounterHistoryTableCell", for: indexPath) as! CounterHistoryTableCell
        cell.display(title: data_[indexPath.row].resource ?? "", desc: data_[indexPath.row].meterUniqueNum ?? "")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        row = indexPath.row
        performSegue(withIdentifier: Segues.fromCounterHistoryTableVC.toHistory, sender: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 60.0)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromCounterHistoryTableVC.toHistory {
            let vc = segue.destination as! CounterHistoryVC
            vc.data_ = data_[row]
            vc.period_ = period_
        }
    }
}


final class CounterHistoryTableCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    
    func display(title: String, desc: String) {
        
        self.title.text = title
        self.desc.text  = desc
    }
    
}
