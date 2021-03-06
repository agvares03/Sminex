//
//  FinanceDebtVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/13/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss
import PDFKit

protocol FinanceDebtPayCellDelegate {
    func startShareAnimation()
    func stopShareAnimation()
}

final class FinanceDebtVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var collection:  UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func barcodePressed(_ sender: UIButton) {
        if data_?.codPay != "" && data_?.codPay != nil {
            performSegue(withIdentifier: Segues.fromFinanceDebtVC.toBarcode, sender: self)
            
        } else {
            showToast(message: "Нет данных по QR-коду")
        }
    }
    
    @IBAction private func payButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: Segues.fromFinanceDebtVC.toPay, sender: self)
    }
    
    @IBAction private func shareButtonPressed(_ sender: UIButton) {
        delegate?.startShareAnimation()
        if files == nil {
            DispatchQueue.global(qos: .background).async {
                self.filesGroup.wait()
                
                if (self.files?.count ?? 0) > 1 {
                    let alert = UIAlertController(title: "Выберите файл", message: nil, preferredStyle: .actionSheet)
                    self.files?.forEach { file in
                        alert.addAction( UIAlertAction(title: file.fileName, style: .default, handler: { (_) in self.getShareFile(file) } ) )
                    }
                    DispatchQueue.main.async {
                        self.present(alert, animated: true, completion: nil)
                    }
                    
                } else {
                    self.getShareFile(self.files?.first)
                }
            }
            return
        }
        
        if (files?.count ?? 0) > 1 {
            let alert = UIAlertController(title: "Выберите файл", message: nil, preferredStyle: .actionSheet)
            files?.forEach { file in
                alert.addAction( UIAlertAction(title: file.fileName, style: .default, handler: { (_) in self.getShareFile(file) } ) )
            }
            present(alert, animated: true, completion: nil)
        
        } else {
            self.getShareFile(files?.first)
        }
    }
    
    public var data_: AccountBillsJson?
    private var receipts: [ReceiptsJson]?
    private var files: [RecieptFilesJson]?
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
            if data_ != nil {
                self.startAnimation()
                DispatchQueue.global(qos: .userInitiated).async {
                    self.getDebt()
                    self.getShareElements()
                }
            }
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
        guard receipts != nil else {
            return 0
        }
        return receipts?.count != 0 ? (receipts?.count ?? 0) + 1 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FinanceDebtHeader", for: indexPath) as! FinanceDebtHeader
        header.dispay(getNameAndMonth(data_?.numMonth ?? 0) + " \(data_?.numYear ?? 0)", (String(format:"%.2f", (data_?.sum)!) ))
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == receipts?.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceDebtPayCell", for: indexPath) as! FinanceDebtPayCell
            cell.display(data_!)
            delegate = cell
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceDebtCell", for: indexPath) as! FinanceDebtCell
        var isBold = receipts![indexPath.row].usluga?.replacingOccurrences(of: " ", with: "") == receipts![indexPath.row].type?.replacingOccurrences(of: " ", with: "")
        if receipts![indexPath.row].usluga == "" && receipts![indexPath.row].type != ""{
            isBold = true
        }
        if !isBold {
        cell.display(title: receipts![indexPath.row].usluga ?? "",
                     desc: (receipts![indexPath.row].sum ?? 0.0).formattedWithSeparator,
                     isBold: isBold)
        
        } else {
//            let currType = receipts?.filter {
//                return $0.type == receipts![indexPath.row].type
//            }
//            var sum = 0.0
//            currType?.forEach {
//                sum += ($0.sum ?? 0.0)
//            }
            cell.display(title: receipts![indexPath.row].type ?? "",
                         desc: (receipts![indexPath.row].sum ?? 0.0).formattedWithSeparator,
                         isBold: isBold)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.row == receipts?.count {
            let defaults = UserDefaults.standard
            if (!defaults.bool(forKey: "denyOnlinePayments")) {
                let kek = !(data_?.permit_online_payment!)!
                if kek == true{
                    return CGSize(width: view.frame.size.width, height: 130.0)
                    
                }
            }
            
            return CGSize(width: view.frame.size.width, height: 193.0)
            
        }
        if indexPath.row == receipts?.count {
            let defaults = UserDefaults.standard
            if (defaults.bool(forKey: "denyInvoiceFiles")) {
                return CGSize(width: view.frame.size.width, height: 80.0)
            }
            return CGSize(width: view.frame.size.width, height: 193.0)
        
        } else {
            let cell = FinanceDebtCell.fromNib()
            var isBold = receipts![indexPath.row].usluga?.replacingOccurrences(of: " ", with: "") == receipts![indexPath.row].type?.replacingOccurrences(of: " ", with: "")
            if receipts![indexPath.row].usluga == "" && receipts![indexPath.row].type != ""{
                isBold = true
            }
            cell?.display(title: receipts![indexPath.row].usluga ?? "",
                         desc: (receipts![indexPath.row].sum ?? 0.0).formattedWithSeparator,
                         isBold: false)
            var lblH: CGFloat = 0
            if !isBold {
                let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceDebtCell", for: indexPath) as! FinanceDebtCell
                lblH = heightForLabel(text: receipts![indexPath.row].usluga!, font: cell1.title.font, width: self.view.frame.size.width - 126) + 10
            } else {
                let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceDebtCell", for: indexPath) as! FinanceDebtCell
                lblH = heightForLabel(text: receipts![indexPath.row].type!, font: cell1.title.font, width: self.view.frame.size.width - 126) + 10
            }
            return CGSize(width: view.frame.size.width, height: lblH)
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
    
    private func getDebt() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = UserDefaults.standard.string(forKey: "pwd") ?? ""
        let id = data_?.idReceipts?.stringByAddingPercentEncodingForRFC3986() ?? ""
        
        let url = Server.SERVER + Server.GET_BILLS_SERVICES + "login=" + login + "&pwd=" + pwd + "&id_receipts=" + id
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.sync {
                    self.stopAnimation()
                    self.collection.reloadData()
                }
            }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in  } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                self.receipts = ReceiptsDataJson(json: json!)?.data
            }
            if self.receipts!.count != 0{
                var cont = false
                for k in 0...self.receipts!.count - 1{
                    if !cont{
                        if (self.receipts![k].type?.containsIgnoringCase(find: "пени"))!{
                            if UserDefaults.standard.bool(forKey: "denyShowFine"){
                                self.receipts?.remove(at: k)
                                cont = true
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                self.stopAnimation()
                self.collection.reloadData()
            }
            #if DEBUG
//                print("bills = \(String(data: data!, encoding: .utf8) ?? "")")
            #endif
        
        }.resume()
    }
    
    private func getShareElements() {
        
        let login = UserDefaults.standard.string(forKey: "login")?.stringByAddingPercentEncodingForRFC3986() ?? ""
        let pwd   = UserDefaults.standard.string(forKey: "pwd") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_BILL_FILES + "login=\(login)&pwd=\(pwd)&id_receipts=\(data_?.idReceipts ?? "")")!)
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
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                self.files = RecieptFilesDataJson.init(json: json!)?.data
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
            vc.amount_ = (data_?.sum ?? 0.0) - (data_?.payment_sum ?? 0.0)
            vc.codePay_ = data_?.codPay
        
        } else if segue.identifier == Segues.fromFinanceDebtVC.toPay {
            let vc = segue.destination as! FinancePayAcceptVC
            vc.billsData_ = data_
        }
    }
}
//" ₽"
final class FinanceDebtHeader: UICollectionReusableView {
    
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

final class FinanceDebtCell: UICollectionViewCell {
    
