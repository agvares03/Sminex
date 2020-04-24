//
//  FinanceDebtVCComm.swift
//  Sminex
//
//  Created by Sergey Ivanov on 18/07/2019.
//

import UIKit
import Gloss
import PDFKit

protocol BillsCellDelegate: class {
    func barcodePressed(section: Int)
    func payButtonPressed(section: Int)
    func shareButtonPressed(section: Int)
}

class FinanceDebtVCComm: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, BillsCellDelegate {
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var collection:  UICollectionView!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    @IBOutlet private weak var archiveBtn: UILabel!
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    func barcodePressed(section: Int) {
        currSection = section
        if data_[section].codPay != "" && data_[section].codPay != nil {
            performSegue(withIdentifier: Segues.fromFinanceDebtVC.toBarcode, sender: self)
            
        } else {
            showToast(message: "Нет данных по QR-коду")
        }
    }
    
    func payButtonPressed(section: Int) {
        currSection = section
        performSegue(withIdentifier: Segues.fromFinanceDebtVC.toPay, sender: self)
    }
    
    @IBAction private func goArchivePressed(_ sender: UIButton) {
        performSegue(withIdentifier: "receiptArchive", sender: self)
    }
    
    func shareButtonPressed(section: Int) {
        currSection = section
        delegate?.startShareAnimation()
        if files[section].filteredData == nil {
            DispatchQueue.global(qos: .background).async {
                self.filesGroup.wait()

                if (self.files[section].filteredData.count) > 1 {
                    let alert = UIAlertController(title: "Выберите файл", message: nil, preferredStyle: .actionSheet)
                    self.files[section].filteredData.forEach { file in
                        alert.addAction( UIAlertAction(title: file.fileName, style: .default, handler: { (_) in self.getShareFile(file) } ) )
                    }
                    DispatchQueue.main.async {
                        self.present(alert, animated: true, completion: nil)
                    }

                } else {
                    self.getShareFile(self.files[section].filteredData.first)
                }
            }
            return
        }

        if (files[section].filteredData.count) > 1 {
            let alert = UIAlertController(title: "Выберите файл", message: nil, preferredStyle: .actionSheet)
            files[section].filteredData.forEach { file in
                alert.addAction( UIAlertAction(title: file.fileName, style: .default, handler: { (_) in self.getShareFile(file) } ) )
            }
            present(alert, animated: true, completion: nil)

        } else {
            self.getShareFile(files[section].filteredData.first)
        }
    }
    struct Objects {
        var sectionName : Int
        var filteredData : [ReceiptsJson]!
    }
    struct FileObjects {
        var sectionName : Int
        var filteredData : [RecieptFilesJson]!
    }
    var currSection = -1
    var dataFilt = [Objects]()
    public var allData_: [AccountBillsJson] = []
    public var data_: [AccountBillsJson] = []
    private var files = [FileObjects]()
    private var filesGroup = DispatchGroup()
    private var delegate: FinanceDebtPayCellDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        automaticallyAdjustsScrollViewInsets = false
        collection.dataSource   = self
        collection.delegate     = self
        
        let defaults = UserDefaults.standard
        if (defaults.bool(forKey: "denyInvoiceFiles")) {
            
        } else {
            if data_.count != 0 {
                self.startAnimation()
                DispatchQueue.global(qos: .userInitiated).async {
                    self.getDebt(dat: self.data_[0])
                    self.getShareElements(dat: self.data_[0])
                }
            }
        }
        if title == "Неоплаченный счет"{
            archiveBtn.text = "Архив неоплаченных счетов"
        }
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключенние к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.viewDidLoad()
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        case .wifi: break
            
