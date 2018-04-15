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
    
    
    override func awake(withContext context: Any?) {
        
        super.awake(withContext: context)
        
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.didReceiveFile(_:)),
                       name: .WCDidReceiveFile,
                       object: WatchConnector.shared)
        
        WatchConnector.shared.listenToMessageBlock({ (message: WCMessageType) in
            
            DispatchQueue.main.async(execute: {
                
                let cdm = CoreDataManager.shared
                
                let fm = FileManager.default
                
                do {
                    
                    let content = try fm.contentsOfDirectory(at: cdm.coreDataDirectory, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
                    
                    let newStoreURL = content.first(where: { (url: URL) -> Bool in
                        
                        url.pathExtension == "sqlite"
                    })!
                    
                    try cdm.migrate(to: newStoreURL)
                    
                    try self.reloadData()
                    
                } catch let error as NSError {
                    
                    print(error)
                }
            })
            
            }, withIdentifier: ReloadData)
    }
    
    @objc func didReceiveFile(_ notification: Notification) {
        
        if let file = notification.userInfo?[WatchConnector.Keys.sessionFile] as? WCSessionFile {
            
            let lastPathComponent = file.fileURL.lastPathComponent
            
            let url = CoreDataManager.shared.coreDataDirectory.appendingPathComponent(lastPathComponent)
            
            do {
                
                let fm = FileManager.default
                
                if fm.fileExists(atPath: url.path) {
                    
                    try fm.removeItem(at: url)
                }
                
                try fm.moveItem(at: file.fileURL, to: url)
                    
                } catch let error as NSError {
                    
                    print(#function, error.localizedDescription)
                }
        }
    }
    
    func reloadData() throws {
        
        let managedObjectContext = CoreDataManager.shared.managedObjectContext
        
        let entity = NSEntityDescription.entity(forEntityName: String(describing: Note.self), in: managedObjectContext)
        
        let fetchRequest = NSFetchRequest<NSDictionary>()
        fetchRequest.entity = entity
        fetchRequest.resultType = .dictionaryResultType
        
        let notes = try managedObjectContext.fetch(fetchRequest)
        
        let numberOfRows = notes.count
        
        if numberOfRows == 0 {
            
            self.table.setHidden(true)
            self.errorLabel.setHidden(false)
            self.errorLabel.setText("No notes")
            
        } else {
            
            self.table.setNumberOfRows(numberOfRows, withRowType: String(describing: TableRowController.self))
            
            for index in (0..<numberOfRows) {
                
                let tableRowController = self.table.rowController(at: index) as! TableRowController
                tableRowController.image.setImageData(notes[index]["image"] as? Data)
                tableRowController.label.setText(notes[index]["url"] as? String)
            }
            self.table.setHidden(false)
            self.errorLabel.setHidden(true)
        }
    }
}


