//
//  InterfaceController.swift
//  WatchConnectorWatch Extension
//
//  Created by NSSimpleApps on 07.03.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController {

    @IBOutlet var button: WKInterfaceButton!
    @IBOutlet var table: WKInterfaceTable!
    
    @IBOutlet var errorLabel: WKInterfaceLabel!
    
    private var notes = [[String: AnyObject]]()
    
    private var rowIndex: Int?
    
    override func awakeWithContext(context: AnyObject?) {
        
        super.awakeWithContext(context)
        
        self.updateTitleWithContext(WatchConnector.shared.receivedApplicationContext)
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self,
                       selector: #selector(self.applicationContextDidChange(_:)),
                       name: WCApplicationContextDidChangeNotification,
                       object: WatchConnector.shared)
        
        //WCSessionDelegate
    }
    
    func updateTitleWithContext(context: [String: AnyObject]) {
        
        let title: String
        
        if let flag = context[NeedUpdateUI] as? Bool {
            
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
    
    func applicationContextDidChange(notification: NSNotification) {
        
        if let context = notification.userInfo as? [String: AnyObject] {
            
            dispatch_async(dispatch_get_main_queue(), {
                
                self.updateTitleWithContext(context)
            })
        }
    }
    
    override func willActivate() {
        
        super.willActivate()
        
        if self.rowIndex != nil {
            
            self.notes.removeAtIndex(self.rowIndex!)
            self.table.removeRowsAtIndexes(NSIndexSet(index: self.rowIndex!))
            
            self.rowIndex = nil
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func requestData() {
        
        self.button.setEnabled(false)
        
        WatchConnector.shared.sendData(NSData(), withIdentifier: DataRequest, description: nil, replyBlock: { (data: NSData, description: String?) -> Void in
            
            if let message = NSKeyedUnarchiver.unarchiveObjectWithData(data) {
                
                self.notes = message[Notes] as! [[String: AnyObject]]
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.table.setHidden(false)
                    self.errorLabel.setHidden(true)
                    
                    let numberOfRows = self.notes.count
                    
                    if numberOfRows == 0 {
                        
                        self.table.setHidden(true)
                        self.errorLabel.setHidden(false)
                        self.errorLabel.setText("No notes")
                        
                    } else {
                        
                        self.table.setNumberOfRows(numberOfRows, withRowType: String(TableRowController))
                        
                        for index in (0..<numberOfRows) {
                            
                            let tableRowController = self.table.rowControllerAtIndex(index) as! TableRowController
                            tableRowController.image.setImageData(self.notes[index]["image"] as? NSData)
                            tableRowController.label.setText(self.notes[index]["url"] as? String)
                        }
                        self.table.setHidden(false)
                        self.errorLabel.setHidden(true)
                    }
                    
                    self.button.setEnabled(true)
                })
            }
            
            }) { (error: NSError) -> Void in
                
                print(error)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.table.setHidden(true)
                    self.errorLabel.setHidden(false)
                    self.errorLabel.setText(error.localizedDescription)
                    
                    self.button.setEnabled(true)
                })
        }
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        
        let deleteAction = WKAlertAction(title: "Yes", style: .Default) { () -> Void in
            
            WatchConnector.shared.sendMessage([URIRepresentation: self.notes[rowIndex][URIRepresentation] as! String],
                withIdentifier: DeleteNote,
                errorBlock: { (error: NSError) -> Void in
                    
                    print(error)
            })
            
            self.rowIndex = rowIndex
        }
        
        let cancelAction = WKAlertAction(title: "Cancel", style: .Cancel) { () -> Void in
            
            
        }
        
        self.presentAlertControllerWithTitle("Are you sure you want to delete URL \(self.notes[rowIndex]["url"]!)", message: nil, preferredStyle: WKAlertControllerStyle.Alert, actions: [deleteAction, cancelAction])
    }
}
