//
//  DispRequestList.swift
//  Sminex
//
//  Created by Sergey Ivanov on 29/11/2018.
//

import UIKit

class TableWorker: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    
    @IBOutlet private weak var tableView:       UITableView!
    @IBOutlet private weak var activity:        UIActivityIndicatorView?
    
    @IBOutlet weak var appsTab: UIStackView!
    @IBOutlet weak var newApps: UIButton!
    @IBOutlet weak var workApps: UIButton!
    @IBOutlet weak var newLbl: UILabel!
    @IBOutlet weak var workLbl: UILabel!
    
    var index: Int = 0
    var typeApps = false
    let title1:[String] = ["Жанна Николаевна", "Антон Петров", "Владимир Константинов"]
    let desc:[String] = ["Диспетчер", "Сантехник", "Электрик"]
    
    private var techService: ServiceDispHeaderData?
    private var worker: ServiceWorkerCellData?
    private var data: [WorkerCellData] = []
    private var refreshControl: UIRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 74
        tableView.rowHeight = UITableViewAutomaticDimension
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
            let icon = UIImage(named: "account")!
            data.append(WorkerCellData(title: title1[i] ,
                                         desc: desc[i] ,
                                         icon: icon, id: i + 1))
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "WorkerCell", for: indexPath) as! WorkerCell
        cell.display(data[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        index = indexPath.row
        self.tappedCell()
    }
    
    func tappedCell() {
        self.worker = ServiceWorkerCellData(icon: data[index].icon, title: data[index].title, desc: data[index].desc, id: data[index].id)
        
//        if self.tableView != nil {
//            self.performSegue(withIdentifier: Segues.fromAppsUser.toServiceDisp, sender: self)
//        }
        TemporaryHolder.instance.worker = self.worker
        navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromAppsUser.toServiceDisp {
            let vc = segue.destination as! TechServiceDispVC
            vc.worker.append(worker!)
            navigationController?.popViewController(animated: true)
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

final class WorkerCell: UITableViewCell {
    
    @IBOutlet private weak var skTitleHeight: NSLayoutConstraint!
    @IBOutlet private weak var skTitleBottm: NSLayoutConstraint!
    @IBOutlet private weak var icon:            UIImageView!
    @IBOutlet private weak var title:           UILabel!
    @IBOutlet private weak var desc:            UILabel!
    
    private var type: String?
    
    fileprivate func display(_ item: WorkerCellData) {
        
        desc.text   = item.desc
        icon.image  = item.icon
        title.text  = item.title
    }
}

private final class WorkerCellData {
    
    let icon:       UIImage
    let title:      String
    let desc:       String
    let id:         Int
    
    init(title: String, desc: String, icon: UIImage, id: Int) {
        
        self.title      = title
        self.desc       = desc
        self.icon       = icon
        self.id         = id
    }
}
