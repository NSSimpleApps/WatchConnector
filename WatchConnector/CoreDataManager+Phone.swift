//
//  CoreDataManager+Phone.swift
//  WatchConnector
//
//  Created by NSSimpleApps on 02.05.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import Foundation
import CoreData

let BackgroundContext = "BackgroundContext"

extension CoreDataManager { // for watch request
    
    func initWatchInteraction() {
        
        WatchConnector.shared.listenToReplyDataBlock({ (data: NSData, description: String?) -> NSData in
            
            let backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator
            
            let fetchRequest = NSFetchRequest(entityName: String(Note))
            fetchRequest.propertiesToFetch = ["image", "url"]
            
            var result = [[String: AnyObject]]()
            
            do {
                
                let notes = try backgroundContext.executeFetchRequest(fetchRequest) as! [Note]
                
                for note in notes {
                    
                    var d = note.toDictionary()
                    d[URIRepresentation] = note.objectID.URIRepresentation().absoluteString
                    
                    result.append(d)
                }
                
                return NSKeyedArchiver.archivedDataWithRootObject([Notes: result])
                
            } catch let error as NSError {
                
                print(error)
                
                return NSKeyedArchiver.archivedDataWithRootObject([Notes: []])
            }
            },
                                                     withIdentifier: DataRequest)
    }
    
    func initDeleteNote() {
        
        WatchConnector.shared.listenToMessageBlock({ (message: WCMessageType) -> Void in
            
            let id = message[URIRepresentation] as! String
            
            let backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            backgroundContext.name = BackgroundContext
            backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator
            
            if let managedObjectID = self.persistentStoreCoordinator.managedObjectIDForURIRepresentation(NSURL(string: id)!), let object = backgroundContext.objectWithID(managedObjectID) as? Note {
                
                backgroundContext.deleteObject(object)
                do {
                    
                    try backgroundContext.save()
                    
                } catch let error as NSError {
                    
                    print(error)
                }
            }
            
            },
                                                   withIdentifier: DeleteNote)
    }
}