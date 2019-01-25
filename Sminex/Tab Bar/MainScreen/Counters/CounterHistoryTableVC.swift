//
//  CounterHistoryTableVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/29/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class CounterHistoryTableVC: UIViewController {
    
    @IBOutlet private weak var collection: UICollectionView!
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: Properties
    
    public var data_: [MeterValue] = []
    public var period_: [CounterPeriod]?
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 73
    }
    
    // MARK: Actions
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromCounterHistoryTableVC.toHistory, let index = sender as? Int {
            let vc = segue.destination as! CounterHistoryVC
            vc.data_ = data_[index]
            vc.period_ = period_
        }
    }
}

extension CounterHistoryTableVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data_.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCounterCell", for: indexPath) as! HistoryCounterCell
        cell.configure(title: data_[indexPath.row].resource ?? "", counterName: data_[indexPath.row].meterUniqueNum ?? "")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: Segues.fromCounterHistoryTableVC.toHistory, sender: indexPath.row)
    }
    
}

@available(*, deprecated, message: "Use HistoryCounterCell instead")
final class CounterHistoryTableCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    
    func display(title: String, desc: String) {
        
        self.title.text = title
        self.desc.text  = desc
    }
    
    class func fromNib() -> CounterHistoryTableCell? {
        var cell: CounterHistoryTableCell?
        Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)?.forEach {
            if let view = $0 as? CounterHistoryTableCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        cell?.desc.preferredMaxLayoutWidth = cell?.desc.bounds.size.width ?? 0.0
        return cell
    }
}
