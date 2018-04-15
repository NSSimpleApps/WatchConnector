//
//  ExtensionDelegate.swift
//  WatchConnectorWatch Extension
//
//  Created by NSSimpleApps on 07.03.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        let connector = WatchConnector.shared
        connector.addObserver(self,
                              selector: #selector(self.handleConnectorNotification(_:)),
                              name: .WCApplicationContextDidChange)
        connector.addObserver(self,
                              selector: #selector(self.handleConnectorNotification(_:)),
                              name: .WCDidReceiveUserInfo)
        
        connector.addObserver(self,
                              selector: #selector(self.handleConnectorNotification(_:)),
                              name: .WCSessionReachabilityDidChange)
        
        connector.addObserver(self,
                              selector: #selector(self.handleConnectorNotification(_:)),
                              name: .WCDidReceiveFile)
        connector.addObserver(self,
                              selector: #selector(self.handleConnectorNotification(_:)),
                              name: .WCDidFinishFileTransfer)
        
        if #available(watchOSApplicationExtension 2.2, *) {
            connector.addObserver(self,
                                  selector: #selector(self.handleConnectorNotification(_:)),
                                  name: .WCSessionActivationDidComplete)
        }
        
        WatchConnector.shared.activateSession()
    }
    
    @objc func handleConnectorNotification(_ notification: Notification) {
        print(notification)
        print("============================================================")
    }
}
