//
//  TableController.swift
//  WatchConnectorWatch Extension
//
//  Created by NSSimpleApps on 07.03.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import WatchKit
import Foundation
import CoreData


class TableController: WKInterfaceController {
    
    @IBOutlet var button: WKInterfaceButton!
    @IBOutlet var table: WKInterfaceTable!
    
    @IBOutlet var errorLabel: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        
        super.awakeWithContext(context)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "didReceiveFile:",
            name: WCDidReceiveFileNotification,
            object: WatchConnector.shared)
    }
    
    func didReceiveFile(notification: NSNotification) {
        
        if let fileURL = notification.userInfo?[WCSessionFileURL] as? NSURL {
        
            dispatch_sync(dispatch_get_main_queue()) { () -> Void in
                
                CoreDataManager.shared.persistentStoreURL = fileURL
                
                let fetchRequest = NSFetchRequest(entityName: String(Note))
                
                let managedObjectContext = CoreDataManager.shared.managedObjectContext
                
                do {
                    
                    print(try managedObjectContext.executeFetchRequest(fetchRequest))
                    
                } catch let error as NSError {
                    
                    print(error)
                }
                
                self.button.setEnabled(true)
            }
        }
    }
    
    override func willActivate() {
        
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func requestData() {
        
        self.button.setEnabled(false)
        
        WatchConnector.shared.sendMessage([:],
            withIdentifier: FileRequest)
            { (error: NSError) -> Void in
                
                print(error)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.table.setHidden(true)
                    self.errorLabel.setHidden(false)
                    self.errorLabel.setText(error.localizedDescription)
                    
                    self.button.setEnabled(true)
                })
        }
    }
}
