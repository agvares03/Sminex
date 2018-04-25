//
//  AuthSupportVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/25/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import DeviceKit

final class AuthSupportVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet private weak var sendButtonBottom:    NSLayoutConstraint!
    @IBOutlet private weak var sendButtonTop:       NSLayoutConstraint!
    @IBOutlet private weak var imgsHeight:          NSLayoutConstraint!
    @IBOutlet private weak var scroll:              UIScrollView!
    @IBOutlet private weak var imgsScroll:          UIScrollView!
    @IBOutlet private weak var problemTextView:     UITextField!
    @IBOutlet private weak var emailTextView:       UITextField!
    @IBOutlet private weak var lsTextView:          UITextField!
    @IBOutlet private weak var sendButton:          UIButton!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        
        view.endEditing(true)
        let alert = UIAlertController(title: "Удалить заявку?", message: "Изменения не сохранятся", preferredStyle: .alert)
        alert.addAction( UIAlertAction(title: "Отмена", style: .default, handler: { (_) in } ) )
        alert.addAction( UIAlertAction(title: "Удалить", style: .destructive, handler: { (_) in
            self.navigationController?.popViewController(animated: true) } ) )
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        sendMessage()
    }
    
    @IBAction private func imgsButtonPressed(_ sender: UIButton) {
        
        view.endEditing(true)
        let action = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        action.addAction(UIAlertAction(title: "Выбрать из галереи", style: .default, handler: { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary;
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        action.addAction(UIAlertAction(title: "Сделать фото", style: .default, handler: { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera;
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        action.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) in }))
        present(action, animated: true, completion: nil)
    }
    
    private var imgs: [UIImage] = [] {
        didSet {
            if imgs.count == 0 {
                imgsHeight.constant = 1
                sendButtonTop.constant = getPoint() + 149
                
                if isNeedToScrollMore() && tabBarController != nil {
                    sendButtonTop.constant = getPoint() + 99
                }
            
            } else {
                imgsHeight.constant = 150
                sendButtonTop.constant = getPoint() - 150
                
                if isNeedToScrollMore() && tabBarController != nil {
                    sendButtonTop.constant = getPoint() - 100
                }
            }
            drawImages()
        }
    }
    private var currPoint: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currPoint = sendButton.frame.origin.y
        sendButton.isEnabled = false
        sendButton.alpha     = 0.5
        imgsHeight.constant  = 1
        
        automaticallyAdjustsScrollViewInsets = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        problemTextView.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        emailTextView.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        lsTextView.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        sendButtonTop.constant = getPoint()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        if problemTextView.text == "" || emailTextView.text == "" || lsTextView.text == "" {
            sendButton.isEnabled = false
            sendButton.alpha = 0.5
            
        } else {
            sendButton.isEnabled = true
            sendButton.alpha = 1
        }
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
        
        scroll.contentSize.height += 200
        
        if !isNeedToScroll() {
            
            if Device().isOneOf([.iPhone6, .iPhone6s, .simulator(.iPhone6), .simulator(.iPhone6s)]) && imgs.count != 0 {
                sendButtonBottom.constant += 220
                sendButtonTop.constant    -= 190
                return
            }
            
            sendButtonTop.constant -= 210
        
        } else {
            if !isNeedToScrollMore() {
                if imgs.count == 0 {
                    if tabBarController == nil {
                        sendButtonTop.constant -= 210
                    } else {
                        sendButtonTop.constant -= 180
                    }
                    
                } else {
                    if tabBarController == nil {
                        sendButtonBottom.constant += 60
                        sendButtonTop.constant    -= 60
                    
                    } else {
                        sendButtonBottom.constant += 40
                        sendButtonTop.constant    -= 40
                    }
                }
            
            } else {
                if imgs.count == 0 {
                    if tabBarController == nil {
                        sendButtonTop.constant    = getPoint() - 120
                        sendButtonBottom.constant = getPoint() + 70
                    
                    } else {
                        sendButtonTop.constant    = getPoint() - 100
                        sendButtonBottom.constant = getPoint() + 50
                    }
                
                } else {
                    if tabBarController == nil {
                        sendButtonBottom.constant = getPoint() + 120
                    
                    } else {
                        sendButtonBottom.constant = getPoint() + 100
                    }
                }
            }
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        
        scroll.contentSize.height -= 200
        
        if Device().isOneOf([.iPhone6, .iPhone6s, .simulator(.iPhone6), .simulator(.iPhone6s)]) && imgs.count != 0 {
            sendButtonBottom.constant -= 220
            sendButtonTop.constant    += 190
            return
        }
        
        if !isNeedToScroll() {
            sendButtonTop.constant += 210
            
        } else {
            if !isNeedToScrollMore() {
                if imgs.count == 0 {
                    if tabBarController == nil {
                        sendButtonTop.constant += 210
                    } else {
                        sendButtonTop.constant += 180
                    }
                    
                } else {
                    if tabBarController == nil {
                        sendButtonBottom.constant -= 60
                        sendButtonTop.constant    += 60
                    
                    } else {
                        sendButtonBottom.constant -= 40
                        sendButtonTop.constant    += 40
                    }
                }
            } else {
                if imgs.count == 0 {
                    sendButtonTop.constant = getPoint()
                    sendButtonBottom.constant = 16
                    
                } else {
                    sendButtonBottom.constant = 16
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.isNavigationBarHidden = true
    }
    
    private func getPoint() -> CGFloat {
        if Device() != .iPhoneX && Device() != .simulator(.iPhoneX) {
            if tabBarController == nil {
                return (view.frame.size.height - currPoint) + 50
            } else {
                return ((view.frame.size.height - currPoint) + 50) - 50
            }
        } else {
            if tabBarController == nil {
                return (view.frame.size.height - currPoint) - 50
            } else {
                return ((view.frame.size.height - currPoint) - 50) - 50
            }
        }
    }
    
    private func drawImages() {
        
        imgsScroll.subviews.forEach {
            $0.removeFromSuperview()
        }
        var x = 0.0
        var tag = 0
        
        imgs.forEach {
            let img = UIImageView(frame: CGRect(x: x, y: 0.0, width: 150.0, height: 150.0))
            img.image = $0
            let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            img.isUserInteractionEnabled = true
            img.addGestureRecognizer(tap)
            imgsScroll.addSubview(img)
            
            let deleteButton = UIButton(frame: CGRect(x: x + 130.0, y: 0.0, width: 20.0, height: 20.0))
            deleteButton.backgroundColor = .white
            deleteButton.cornerRadius = 0.5 * deleteButton.bounds.size.width
            deleteButton.clipsToBounds = true
            deleteButton.tag = tag
            deleteButton.alpha = 0.7
            deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
            imgsScroll.addSubview(deleteButton)
            
            let image = UIImageView(frame: CGRect(x: x + 135.0, y: 5.0, width: 10.0, height: 10.0))
            image.image = UIImage(named: "close_ic")
            imgsScroll.addSubview(image)
            
            x += 160
            tag += 1
        }
        imgsScroll.contentSize = CGSize(width: CGFloat(x), height: imgsScroll.frame.size.height)
    }
    
    @objc private func deleteButtonTapped(_ sender: UIButton) {
        imgs.remove(at: sender.tag)
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        
        let imageView = sender.view as! UIImageView
        let newImageView = UIImageView(image: imageView.image)
        newImageView.frame = UIScreen.main.bounds
        newImageView.backgroundColor = .black
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage(_:)))
        newImageView.addGestureRecognizer(tap)
        self.view.addSubview(newImageView)
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = true
    }
    
    @objc func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        self.navigationController?.isNavigationBarHidden = false
        sender.view?.removeFromSuperview()
    }
    
    private func sendMessage() {
        
        let url = "login=\(lsTextView.text ?? "")&text=\(problemTextView.text ?? "")&email=\(emailTextView.text ?? "")"
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SEND_MESSAGE + url)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else { return }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            #if DEBUG
                print(String(data: data!, encoding: .utf8) ?? "")
            #endif
        }.resume()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imgs.append(image)
        dismiss(animated: true, completion: nil)
    }
}


















