//
//  DispRequestList.swift
//  Sminex
//
//  Created by Sergey Ivanov on 29/11/2018.
//

import UIKit
import DeviceKit

class DispTabView: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    
    @IBOutlet weak var barItem: UIBarButtonItem!
    @IBOutlet private weak var tableView:       UITableView!
    @IBOutlet private weak var heightTable:     NSLayoutConstraint!
    @IBOutlet private weak var widthView:     NSLayoutConstraint!
    @IBOutlet private weak var activity:        UIActivityIndicatorView?
    
    @IBOutlet weak var appsTab: UIStackView!
    @IBOutlet weak var newApps: UIButton!
    @IBOutlet weak var workApps: UIButton!
    @IBOutlet weak var newLbl: UILabel!
    @IBOutlet weak var workLbl: UILabel!
    
    var index: Int = 0
    var typeApps = false
    let title1:[String] = ["Техническое обслуживание", "Техническое обслуживание", "Техническое обслуживание"]
    let desc:[String] = ["Кошка на дереве застряла", "Соседи затопили", "Трубу прорвало"]
    let adres:[String] = ["Ул. Гагарина 39", "Ул. Пушкина 23", "Ул. Гоголя 94"]
    let date:[String] = ["29.12.2018", "01.01.2018", "19.09.2018"]

    let title2:[String] = ["Техническое обслуживание", "Техническое обслуживание", "Техническое обслуживание"]
    let desc2:[String] = ["Заявка на обслуживание", "ДВерь в подъезд не работает", "Трубу прорвало"]
    let adres2:[String] = ["Проспект Мира 78", "Ул. Пушкина 23", "Ул. Гоголя 94"]
    let date2:[String] = ["29.12.2018", "01.01.2018", "19.09.2018"]
    
    private var techService: ServiceDispHeaderData?
    private var data: [AppsDispCellData] = []
    private var refreshControl: UIRefreshControl?
    
    @IBAction private func workAppsPressed(_ sender: UIButton?) {
            
        typeApps = true
        workLbl.isHidden = false
        newLbl.isHidden = true
        workApps.titleLabel?.textColor = UIColor(red:0.00, green:0.57, blue:1.00, alpha:1.0)
        newApps.titleLabel?.textColor = .lightGray
        updateTable()
//        DispatchQueue.main.async {
//            self.stopAnimatior()
//            self.performSegue(withIdentifier: Segues.fromAppsUser.toRequestType, sender: self)
//        }
    }
    
    @IBAction private func newAppsPressed(_ sender: UIButton?) {
        
        typeApps = false
        workLbl.isHidden = true
        newLbl.isHidden = false
        workApps.titleLabel?.textColor = .lightGray
        newApps.titleLabel?.textColor = UIColor(red:0.00, green:0.57, blue:1.00, alpha:1.0)
        
        updateTable()
        //        DispatchQueue.main.async {
        //            self.stopAnimatior()
        //            self.performSegue(withIdentifier: Segues.fromAppsUser.toRequestType, sender: self)
        //        }
    }
    
    @IBAction private func dispAccPressed(_ sender: UIButton?) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 97
        tableView.rowHeight = UITableViewAutomaticDimension
        workLbl.isHidden = true
        workApps.titleLabel?.textColor = .lightGray
        newApps.titleLabel?.textColor = UIColor(red:0.00, green:0.57, blue:1.00, alpha:1.0)
        widthView.constant = view.frame.width / 2
        print(widthView.constant)
        if Device().isOneOf([.iPhone5, .iPhone5s, .iPhone5c, .iPhoneSE, .simulator(.iPhoneSE)]){
            heightTable.constant -= 100
        }
        
        let button = UIButton()
        button.setImage(UIImage(named: "dispIcon"), for: .normal)
        button.addTarget(self, action: #selector(dispAccPressed), for: .touchUpInside)
        button.cornerRadius = 15
        barItem.customView = button
        
        let width = barItem.customView?.widthAnchor.constraint(equalToConstant: 32)
        width!.isActive = true
        let height = barItem.customView?.heightAnchor.constraint(equalToConstant: 32)
        height!.isActive = true
        
        updateTable()
    }
    
    @objc private func refresh(_ sender: UIRefreshControl) {
        DispatchQueue.main.async {
            self.updateTable()
        }
    }
    
    func updateTable(){
        startAnimator()
        data.removeAll()
        for i in 0...2{
            let icon = UIImage(named: "processing_label")!
            if typeApps{
                data.append(AppsDispCellData(title: title2[i] ,
                                         desc: desc2[i] ,
                                         icon: icon,
                                         adres: adres2[i] ,
                                         date: date2[i]))
            }else{
                data.append(AppsDispCellData(title: title1[i] ,
                                         desc: desc[i] ,
                                         icon: icon,
                                         adres: adres[i] ,
                                         date: date[i]))
            }
        }
        DispatchQueue.main.async {
            self.tableView?.reloadData()
            self.stopAnimatior()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppsDispCell", for: indexPath) as! AppsDispCell
        cell.display(data[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        index = indexPath.row
        self.tappedCell()
    }
    
    func tappedCell() {
        let login1 = UserDefaults.standard.string(forKey: "login")
        let tapped = data[index]
        let ident: String = (tapped.title) as String
        if ident == "Техническое обслуживание"{
            
            self.techService = ServiceDispHeaderData(title: data[index].title, date: data[index].date, person: "Иванов Иван Иванович", phone: "+79659139567", adres: data[index].adres)
            
                if self.tableView != nil {
                    self.performSegue(withIdentifier: Segues.fromAppsUser.toServiceDisp, sender: self)
                }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromAppsUser.toServiceDisp {
            let vc = segue.destination as! TechServiceDispVC
            vc.data_ = techService!
        }
    }
    
    private func startAnimator() {
        
        activity?.isHidden       = false
        
        activity?.startAnimating()
    }
    
    private func stopAnimatior() {
        
        activity?.stopAnimating()
        
        activity?.isHidden       = true
    }
    
    func update() {
//        self.createButton?.isHidden = true
//        DispatchQueue.main.async {
//            self.delegate?.update(method: "Request")
//            self.getRequests()
//        }
    }
}

final class AppsDispCell: UITableViewCell {
    
    @IBOutlet private weak var skTitleHeight: NSLayoutConstraint!
    @IBOutlet private weak var skTitleBottm: NSLayoutConstraint!
    @IBOutlet private weak var icon:            UIImageView!
    @IBOutlet private weak var title:           UILabel!
    @IBOutlet private weak var desc:            UILabel!
    @IBOutlet private weak var adres:           UILabel!
    @IBOutlet private weak var date:            UILabel!
    @IBOutlet private weak var back:            UIView!
    
    private var type: String?
    
    fileprivate func display(_ item: AppsDispCellData) {
        
        desc.text   = item.desc
        icon.image      = item.icon
        adres.text     = item.adres
        
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy hh:mm:ss"
        df.isLenient = true
        date.text = dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM").contains(find: "Сегодня")
            ? dayDifference(from: df.date(from: item.date) ?? Date(), style: "hh:mm")
            : dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM")
        
        title.text = item.title
        back.isHidden = false
    }
}

private final class AppsDispCellData {
    
    let icon:       UIImage
    let title:      String
    let desc:       String
    let adres:     String
    let date:       String
    
    init(title: String, desc: String, icon: UIImage, adres: String, date: String) {
        
        self.title      = title
        self.desc       = desc
        self.icon       = icon
        self.adres      = adres
        self.date       = date
    }
}
