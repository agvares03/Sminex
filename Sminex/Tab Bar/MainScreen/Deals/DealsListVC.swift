//
//  DealsListVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/10/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss

final class DealsListVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var collection:  UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    open var data_: [DealsJson] = []
    private var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collection.delegate     = self
        collection.dataSource   = self
        
        if data_.count == 0 {
            startAnimator()
            getDeals()
        
        } else {
            stopAnimator()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data_.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 250.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DealsListCell", for: indexPath) as! DealsListCell
        cell.display(data_[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        index = indexPath.row
        performSegue(withIdentifier: Segues.fromDealsListVC.toDealsDesc, sender: self)
    }
    
    private final func getDeals() {
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.PROPOSALS + "ident=\(UserDefaults.standard.string(forKey: "login") ?? "")")!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.async {
                    self.collection.reloadData()
                    self.stopAnimator()
                }
            }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.data_ = (DealsDataJson(json: try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! JSON)?.data)!
            
            #if DEBUG
//                print(String(data: data!, encoding: .utf8) ?? "")
            #endif
        
        }.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromDealsListVC.toDealsDesc {
            let vc = segue.destination as! DealsListDescVC
            vc.data_ = data_[index]
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
}

final class DealsListCell: UICollectionViewCell {
    
    @IBOutlet private weak var image:   UIImageView!
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    
    fileprivate func display(_ item: DealsJson) {
        
        image.image         = item.img
        title.text          = item.name
        desc.text           = item.desc
    }
}

struct DealsDataJson: JSONDecodable {
    
    let data: [DealsJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

struct DealsJson: JSONDecodable {
    
    let img:        UIImage?
    let picture:    String?
    let dateStop:   String?
    let dateStart:  String?
    let priority:   String?
    let name: 	    String?
    let desc: 	    String?
    let body:       String?
    let link:       String?
    let delay:      Int?
    let id:         Int?
    
    init?(json: JSON) {
        
        picture     = "Picture"     <~~ json
        dateStop    = "DateStop"    <~~ json
        dateStart   = "DateStart"   <~~ json
        priority    = "Priority"    <~~ json
        name        = "Name"        <~~ json
        desc        = "Description" <~~ json
        body        = "Body"        <~~ json
        link        = "Link"        <~~ json
        delay       = "Delay"       <~~ json
        id          = "ID"          <~~ json
        img         = UIImage(data: Data(base64Encoded: (picture?.replacingOccurrences(of: "data:image/png;base64,", with: ""))!)!)
    }
    
}











