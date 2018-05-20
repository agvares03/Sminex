//
//  DigitInput.swift
//  Sminex
//
//  Created by IH0kN3m on 3/28/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

public enum DigitInputViewAnimationType: Int {
    case none, dissolve, spring
}

public protocol CounterDelegate {
    func textFieldDidChange(_ textField: UITextField)
}

open class DigitInputView: UIView {
    
    /**
     The number of digits to show, which will be the maximum length of the final string
     */
    open var numberOfDigits: Int = 4 {
        
        didSet {
            setup()
        }
        
    }
    
    open var isEnergy: Bool = false
    
    /**
     The color of the line under each digit
     */
    open var bottomBorderColor = UIColor.lightGray {
        
        didSet {
            setup()
        }
        
    }
    
    /**
     The background color of digits
     */
    open var backColor = UIColor.clear {
        
        didSet {
            setup()
        }
    }
    
    /**
     The color of the line under next digit
     */
    open var nextDigitBottomBorderColor = UIColor.gray {
        
        didSet {
            setup()
        }
        
    }
    
    /**
     The color of the digits
     */
    open var textColor: UIColor = .black {
        
        didSet {
            setup()
        }
        
    }
    
    /**
     If not nil, only the characters in this string are acceptable. The rest will be ignored.
     */
    open var acceptableCharacters: String? = nil
    
    /// The animatino to use to show new digits
    open var animationType: DigitInputViewAnimationType = .dissolve
    
    /**
     The font of the digits. Although font size will be calculated automatically.
     */
    open var font: UIFont?
    
    /**
     The string that the user has entered
     */
    open var text: String {
        
        get {
            
            guard let textField = textField else { return "" }
            var txt = textField.text ?? ""
            
            if acceptableCharacters?.contains(find: ".") ?? false && txt.length > 4 {
                txt.insert(".", at: txt.index(txt.startIndex, offsetBy: 4))
            }
            return txt
            
        }
        
    }
    
    fileprivate var labels = [DigitLabel]()
    fileprivate var underlines = [UIView]()
    open var textField: UITextField?
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer?
    
    fileprivate var underlineHeight: CGFloat = 4
    fileprivate var spacing: CGFloat = 8
    
    open var delegate: CounterDelegate?
    
    override open var canBecomeFirstResponder: Bool {
        
        get {
            return true
        }
        
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        setup()
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        setup()
        
    }
    
    override open func becomeFirstResponder() -> Bool {
        
        guard let textField = textField else { return false }
        textField.becomeFirstResponder()
        return true
        
    }
    
    override open func resignFirstResponder() -> Bool {
        
        guard let textField = textField else { return true }
        textField.resignFirstResponder()
        return true
        
    }
    
    override open func layoutSubviews() {
        
        super.layoutSubviews()
        
        // width to height ratio
        let ratio: CGFloat = 0.75
        
        // Now we find the optimal font size based on the view size
        // and set the frame for the labels
        var characterWidth = frame.height * ratio
        var characterHeight = frame.height
        
        // if using the current width, the digits go off the view, recalculate
        // based on width instead of height
        if (characterWidth + spacing) * CGFloat(numberOfDigits) + spacing > frame.width {
            characterWidth = (frame.width - spacing * CGFloat(numberOfDigits + 1)) / CGFloat(numberOfDigits)
            characterHeight = characterWidth / ratio
        }
        
        let extraSpace = frame.width - CGFloat(numberOfDigits - 1) * spacing - CGFloat(numberOfDigits) * characterWidth
        
        // font size should be less than the available vertical space
        let fontSize = CGFloat(25)//characterHeight * 0.8
        
        let y = (frame.height - characterHeight) / 2
        for (index, label) in labels.enumerated() {
            let x = extraSpace / 2 + (characterWidth + spacing) * CGFloat(index)
            label.frame = CGRect(x: x, y: y, width: characterWidth, height: characterHeight)
            
            underlines[index].frame = CGRect(x: x, y: frame.height - underlineHeight, width: characterWidth, height: underlineHeight)
            
            if let font = font {
                label.font = font.withSize(fontSize)
            }
            else {
                label.font = label.font.withSize(fontSize)
            }
        }
        
    }
    
    /**
     Sets up the required views
     */
    open func setup() {
        
        isUserInteractionEnabled = true
        clipsToBounds = true
        
        if tapGestureRecognizer == nil {
            tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
            addGestureRecognizer(tapGestureRecognizer!)
        }
        
        if textField == nil {
            textField = UITextField()
            textField?.delegate = self
            textField?.frame = CGRect(x: 0, y: -40, width: 100, height: 30)
            
            if #available(iOS 11.0, *) {
                textField?.smartDashesType = .no
                textField?.smartQuotesType = .no
            }
            
            textField?.autocorrectionType = .no
            addSubview(textField!)
        }
        
