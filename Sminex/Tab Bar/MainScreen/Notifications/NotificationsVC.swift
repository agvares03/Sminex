//
//  NotificationsVC.swift
//  Sminex
//
//  Created by Роман Тузин on 01/08/2019.
//

import UIKit

class NotificationsVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PushListCell", for: indexPath) as! DealsListCell
        return cell
    }
    
    
    @IBOutlet weak var loader: UIActivityIndicatorView!
    @IBOutlet weak var collection: UICollectionView!
    
    @IBAction func BackPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUserInterface()
        
        automaticallyAdjustsScrollViewInsets = false
        
        collection.delegate     = self
        collection.dataSource   = self
        
        stopAnimator()
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключение к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.viewDidLoad()
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        case .wifi: break
            
        case .wwan: break
            
        }
    }
    
    private func startAnimator() {
        collection.alpha = 0
        loader.isHidden = false
        loader.startAnimating()
    }

    private func stopAnimator() {
        collection.alpha = 1
        loader.isHidden = true
        loader.stopAnimating()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
