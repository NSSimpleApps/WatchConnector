//
//  CoreDataManager.swift
//  WatchConnector
//
//  Created by NSSimpleApps on 07.03.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import Foundation
import CoreData

let DataBaseName = "WatchConnector"


class CoreDataManager: NSObject {
    
    lazy var coreDataDirectory: URL = {
        
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent(DataBaseName)
        
        let fm = FileManager.default
        
        if !fm.fileExists(atPath: url.path) {
            
            do {
                
                try fm.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
                
            } catch let error as NSError {
                
                print(error)
                abort()
            }
        }
        return url
    }()
    
    var defaultPersistentStoreURL: URL {
        
        return self.coreDataDirectory.appendingPathComponent(String(format: "%@.sqlite", DataBaseName))
    }
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        
        let modelURL = Bundle.main.url(forResource: DataBaseName, withExtension: "momd")!
        
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.defaultPersistentStoreURL, options: nil)
            
        } catch let error as NSError {
            // Report any error we got.
            var dict = [String: Any]()
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
        
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        
        return managedObjectContext
    }()
    
    static let shared = CoreDataManager()
    
    private override init() {
        
        super.init()
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