        textField?.keyboardType = .numberPad
        
        // Since this function isn't called frequently, we just remove everything
        // and recreate them. Don't need to optimize it.
        
        for label in labels {
            label.removeFromSuperview()
        }
        labels.removeAll()
        
        for underline in underlines {
            underline.removeFromSuperview()
        }
        underlines.removeAll()
        
        for i in 0..<numberOfDigits {
            let label = DigitLabel()
            label.textAlignment = .center
            label.isUserInteractionEnabled  = false
            label.adjustsFontSizeToFitWidth = false
            label.textColor = textColor
            label.backgroundColor = backColor
            label.cornerRadius = 8
            label.text = "0"
            label.font = font
            
            let underline = UIView()
            underline.backgroundColor = i == 0 ? nextDigitBottomBorderColor : bottomBorderColor
            
            addSubview(label)
            addSubview(underline)
            labels.append(label)
            underlines.append(underline)
        }
        
    }
    
    /**
     Handles tap gesture on the view
     */
    @objc fileprivate func viewTapped(_ sender: UITapGestureRecognizer) {
        
        textField!.becomeFirstResponder()
        
    }
    
    /**
     Called when the text changes so that the labels get updated
     */
    fileprivate func didChange(_ backspaced: Bool = false) {
        
        guard let textField = textField, let text = textField.text else { return }
        
        delegate?.textFieldDidChange(textField)
        for item in labels {
            item.text = "0"
        }
        
        var txt = textField.text ?? ""
        
        if acceptableCharacters?.contains(find: ".") ?? false && txt.length > 4 {
            txt.insert(".", at: txt.index(txt.startIndex, offsetBy: 4))
        }
        
        for (index, item) in txt.reversed().enumerated() {
            if labels.count > index {
                let animate = index == text.count - 1 && !backspaced
                changeText(of: labels.reversed()[index], newText: String(item), animate)
            }
        }
        
        // set all the bottom borders color to default
        for underline in underlines {
            underline.backgroundColor = bottomBorderColor
        }
        
        let nextIndex = text.count + 1
        if labels.count > 0, nextIndex < labels.count + 1 {
            // set the next digit bottom border color
            underlines[nextIndex - 1].backgroundColor = nextDigitBottomBorderColor
        }
        
    }
    
    /// Changes the text of a DigitLabel with animation
    ///
    /// - parameter label: The label to change text of
    /// - parameter newText: The new string for the label
    private func changeText(of label: DigitLabel, newText: String, _ animated: Bool = false) {
        
        if !animated || animationType == .none {
            label.text = newText
            return
        }
        
        if animationType == .spring {
            label.frame.origin.y = frame.height
            label.text = newText
            
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                label.frame.origin.y = self.frame.height - label.frame.height
            }, completion: nil)
        }
        else if animationType == .dissolve {
            UIView.transition(with: label,
                              duration: 0.4,
                              options: .transitionCrossDissolve,
                              animations: {
                                label.text = newText
            }, completion: nil)
        }
    }
    
}


// MARK: TextField Delegate
extension DigitInputView: UITextFieldDelegate {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let char = string.cString(using: .utf8)
        let isBackSpace = strcmp(char, "\\b")
        if isBackSpace == -92, let text = textField.text {
            
            textField.text = text.substring(to: text.index(text.endIndex, offsetBy: -1))
            didChange(true)
            return false
        }
        
        if !isEnergy {
        
            if (acceptableCharacters?.contains(find: ".") ?? false) && (textField.text?.length ?? 0) >= 7 {
                return false
                
            } else if !(acceptableCharacters?.contains(find: ".") ?? false) && (textField.text?.length ?? 0) >= 5 {
                return false
            }
        
        } else {
            if (textField.text?.length ?? 0) >= 6 {
                return false
            }
        }
        
        if !(acceptableCharacters?.contains(find: string) ?? true) {
            return false
        }
        
        if string == "." && (textField.text ?? "").contains(find: ".") {
            return false
        
        } else if string == "." && !(textField.text ?? "").contains(find: ".") {
            
            textField.text = (textField.text ?? "") + string
            didChange()
            return false
        }
        
        guard let acceptableCharacters = acceptableCharacters else {
            textField.text = (textField.text ?? "") + string
            didChange()
            return false
        }
        
        if acceptableCharacters.contains(string) {
            textField.text = (textField.text ?? "") + string
            didChange()
            return false
        }
        
        return false
        
    }
    
}

final class DigitLabel: UILabel {
    
    override var text: String? {
        didSet {
            if text == "." {
                self.backgroundColor = .clear
            } else {
                self.backgroundColor = UIColor(white: 96/100, alpha: 1.0)
            }
        }
    }
}

