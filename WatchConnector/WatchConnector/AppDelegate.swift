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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        CoreDataManager.shared.initWatchInteraction()
        CoreDataManager.shared.initDeleteNote()
        
        let connector = WatchConnector.shared
        connector.addObserver(self,
                              selector: #selector(self.handleNotification(_:)),
                              name: .WCApplicationContextDidChange)
        connector.addObserver(self,
                              selector: #selector(self.handleNotification(_:)),
                              name: .WCDidReceiveUserInfo)
        
        connector.addObserver(self,
                              selector: #selector(self.handleNotification(_:)),
                              name: .WCSessionReachabilityDidChange)
        connector.addObserver(self,
                              selector: #selector(self.handleNotification(_:)),
                              name: .WCWatchStateDidChange)
        
        connector.addObserver(self,
                              selector: #selector(self.handleNotification(_:)),
                              name: .WCDidReceiveFile)
        connector.addObserver(self,
                              selector: #selector(self.handleNotification(_:)),
                              name: .WCDidFinishFileTransfer)
        
        connector.addObserver(self,
                              selector: #selector(self.handleNotification(_:)),
                              name: .WCSessionActivationDidComplete)
        connector.addObserver(self,
                              selector: #selector(self.handleNotification(_:)),
                              name: .WCSessionDidBecomeInactive)
        connector.addObserver(self,
                              selector: #selector(self.handleNotification(_:)),
                              name: .WCSessionDidDeactivate)
        
        WatchConnector.shared.activateSession()
        
        return true
    }
    
    @objc func handleNotification(_ notification: Notification) {
        print(notification)
        print("============================================================")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        CoreDataManager.shared.saveContext()
    }
}

