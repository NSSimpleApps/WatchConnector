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
    
    private var images: [NSData] = []
    private var urls: [String] = []
    private var ids: [String] = []
    
    private var rowIndex: Int?
    
    override func awakeWithContext(context: AnyObject?) {
        
        super.awakeWithContext(context)
    }

    override func willActivate() {
        
        super.willActivate()
        
        if self.rowIndex != nil {
            
            self.urls.removeAtIndex(self.rowIndex!)
            table.removeRowsAtIndexes(NSIndexSet(index: self.rowIndex!))
            
            self.rowIndex = nil
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func requestData() {
        
        self.button.setEnabled(false)
        
        WatchConnector.shared.sendData(NSData(), withIdentifier: "RequestData", description: "", replyBlock: { (data: NSData, description: String?) -> Void in
            
            if let object = NSKeyedUnarchiver.unarchiveObjectWithData(data) {
                
                self.images = object["Images"] as! [NSData]
                self.urls = object["URLs"] as! [String]
                self.ids = object["IDs"] as! [String]
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.table.setHidden(false)
                    self.errorLabel.setHidden(true)
                    
                    let numberOfRows = self.images.count
                    
                    self.table.setNumberOfRows(numberOfRows, withRowType: String(TableRowController))
                    
                    for index in (0..<numberOfRows) {
                        
                        let tableRowController = self.table.rowControllerAtIndex(index) as! TableRowController
                        tableRowController.image.setImageData(self.images[index])
                        tableRowController.label.setText(self.urls[index])
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
            
            WatchConnector.shared.sendMessage(["id": self.ids[rowIndex]],
                withIdentifier: "RemoveNote",
                errorBlock: { (error: NSError) -> Void in
                    
                    print(error)
            })
            
            self.rowIndex = rowIndex
        }
        
        let cancelAction = WKAlertAction(title: "Cancel", style: .Cancel) { () -> Void in
            
            
        }
        
        self.presentAlertControllerWithTitle("Are you sure you want to delete URL \(self.urls[rowIndex])", message: nil, preferredStyle: WKAlertControllerStyle.Alert, actions: [deleteAction, cancelAction])
    }
}
