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
    
    func migrate(to newStoreURL: URL) throws {
        
        let currentStore = self.persistentStoreCoordinator.persistentStores.last!
        
        try self.persistentStoreCoordinator.remove(currentStore)
        try self.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: newStoreURL, options: nil)
    }
}