        case .wwan: break
            
        }
    }
    @objc func statusManager(_ notification: Notification) {
        updateUserInterface()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notifiPressed = false
        if TemporaryHolder.instance.menuNotifications > 0{
            notifiBtn.image = UIImage(named: "new_notifi1")!
        }else{
            notifiBtn.image = UIImage(named: "new_notifi0")!
        }
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard dataFilt[section].filteredData != nil else {
            return 0
        }
        return dataFilt[section].filteredData?.count != 0 ? (dataFilt[section].filteredData?.count ?? 0) + 1 : 1
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataFilt.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FinanceDebtCommHeader", for: indexPath) as! FinanceDebtCommHeader
        header.dispay(getNameAndMonth(data_[indexPath.section].numMonth ?? 0) + " \(data_[indexPath.section].numYear ?? 0)", (String(format:"%.2f", (data_[indexPath.section].sum)!) ))
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == dataFilt[indexPath.section].filteredData?.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceDebtPayCommCell", for: indexPath) as! FinanceDebtPayCommCell
            cell.display(data_[indexPath.section], delegate: self, section: indexPath.section)
            delegate = cell
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceDebtCommCell", for: indexPath) as! FinanceDebtCommCell
        var isBold = dataFilt[indexPath.section].filteredData![indexPath.row].usluga?.replacingOccurrences(of: " ", with: "") == dataFilt[indexPath.section].filteredData![indexPath.row].type?.replacingOccurrences(of: " ", with: "")
        if dataFilt[indexPath.section].filteredData![indexPath.row].usluga == "" && dataFilt[indexPath.section].filteredData![indexPath.row].type != ""{
            isBold = true
        }
        if !isBold {
            cell.display(title: dataFilt[indexPath.section].filteredData![indexPath.row].usluga ?? "",
                         desc: (dataFilt[indexPath.section].filteredData![indexPath.row].sum ?? 0.0).formattedWithSeparator,
                         isBold: isBold)
            
        } else {
            //            let currType = receipts?.filter {
            //                return $0.type == receipts![indexPath.row].type
            //            }
            //            var sum = 0.0
            //            currType?.forEach {
            //                sum += ($0.sum ?? 0.0)
            //            }
            cell.display(title: dataFilt[indexPath.section].filteredData![indexPath.row].type ?? "",
                         desc: (dataFilt[indexPath.section].filteredData![indexPath.row].sum ?? 0.0).formattedWithSeparator,
                         isBold: isBold)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row == dataFilt[indexPath.section].filteredData?.count {
            var height:CGFloat = 100.0
            let defaults = UserDefaults.standard
//            if (defaults.bool(forKey: "denyInvoiceFiles")) {
//                height = 60.0
//            }
            if (!defaults.bool(forKey: "denyOnlinePayments")) {
                let kek = data_[indexPath.section].permit_online_payment!
                if kek == true{
                    height = 193
                }
            }
            return CGSize(width: view.frame.size.width - 32, height: height)
            
        } else {
            let cell = FinanceDebtCommCell.fromNib()
            var isBold = dataFilt[indexPath.section].filteredData![indexPath.row].usluga?.replacingOccurrences(of: " ", with: "") == dataFilt[indexPath.section].filteredData![indexPath.row].type?.replacingOccurrences(of: " ", with: "")
            if dataFilt[indexPath.section].filteredData![indexPath.row].usluga == "" && dataFilt[indexPath.section].filteredData![indexPath.row].type != ""{
                isBold = true
            }
            cell?.display(title: dataFilt[indexPath.section].filteredData![indexPath.row].usluga ?? "",
                          desc: (dataFilt[indexPath.section].filteredData![indexPath.row].sum ?? 0.0).formattedWithSeparator,
                          isBold: false)
            var lblH: CGFloat = 0
            if !isBold {
                let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceDebtCommCell", for: indexPath) as! FinanceDebtCommCell
                lblH = heightForLabel(text: dataFilt[indexPath.section].filteredData![indexPath.row].usluga!, font: cell1.title.font, width: self.view.frame.size.width - 199) + 10
                return CGSize(width: view.frame.size.width - 32, height: lblH)
            } else {
                let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceDebtCommCell", for: indexPath) as! FinanceDebtCommCell
                lblH = heightForLabel(text: dataFilt[indexPath.section].filteredData![indexPath.row].type!, font: cell1.title.font, width: self.view.frame.size.width - 159) + 10
                if lblH > 39{
                    return CGSize(width: view.frame.size.width - 32, height: lblH)
                }else{
                    return CGSize(width: view.frame.size.width - 32, height: 39)
                }
            }
            
        }
    }
    
    func heightForLabel(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
    
    private func getDebt(dat: AccountBillsJson) {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = UserDefaults.standard.string(forKey: "pwd") ?? ""
        let id = dat.idReceipts?.stringByAddingPercentEncodingForRFC3986() ?? ""
        
        let url = Server.SERVER + Server.GET_BILLS_SERVICES + "login=" + login + "&pwd=" + pwd + "&id_receipts=" + id
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
                        
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in  } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            var rec: [ReceiptsJson]? = []
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                rec = ReceiptsDataJson(json: json!)?.data
            }
            if rec!.count != 0{
                var cont = false
                for k in 0...rec!.count - 1{
                    if !cont{
                        if (rec![k].type?.containsIgnoringCase(find: "пени"))!{
                            if UserDefaults.standard.bool(forKey: "denyShowFine"){
                                rec?.remove(at: k)
                                cont = true
                            }
                        }
                    }
                }
            }
            self.dataFilt.append(Objects(sectionName: self.dataFilt.count, filteredData: rec))
            if self.dataFilt.count == self.data_.count{
                DispatchQueue.main.async {
                    self.stopAnimation()
                    self.collection.reloadData()
                }
            }else{
                self.getDebt(dat: self.data_[self.dataFilt.count])
            }
            #if DEBUG
            //                print("bills = \(String(data: data!, encoding: .utf8) ?? "")")
            #endif
            
            }.resume()
    }
    
    private func getShareElements(dat: AccountBillsJson) {
        
        let login = UserDefaults.standard.string(forKey: "login")?.stringByAddingPercentEncodingForRFC3986() ?? ""
        let pwd   = UserDefaults.standard.string(forKey: "pwd") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_BILL_FILES + "login=\(login)&pwd=\(pwd)&id_receipts=\(dat.idReceipts ?? "")")!)
        request.httpMethod = "GET"
        
        //        print(request.url)
        
        filesGroup.enter()
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                self.filesGroup.leave()
            }
            
            guard data != nil else { return }
            
            #if DEBUG
            //            print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            var fil:[RecieptFilesJson]? = []
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                fil = RecieptFilesDataJson.init(json: json!)?.data
            }
            self.files.append(FileObjects(sectionName: self.files.count, filteredData: fil))
            if self.files.count != self.data_.count{
                self.getShareElements(dat: self.data_[self.files.count])
            }
            }.resume()
    }
    
    private func getShareFile(_ file: RecieptFilesJson?) {
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.DOWNLOAD_FILE + "fileId=\(file?.id ?? "")")!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.async {
                    self.delegate?.stopShareAnimation()
                }
            }
            
            guard data != nil else { return }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка", message: "Файл отсутствует на сервере", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            if file?.type == "png"
                || file?.type == "jpeg"
                || file?.type == "jpg"
                || file?.fileName?.contains(find: ".png") ?? false
                || file?.fileName?.contains(find: ".jpeg") ?? false
                || file?.fileName?.contains(find: ".jpg") ?? false {
                
                let image = [UIImage(data: data!)!]
                DispatchQueue.main.async {
                    let activityViewController = UIActivityViewController(activityItems: image, applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.view
                    self.present(activityViewController, animated: true, completion: nil)
                }
                
            } else if file?.type == "pdf" || file?.fileName?.contains(find: ".pdf") ?? false {
                var docURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last! as NSURL
                docURL = docURL.appendingPathComponent( "myDocument.pdf")! as NSURL
                try! data?.write(to: docURL as URL)
                DispatchQueue.main.async {
                    let activityViewController = UIActivityViewController(activityItems: [docURL], applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.view
                    self.present(activityViewController, animated: true, completion: nil)
                }
            }
            
            #if DEBUG
            //                print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            
            }.resume()
    }
    
    private func startAnimation() {
        loader.isHidden     = false
        collection.isHidden = true
        loader.startAnimating()
    }
    
    private func stopAnimation() {
        collection.isHidden = false
        loader.isHidden     = true
        loader.stopAnimating()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromFinanceDebtVC.toBarcode {
            let vc = segue.destination as! FinanceBarCodeVC
            vc.amount_ = (data_[currSection].sum ?? 0.0) - (data_[currSection].payment_sum ?? 0.0)
            vc.codePay_ = data_[currSection].codPay
            
        } else if segue.identifier == Segues.fromFinanceDebtVC.toPay {
            let vc = segue.destination as! FinancePayAcceptVCComm
            vc.billsData_ = data_[currSection]
        } else if segue.identifier == Segues.fromFinanceVC.toReceiptArchive {
            let vc = segue.destination as! FinanceDebtArchiveVCComm
            vc.data_ = allData_
            if title == "Неоплаченный счет"{
                vc.title = "Неоплаченные счета"
            }
        }
    }
}
//" ₽"
final class FinanceDebtCommHeader: UICollectionReusableView {
    
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var obj_sum: UILabel!
    
