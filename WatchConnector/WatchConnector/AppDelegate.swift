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
                                               name: .WCWatchStateDidChange,
                                               object: WatchConnector.shared)
        
        if #available(iOS 9.3, *) {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.sessionDidBecomeInactive(_:)),
                                                   name: .WCSessionDidBecomeInactive,
                                                   object: WatchConnector.shared)
        } else {
            
        }
        
        if #available(iOS 9.3, *) {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.sessionDidDeactivate(_:)),
                                                   name: .WCSessionDidDeactivate,
                                                   object: WatchConnector.shared)
        } else {
            // Fallback on earlier versions
        }
        
        WatchConnector.shared.activateSession()
        
        return true
    }
    
    @objc func watchStateDidChange(_ notification: Notification) {
        
        print(#function, notification)
    }
    
    @objc func sessionDidBecomeInactive(_ notification: Notification) {
        
        print(#function, notification)
    }
    
    @objc func sessionDidDeactivate(_ notification: Notification) {
        
        print(#function, notification)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        
        CoreDataManager.shared.saveContext()
    }
}

