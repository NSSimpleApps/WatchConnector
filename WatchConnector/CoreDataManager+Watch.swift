//
//  CoreDataManager+Watch.swift
//  WatchConnector
//
//  Created by NSSimpleApps on 03.05.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import Foundation
import CoreData


extension CoreDataManager { // for watch stuff
    
    func migrateToNewStoreURL(newStoreURL: NSURL) throws {
        
        let currentStore = self.persistentStoreCoordinator.persistentStores.last!
        
        try self.persistentStoreCoordinator.removePersistentStore(currentStore)
        try self.persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: newStoreURL, options: nil)
    }
}
