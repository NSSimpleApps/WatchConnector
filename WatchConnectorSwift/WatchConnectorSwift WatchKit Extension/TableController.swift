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
import WatchConnectivity


class TableController: WKInterfaceController {
    
    @IBOutlet var button: WKInterfaceButton!
    @IBOutlet var table: WKInterfaceTable!
    
    @IBOutlet var errorLabel: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        
        super.awakeWithContext(context)
        
        let nc = NSNotificationCenter.defaultCenter()
        
        nc.addObserver(self,
                       selector: #selector(self.didReceiveFile(_:)),
                       name: WCDidReceiveFileNotification,
                       object: WatchConnector.shared)
        
        WatchConnector.shared.listenToMessageBlock({ (message: WCMessageType) in
            
            dispatch_async(dispatch_get_main_queue(), {
                
                let cdm = CoreDataManager.shared
                
                let fm = NSFileManager.defaultManager()
                
                do {
                    
                    let content = try fm.contentsOfDirectoryAtURL(cdm.coreDataDirectory, includingPropertiesForKeys: nil, options: .SkipsSubdirectoryDescendants)
                    
                    let newStoreURL = content.filter({ (URL: NSURL) -> Bool in
                        
                        URL.pathExtension == "sqlite"
                    }).first!
                    
                    try cdm.migrateToNewStoreURL(newStoreURL)
                    
                    try self.reloadData()
                    
                } catch let error as NSError {
                    
                    print(error)
                }
            })
            
            }, withIdentifier: ReloadData)
    }
    
    func didReceiveFile(notification: NSNotification) {
        
        if let file = notification.userInfo?[WCSessionFileKey] as? WCSessionFile {
            
            let lastPathComponent = file.fileURL.lastPathComponent!
            
            let fm = NSFileManager.defaultManager()
            
            let URL = CoreDataManager.shared.coreDataDirectory.URLByAppendingPathComponent(lastPathComponent)
            
            do {
                
                if fm.fileExistsAtPath(URL.path!) {
                    
                    try fm.removeItemAtURL(URL)
                }
                
                try fm.moveItemAtURL(file.fileURL, toURL: URL)
                    
                } catch let error as NSError {
                    
                    print(#function, error.localizedDescription)
                }
        }
    }
    
    func reloadData() throws {
        
        let managedObjectContext = CoreDataManager.shared.managedObjectContext
        
        let entity = NSEntityDescription.entityForName(String(Note), inManagedObjectContext: managedObjectContext)
        
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entity
        fetchRequest.resultType = .DictionaryResultType
        
        let notes = try managedObjectContext.executeFetchRequest(fetchRequest) as! [[String: AnyObject]]
        
        let numberOfRows = notes.count
        
        if numberOfRows == 0 {
            
            self.table.setHidden(true)
            self.errorLabel.setHidden(false)
            self.errorLabel.setText("No notes")
            
        } else {
            
            self.table.setNumberOfRows(numberOfRows, withRowType: String(TableRowController))
            
            for index in (0..<numberOfRows) {
                
                let tableRowController = self.table.rowControllerAtIndex(index) as! TableRowController
                tableRowController.image.setImageData(notes[index]["image"] as? NSData)
                tableRowController.label.setText(notes[index]["url"] as? String)
            }
            self.table.setHidden(false)
            self.errorLabel.setHidden(true)
        }
    }
}


