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
        
        WatchConnector.shared.listenToReplyDataBlock({ (data: Data, description: String?) -> Data in
            
            let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator
            
            let fetchRequest = NSFetchRequest<Note>(entityName: String(describing: Note.self))
            fetchRequest.propertiesToFetch = ["image", "url"]
            
            do {
                
                let notes = try backgroundContext.fetch(fetchRequest)
                
                let results = notes.map({ (note: Note) -> [String: Any] in
                    
                    var d = note.toDictionary()
                    d[URIRepresentation] = note.objectID.uriRepresentation().absoluteString
                    
                    return d
                })
                
                return NSKeyedArchiver.archivedData(withRootObject: [Notes: results])
                
            } catch let error as NSError {
                
                print(error)
                
                return NSKeyedArchiver.archivedData(withRootObject: [Notes: []])
            }
            },
                                                     withIdentifier: DataRequest)
    }
    
    func initDeleteNote() {
        
        WatchConnector.shared.listenToMessageBlock({ (message: WCMessageType) -> Void in
            
            let id = message[URIRepresentation] as! String
            
            let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            backgroundContext.name = BackgroundContext
            backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator
            
            if let managedObjectID = self.persistentStoreCoordinator.managedObjectID(forURIRepresentation: URL(string: id)!), let object = backgroundContext.object(with: managedObjectID) as? Note {
                
                backgroundContext.delete(object)
                
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
