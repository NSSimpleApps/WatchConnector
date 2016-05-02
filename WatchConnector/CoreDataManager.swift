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
    
    lazy var coreDataDirectory: NSURL = {
        
        let URL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!.URLByAppendingPathComponent(DataBaseName)
        
        let fm = NSFileManager.defaultManager()
        
        if !fm.fileExistsAtPath(URL.path!) {
            
            do {
                
                try fm.createDirectoryAtURL(URL, withIntermediateDirectories: false, attributes: nil)
                
            } catch let error as NSError {
                
                print(error)
                abort()
            }
        }
        return URL
    }()
    
    var defaultPersistentStoreURL: NSURL {
        
        return self.coreDataDirectory.URLByAppendingPathComponent(String(format: "%@.sqlite", DataBaseName))
    }
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        
        let modelURL = NSBundle.mainBundle().URLForResource(DataBaseName, withExtension: "momd")!
        
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.defaultPersistentStoreURL, options: nil)
            
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
