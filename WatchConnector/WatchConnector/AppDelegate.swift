//
//  AppDelegate.swift
//  WatchConnector
//
//  Created by NSSimpleApps on 18.09.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //WatchConnector.shared.activateSession()
        
        CoreDataManager.shared.initWatchInteraction()
        CoreDataManager.shared.initDeleteNote()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.watchStateDidChange(_:)),
                                               name: WCWatchStateDidChangeNotification,
                                               object: WatchConnector.shared)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sessionDidBecomeInactive(_:)),
                                               name: WCSessionDidBecomeInactiveNotification,
                                               object: WatchConnector.shared)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sessionDidDeactivate(_:)),
                                               name: WCSessionDidDeactivateNotification,
                                               object: WatchConnector.shared)
        
        WatchConnector.shared.activateSession()
        
        return true
    }
    
    func watchStateDidChange(_ notification: Notification) {
        
        print(#function, notification)
    }
    
    func sessionDidBecomeInactive(_ notification: Notification) {
        
        print(#function, notification)
    }
    
    func sessionDidDeactivate(_ notification: Notification) {
        
        print(#function, notification)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        
        CoreDataManager.shared.saveContext()
    }
}