    @IBOutlet weak var title:   UILabel!
    @IBOutlet weak var desc:    UILabel!
    
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
            self.title.font = UIFont.boldSystemFont(ofSize: self.title.font.pointSize)
            self.desc.font  = UIFont.boldSystemFont(ofSize: self.desc.font.pointSize)
            self.title.textColor = .black
        
        } else {
            self.title.font = UIFont.systemFont(ofSize: self.title.font.pointSize, weight: .light)
            self.desc.font  = UIFont.systemFont(ofSize: self.title.font.pointSize, weight: .light)
            self.title.textColor = .gray
        }
    }
    
    class func fromNib() -> FinanceDebtCell? {
        var cell: FinanceDebtCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? FinanceDebtCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 0.0) - 150
        return cell
    }
}

final class FinanceDebtPayCell: UICollectionViewCell, FinanceDebtPayCellDelegate {
    
    @IBOutlet private weak var shareLoader: UIActivityIndicatorView!
    @IBOutlet private weak var shareButton: UIButton!
    @IBOutlet private weak var dateLabel:   UILabel!
//    @IBOutlet private weak var btnConst:   NSLayoutConstraint!
    @IBOutlet private weak var btnConst1:   NSLayoutConstraint!
    @IBOutlet weak var pay_button: UIButton!
    @IBOutlet weak var pay_QR: UIButton!
    @IBOutlet weak var pay_QR_image: UIImageView!
    
    func display(_ data: AccountBillsJson) {
        self.stopShareAnimation()
        var date = data.datePay
        if (date?.count ?? 0) > 9 {
            date?.removeLast(9)
        }
        self.dateLabel.text = "До " + (date ?? "")
        
        let defaults = UserDefaults.standard
        pay_button.isHidden   = defaults.bool(forKey: "denyOnlinePayments")
        
        // Если оплаты разрешены, проверим - можно ли оплачивать конкретно эту квитанцию
        if (!defaults.bool(forKey: "denyOnlinePayments")) {
            pay_button.isHidden    = !data.permit_online_payment!
        }
        
        // Выводить или нет кнопку QR-код
        if defaults.bool(forKey: "denyQRCode"){
            pay_QR.isHidden           = true
            pay_QR_image.isHidden     = true
        }
        
        if pay_button.isHidden {
            btnConst1.constant = 0
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

struct ReceiptsDataJson: JSONDecodable {
    
    let data: [ReceiptsJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

struct ReceiptsJson: JSONDecodable {
    
    let idReceipts:     String?
    let usluga:         String?
    let type:           String?
    let sum:            Double?
    
    init?(json: JSON) {
        idReceipts  = "id_receipts" <~~ json
        usluga      = "usluga"      <~~ json
        type        = "type"        <~~ json
        sum         = "sum"         <~~ json
    }
    
    init(idReceipts: String, usluga: String, type: String, sum: Double) {
        self.idReceipts = idReceipts
        self.usluga     = usluga
        self.type       = type
        self.sum        = sum
    }
}

struct RecieptFilesDataJson: JSONDecodable {
    
    let data: [RecieptFilesJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

struct RecieptFilesJson: JSONDecodable {
    
    let fileName:   String?
    let type:       String?
    let id:         String?
    
    init?(json: JSON) {
        
        fileName = "FileName"   <~~ json
        type     = "Type"       <~~ json
        id       = "ID"         <~~ json
    }
}
