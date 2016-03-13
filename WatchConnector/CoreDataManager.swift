//
//  CoreDataManager.swift
//  WatchConnector
//
//  Created by NSSimpleApps on 07.03.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import Foundation
import CoreData


class CoreDataManager: NSObject {
    
    lazy var applicationDocumentsDirectory: NSURL = {
        
        let URLs = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        
        return URLs.last!
    }()
    
    var persistentStoreURL: NSURL!
    
    var defaultPersistentStoreURL: NSURL {
        
        return self.applicationDocumentsDirectory.URLByAppendingPathComponent("WatchConnector.sqlite")
    }
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        
        let modelURL = NSBundle.mainBundle().URLForResource("WatchConnector", withExtension: "momd")!
        
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.persistentStoreURL, options: nil)
            
        } catch let error as NSError {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        
        let coordinator = self.persistentStoreCoordinator
        
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        
        return managedObjectContext
    }()
    
    class var shared: CoreDataManager {
        
        struct Static {
            
            static var onceToken: dispatch_once_t = 0
            static var instance: CoreDataManager!
        }
        
        dispatch_once(&Static.onceToken) {
            
            Static.instance = CoreDataManager()
        }
        return Static.instance
    }
    
    private override init() {
        
        super.init()
        
        self.persistentStoreURL = self.defaultPersistentStoreURL
    }
    
    func saveContext () {
        
        if managedObjectContext.hasChanges {
            
            do {
                
                try managedObjectContext.save()
                
            } catch let error as NSError {
                
                NSLog("Unresolved error \(error), \(error.userInfo)")
                
                abort()
            }
        }
    }
}

#if os(iOS)
extension CoreDataManager { // for request all entities
    
    func initWatchInteraction() {
        
        WatchConnector.shared.listenToReplyDataBlock({ (data: NSData, description: String?) -> NSData in
            
            let backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator
            
            
            let fetchRequest = NSFetchRequest(entityName: String(Note))
            fetchRequest.propertiesToFetch = ["image", "url"]
            
            var images: [NSData] = []
            var urls: [String] = []
            var ids: [String] = []
            
            do {
                
                let notes = try backgroundContext.executeFetchRequest(fetchRequest) as! [Note]
                
                for note in notes {
                    
                    urls.append(note.url ?? "")
                    images.append(note.image ?? NSData())
                    ids.append(note.objectID.URIRepresentation().absoluteString)
                }
                
            } catch let error as NSError {
                
                print(error)
            }
            
            return NSKeyedArchiver.archivedDataWithRootObject(["Images": images, "URLs": urls, "IDs": ids])
            
            },
            withIdentifier: DataRequest)
    }
    
    func initDeleteEntity() {
        
        WatchConnector.shared.listenToMessageBlock({ (message: WCMessageType) -> Void in
            
            let id = message["id"] as! String
            
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
            withIdentifier: RemoveNote)
    }
    
    func initFileRequest() {
        
        WatchConnector.shared.listenToMessageBlock({ (message: WCMessageType) -> Void in
            
            WatchConnector.shared.transferFile(self.persistentStoreURL,
                metadata: nil)
            
            },
            withIdentifier: FileRequest)
    }
    
}
#endif