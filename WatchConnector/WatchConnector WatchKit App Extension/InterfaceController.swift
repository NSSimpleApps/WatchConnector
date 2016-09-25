//
//  InterfaceController.swift
//  WatchConnectorWatch Extension
//
//  Created by NSSimpleApps on 07.03.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {

    @IBOutlet var button: WKInterfaceButton!
    @IBOutlet var table: WKInterfaceTable!
    
    @IBOutlet var errorLabel: WKInterfaceLabel!
    
    private var notes = [[String: Any]]()
    
    private var rowIndex: Int?
    
    override func awake(withContext context: Any?) {
        
        super.awake(withContext: context)
        
        self.updateTitle(withContext: WatchConnector.shared.receivedApplicationContext)
        
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.applicationContextDidChange(_:)),
                       name: WCApplicationContextDidChangeNotification,
                       object: WatchConnector.shared)
        
        //WCSessionDelegate
    }
    
    func updateTitle(withContext context: [String: Any]) {
        
        let title: String
        
        if let flag = context[UpdateUIKey] as? Bool {
            
            if flag {
                
                title = "Update table!"
                
            } else {
                
                title = "Up to date!"
            }
            
        } else {
            
            title = "Unknown"
        }
        self.setTitle(title)
    }
    
    func applicationContextDidChange(_ notification: Notification) {
        
        if let context = notification.userInfo as? [String: AnyObject] {
            
            DispatchQueue.main.async(execute: {
                
                self.updateTitle(withContext: context)
            })
        }
    }
    
    override func willActivate() {
        
        super.willActivate()
        
        if self.rowIndex != nil {
            
            self.notes.remove(at: self.rowIndex!)
            self.table.removeRows(at: IndexSet(integer: self.rowIndex!))
            
            self.rowIndex = nil
        }
    }

    @IBAction func requestData() {
        
        self.button.setEnabled(false)
        
        WatchConnector.shared.sendData(Data(),
                                       withIdentifier: DataRequest,
                                       description: nil,
                                       replyBlock: { (data: Data, description: String?) in
                                        
                                        if let message = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: Any] {
                                            
                                            self.notes = message[Notes] as! [[String: Any]]
                                            
                                            DispatchQueue.main.async(execute: {
                                                
                                                self.table.setHidden(false)
                                                self.errorLabel.setHidden(true)
                                                
                                                let numberOfRows = self.notes.count
                                                
                                                if numberOfRows == 0 {
                                                    
                                                    self.table.setHidden(true)
                                                    self.errorLabel.setHidden(false)
                                                    self.errorLabel.setText("No notes")
                                                    
                                                } else {
                                                    
                                                    self.table.setNumberOfRows(numberOfRows, withRowType: String(describing: TableRowController.self))
                                                    
                                                    for index in (0..<numberOfRows) {
                                                        
                                                        let tableRowController = self.table.rowController(at: index) as! TableRowController
                                                        tableRowController.image.setImageData(self.notes[index]["image"] as? Data)
                                                        tableRowController.label.setText(self.notes[index]["url"] as? String)
                                                    }
                                                    self.table.setHidden(false)
                                                    self.errorLabel.setHidden(true)
                                                }
                                                
                                                self.button.setEnabled(true)
                                            })
                                        }
                                        
        }) { (error: Error) in
            
            print(error)
            
            DispatchQueue.main.async(execute: {
                
                self.table.setHidden(true)
                self.errorLabel.setHidden(false)
                self.errorLabel.setText(error.localizedDescription)
                
                self.button.setEnabled(true)
            })
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        
        let deleteAction = WKAlertAction(title: "Yes", style: .default) { () -> Void in
            
            WatchConnector.shared.sendMessage([URIRepresentation: self.notes[rowIndex][URIRepresentation] as! String],
                                              withIdentifier: DeleteNote, errorBlock: { (error: Error) in
                                                
                                                print(error)
            })
            
            self.rowIndex = rowIndex
        }
        
        let cancelAction = WKAlertAction(title: "Cancel", style: .cancel) { () -> Void in
            
            
        }
        
        self.presentAlert(withTitle: "Are you sure you want to delete URL \(self.notes[rowIndex]["url"]!)", message: nil, preferredStyle: .alert, actions: [deleteAction, cancelAction])
    }
}
