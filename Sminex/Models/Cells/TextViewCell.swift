

import Foundation
import UIKit

protocol TextViewCellDelegate: class {
    func textViewCell(cell: TextViewCell, didChangeText text: String)
}


class TextViewCell: UITableViewCell, UITextViewDelegate {
    
    // MARK: - Outlets

    @IBOutlet var textView: UITextView!
    
    // MARK: - Properties

    weak var delegate: TextViewCellDelegate?
    
    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        delegate?.textViewCell(cell: self, didChangeText: textView.text)
    }

}