    func dispay(_ title: String, _ obj_sum: String) {
        let d: Double = Double(obj_sum.replacingOccurrences(of: ",", with: "."))!
        var sum = String(format:"%.2f", d)
        if d > 999.00 || d < -999.00{
            let i = Int(sum.distance(from: sum.startIndex, to: sum.index(of: ".")!)) - 3
            sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: i))
        }
        if sum.first == "-" {
            sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: 1))
            self.obj_sum.textColor = UIColor(red: 0/255, green: 128/255, blue: 0/255, alpha: 1.0)
        }
        self.title.text = title
        self.obj_sum.text = sum.replacingOccurrences(of: ".", with: ",") + " ₽"
    }
}

final class FinanceDebtCommCell: UICollectionViewCell {
    
    @IBOutlet weak var title:   UILabel!
    @IBOutlet weak var desc:    UILabel!
    @IBOutlet weak var leadingDesc:    NSLayoutConstraint!
    
    func display(title: String, desc: String, isBold: Bool) {
        let d: Double = Double(desc.replacingOccurrences(of: ",", with: "."))!
        var sum = String(format:"%.2f", d)
        if d > 999.00 || d < -999.00{
            let i = Int(sum.distance(from: sum.startIndex, to: sum.index(of: ".")!)) - 3
            sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: i))
        }
        if sum.first == "-" {
            sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: 1))
            self.desc.textColor = UIColor(red: 0/255, green: 128/255, blue: 0/255, alpha: 1.0)
        }
        self.title.text = title
        self.desc.text = sum.replacingOccurrences(of: ".", with: ",")
        
        if isBold {
            self.leadingDesc.constant = 16
            self.title.font = UIFont.boldSystemFont(ofSize: self.title.font.pointSize)
            self.desc.font  = UIFont.boldSystemFont(ofSize: self.desc.font.pointSize)
            self.title.textColor = .black
            self.desc.textColor = .black
        } else {
            self.leadingDesc.constant = 40
            self.title.font = UIFont.systemFont(ofSize: self.title.font.pointSize, weight: .regular)
            self.desc.font  = UIFont.systemFont(ofSize: self.title.font.pointSize, weight: .regular)
            self.title.textColor = .gray
            self.desc.textColor = .gray
        }
    }
    
    class func fromNib() -> FinanceDebtCommCell? {
        var cell: FinanceDebtCommCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? FinanceDebtCommCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 0.0) - 150
        return cell
    }
}

