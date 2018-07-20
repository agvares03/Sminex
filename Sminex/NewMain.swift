//
//  NewMain.swift
//  Sminex
//
//  Created by Роман Тузин on 26.06.2018.
//  Copyright © 2018 The Best. All rights reserved.
//

import Foundation

class NewMain: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var heigth_collection_Questions: NSLayoutConstraint!
    @IBOutlet weak var heigth_Questions: NSLayoutConstraint!
    
    var items = ["1", "2", "3", "4"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = (UserDefaults.standard.string(forKey: "buisness") ?? "") + " by SMINEX"

    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        heigth_collection_Questions.constant = CGFloat(95 * self.items.count + 40)
        heigth_Questions.constant = CGFloat(heigth_collection_Questions.constant + 80)
        
        return self.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell_question", for: indexPath as IndexPath) as! QuestionCell
        
//        // Use the outlet in our custom class to get a reference to the UILabel in the cell
//        cell.myLabel.text = self.items[indexPath.item]
        cell.backgroundColor = UIColor.cyan // make cell more visible in our example project
        
        return cell
    }
    
    
    
    
}
