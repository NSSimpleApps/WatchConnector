//
//  NSDate+CustomFormat.swift
//  WatchInteraction
//
//  Created by NSSimpleApps on 06.12.15.
//  Copyright © 2015 NSSimpleApps. All rights reserved.
//

import UIKit

extension UIAlertController {
    convenience init(title: String, completion: ((String) -> Void)?) {
        self.init(title: title, message: nil, preferredStyle: .alert)
        self.addTextField { (textField: UITextField) in
            textField.placeholder = "example.com"
            textField.keyboardType = .URL
            textField.delegate = self
        }
        
        let okAlertAction = UIAlertAction(title: "OK", style: .default) { (alertAction: UIAlertAction) -> Void in
            if let text = self.textFields?.first?.text {
                completion?(text)
            }
        }
        okAlertAction.isEnabled = false
        
        self.addAction(okAlertAction)
        self.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    }
}

extension UIAlertController: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let resultText: String
        if let text = textField.text, !text.isEmpty {
            resultText = (text as NSString).replacingCharacters(in: range, with: string)
        } else {
            resultText = string
        }
        
        self.actions.first?.isEnabled = !resultText.isEmpty
        
        return true
    }
}
