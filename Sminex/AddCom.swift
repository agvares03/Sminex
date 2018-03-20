//
//  AddCom.swift
//  DemoUC
//
//  Created by Роман Тузин on 17.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

protocol AddCommDelegate : class {
    func addCommDone(addApp: AddCom, addComm: String)
}

protocol AddCommDelegateUser : class {
    func addCommDone(addApp: AddCom, addComm: String)
}

class AddCom: UIView, Modal {
    var mainView = UIView()
    var backgroundView = UIView()
    var dialogView = UIView()
    
    var textComm: String = ""
    let textEdit = UITextView()
    
    weak var delegate: AppCons!
    weak var delegate_user: AppUser!
    
    convenience init(main_View: UIView, title:String) {
        self.init(frame: UIScreen.main.bounds)
        mainView = main_View
        initialize(main_View: mainView, title: title)
        
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func initialize(main_View: UIView, title:String){
        dialogView.clipsToBounds = true
        
        backgroundView.frame = frame
        backgroundView.backgroundColor = UIColor.black
        backgroundView.alpha = 0.6
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnBackgroundView)))
        addSubview(backgroundView)
        
        let dialogViewWidth = frame.width-64
        
        let titleLabel = UILabel(frame: CGRect(x: 8, y: 8, width: dialogViewWidth-16, height: 30))
        titleLabel.text = title
        titleLabel.textAlignment = .center
        dialogView.addSubview(titleLabel)
        
        let separatorLineView = UIView()
        separatorLineView.frame.origin = CGPoint(x: 0, y: titleLabel.frame.height + 8)
        separatorLineView.frame.size = CGSize(width: dialogViewWidth, height: 1)
        separatorLineView.backgroundColor = UIColor.groupTableViewBackground
        dialogView.addSubview(separatorLineView)
        
        textEdit.frame.origin = CGPoint(x: 4, y: titleLabel.frame.height + 8 + separatorLineView.frame.height + 8)
        textEdit.frame.size = CGSize(width: dialogViewWidth - 8, height: 100)
        textEdit.layer.borderColor = UIColor.gray.cgColor
        textEdit.layer.borderWidth = 1
        dialogView.addSubview(textEdit)
        
        // Добавим UI с кнопками
        let btn_cancel = UIButton()
        btn_cancel.frame.origin = CGPoint(x: 0, y: titleLabel.frame.height + 8 + separatorLineView.frame.height + 8 + textEdit.frame.height + 8)
        btn_cancel.frame.size = CGSize(width: dialogViewWidth / 2, height: 50)
        btn_cancel.setTitle("Отмена", for: UIControlState.normal)
        btn_cancel.setTitleColor(UIColor.blue, for: UIControlState.normal)
        btn_cancel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedCancel)))
        
        let btn_ok = UIButton()
        btn_ok.frame.origin = CGPoint(x: dialogViewWidth / 2, y: titleLabel.frame.height + 8 + separatorLineView.frame.height + 8 + textEdit.frame.height + 8)
        btn_ok.frame.size = CGSize(width: (dialogViewWidth / 2 ) - 15, height: 50)
        btn_ok.setTitle("Добавить", for: UIControlState.normal)
        btn_ok.setTitleColor(UIColor.white, for: UIControlState.normal)
        // Определим интерфейс для разных ук
        let server = Server()
        btn_ok.backgroundColor = server.hexStringToUIColor(hex: "#32CD32")
        btn_ok.layer.cornerRadius = 10
        btn_ok.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedAdd)))
        dialogView.addSubview(btn_cancel)
        dialogView.addSubview(btn_ok)
        
        let dialogViewHeight = titleLabel.frame.height + 8 + separatorLineView.frame.height + 8 + textEdit.frame.height + 8 + btn_cancel.frame.height + 8
        
        dialogView.frame.origin = CGPoint(x: 32, y: frame.height)
        dialogView.frame.size = CGSize(width: frame.width-64, height: dialogViewHeight)
        dialogView.backgroundColor = UIColor.white
        dialogView.layer.cornerRadius = 6
        addSubview(dialogView)
    }
    
    @objc func didTappedCancel(){
        dismiss(animated: true)
    }
    
    @objc func didTappedOnBackgroundView(){
        endEditing(true)
    }
    
    @objc func didTappedAdd() {
        if self.delegate != nil {
            textComm = textEdit.text
            self.delegate?.addCommDone(addApp: self, addComm: textComm)
        }
        if self.delegate_user != nil {
            textComm = textEdit.text
            self.delegate_user?.addCommDone(addApp: self, addComm: textComm)
        }
        dismiss(animated: true)
    }
    
}