final class FinanceDebtPayCommCell: UICollectionViewCell, FinanceDebtPayCellDelegate {
    
    @IBOutlet private weak var shareLoader: UIActivityIndicatorView!
    @IBOutlet private weak var shareButton: UIButton!
    //    @IBOutlet private weak var btnConst:   NSLayoutConstraint!
    @IBOutlet private weak var btnConst1:   NSLayoutConstraint!
    @IBOutlet private weak var viewHeight:   NSLayoutConstraint!
    @IBOutlet weak var pay_button: UIButton!
    var delegate: BillsCellDelegate?
    var section = -1
    @IBAction private func barcodePressed(_ sender: UIButton) {
        delegate?.barcodePressed(section: section)
    }
    
    @IBAction private func payButtonPressed(_ sender: UIButton) {
        delegate?.payButtonPressed(section: section)
    }
    
    @IBAction private func shareButtonPressed(_ sender: UIButton) {
        delegate?.shareButtonPressed(section: section)
    }
    
    func display(_ data: AccountBillsJson, delegate: BillsCellDelegate, section: Int) {
        self.delegate = delegate
        self.section = section
        self.stopShareAnimation()
        var date = data.datePay
        if (date?.count ?? 0) > 9 {
            date?.removeLast(9)
        }
        
        let defaults = UserDefaults.standard
        pay_button.isHidden   = defaults.bool(forKey: "denyOnlinePayments")
        
        // Если оплаты разрешены, проверим - можно ли оплачивать конкретно эту квитанцию
        if (!defaults.bool(forKey: "denyOnlinePayments")) {
            pay_button.isHidden    = !data.permit_online_payment!
        }
        if pay_button.isHidden {
            btnConst1.constant = 0
            viewHeight.constant = 50
        }else{
            viewHeight.constant = 120
            btnConst1.constant = 48
        }
    }
    
    func startShareAnimation() {
        shareButton.isHidden = true
        shareLoader.isHidden = false
        shareLoader.startAnimating()
    }
    
    func stopShareAnimation() {
        shareLoader.stopAnimating()
        shareLoader.isHidden = true
        shareButton.isHidden = false
    }
}
