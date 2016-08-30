//
//  NSDate+CustomFormat.swift
//  WatchInteraction
//
//  Created by NSSimpleApps on 06.12.15.
//  Copyright © 2015 NSSimpleApps. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    convenience init(title: String, completion: (String -> Void)?) {
        
        self.init(title: title, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        self.addTextFieldWithConfigurationHandler { (textField: UITextField) -> Void in
            
            textField.placeholder = "example.com"
            textField.keyboardType = .URL
            textField.delegate = self
        }
        
        let OKAlertAction = UIAlertAction(title: "OK", style: .Default) { (alertAction: UIAlertAction) -> Void in
            
            if let text = self.textFields?.first?.text {
                
                completion?(text)
            }
        }
        OKAlertAction.enabled = false
        
        let cancelAlertAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        self.addAction(OKAlertAction)
        self.addAction(cancelAlertAction)
    }
}

extension UIAlertController: UITextFieldDelegate {
    
    public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        let resultText: String
        
        if let text = textField.text where !text.isEmpty {
            
            resultText = (text as NSString).stringByReplacingCharactersInRange(range, withString: string)
            
        } else {
            
            resultText = string
        }
        
        self.actions.first?.enabled = !resultText.isEmpty
        
        return true
    }
}
