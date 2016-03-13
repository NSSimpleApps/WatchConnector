//
//  WatchConnector.swift
//  WatchConnectorWatch Extension
//
//  Created by NSSimpleApps on 07.03.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import Foundation
import WatchConnectivity

private let WCMessageIdentifier = "WCMessageIdentifier"
private let WCDataDescription = "WCDataDescription"
private let WCDataIdentifier = "WCDataIdentifier"
private let WCData = "WCData"

public let WCApplicationContextDidChange = "WCApplicationContextDidChange"
public let WCDidReceiveUserInfo = "WCDidReceiveUserInfo"

public let WCSessionReachabilityDidChange = "WCSessionReachabilityDidChange"

#if os(iOS)
public let WCWatchStateDidChange = "WCWatchStateDidChange"
#endif

public let WCDidReceiveFileNotification = "WCDidReceiveFileNotification"

public let WCSessionFileURL = "WCSessionFileURL"
public let WCSessionFileMetadata = "WCSessionFileMetadata"


public typealias WCMessageType = [String : AnyObject]

public typealias WCMessageBlock = WCMessageType -> Void
public typealias WCReplyMessageBlock = WCMessageType -> WCMessageType

public typealias WCDataBlock = (NSData, String?) -> Void
public typealias WCReplyDataBlock = (NSData, String?) -> NSData

public typealias WCErrorBlock = NSError -> Void


@available(iOS 9.0, watchOS 2.0, *)
public class WatchConnector: NSObject, WCSessionDelegate {
    
    private var session: WCSession?
    
    private var messageBlocks: [String: WCMessageBlock] = [:]
    private var replyMessageBlocks: [String: WCReplyMessageBlock] = [:]
    
    private var dataBlocks: [String: WCDataBlock] = [:]
    private var replyDataBlocks: [String: WCReplyDataBlock] = [:]
    
    private let accessQueue = dispatch_queue_create("ns.simple.apps", DISPATCH_QUEUE_CONCURRENT)
    
    
    public class var shared: WatchConnector {
        
        struct Static {
            
            static var onceToken: dispatch_once_t = 0
            static var instance: WatchConnector!
        }
        
        dispatch_once(&Static.onceToken) {
            
            Static.instance = WatchConnector()
        }
        return Static.instance
    }
    
    override private init() {
        
        super.init()
    }
    
    public private(set) var isActivated: Bool = false
    
    public func activateSession() -> Bool {
        
        self.isActivated = WCSession.isSupported()
        
        if self.isActivated {
            
            self.session = WCSession.defaultSession()
            self.session?.delegate = self
            self.session?.activateSession()
        }
        return self.isActivated
    }
    
    public var receivedApplicationContext: [String: AnyObject] {
        
        return self.validSession?.receivedApplicationContext ?? [:]
    }
    
    public var applicationContext: [String: AnyObject] {
        
        return self.validSession?.applicationContext ?? [:]
    }
    
    #if os(watchOS)
    public var iOSDeviceNeedsUnlockAfterRebootForReachability: Bool {
        
        return self.validSession?.iOSDeviceNeedsUnlockAfterRebootForReachability ?? true
    }
    #endif
    
    private var reachableSession: WCSession? {
        
        if let validSession = self.validSession where validSession.reachable {
            
            return validSession
        }
        NSLog("WCSession is not reachable")
        
        return nil
    }
    
    private var validSession: WCSession? {
        
        if let session = self.session {
            
            #if os(iOS)
                
                guard session.paired else {
                    
                    NSLog("WCSession is not paired")
                    return nil
                }
                guard session.watchAppInstalled else {
                    
                    NSLog("Watch application is not installed")
                    return nil
                }
            #endif
            
            guard self.isEqual(session.delegate) else {
                
                NSLog("WCSession delegate is not equal to WatchConnector")
                return nil
            }
            
            return session
        }
        NSLog("WCSession is not activated")
        
        return nil
    }
    
    public func updateApplicationContext(context: [String : AnyObject]) throws {
        
        try self.validSession?.updateApplicationContext(context)
    }
    
    public var isReachable: Bool {
        
        return self.reachableSession != nil
    }
    
    public func listenToMessageBlock(messageBlock: WCMessageBlock, withIdentifier identifier: String) {
        
        dispatch_barrier_async(self.accessQueue) { () -> Void in
            
            self.messageBlocks[identifier] = messageBlock
        }
    }
    
    public func listenToReplyMessageBlock(replyMessageBlock: WCReplyMessageBlock, withIdentifier identifier: String) {
        
        dispatch_barrier_async(self.accessQueue) { () -> Void in
            
            self.replyMessageBlocks[identifier] = replyMessageBlock
        }
    }
    
    public func listenToDataBlock(dataBlock: WCDataBlock, withIdentifier identifier: String) {
        
        dispatch_barrier_async(self.accessQueue) { () -> Void in
            
            self.dataBlocks[identifier] = dataBlock
        }
    }
    
    public func listenToReplyDataBlock(replyDataBlock: WCReplyDataBlock, withIdentifier identifier: String) {
        
        dispatch_barrier_async(self.accessQueue) { () -> Void in
            
            self.replyDataBlocks[identifier] = replyDataBlock
        }
    }
    
    public func removeMessageBlockWithIdentifier(identifier: String) {
        
        dispatch_barrier_async(self.accessQueue) { () -> Void in
            
            self.messageBlocks[identifier] = nil
        }
    }
    
    public func removeReplyMessageBlockWithIdentifier(identifier: String) {
        
        dispatch_barrier_async(self.accessQueue) { () -> Void in
            
            self.replyMessageBlocks[identifier] = nil
        }
    }
    
    public func removeDataBlockWithIdentifier(identifier: String) {
        
        dispatch_barrier_async(self.accessQueue) { () -> Void in
            
            self.dataBlocks[identifier] = nil
        }
    }
    
    public func removeReplyDataBlockWithIdentifier(identifier: String) {
        
        dispatch_barrier_async(self.accessQueue) { () -> Void in
            
            self.replyDataBlocks[identifier] = nil
        }
    }
    
    public func sendMessage(var message: WCMessageType, withIdentifier identifier: String, replyBlock: WCMessageBlock, errorBlock: WCErrorBlock?) {
        
        message[WCMessageIdentifier] = identifier
        
        self.reachableSession?.sendMessage(message, replyHandler: { (reply: [String: AnyObject]) -> Void in
            
            replyBlock(reply)
            
            },
            errorHandler: { (error: NSError) -> Void in
                    
                errorBlock?(error)
        })
    }
    
    public func sendMessage(var message: WCMessageType, withIdentifier identifier: String, errorBlock: WCErrorBlock?) {
        
        message[WCMessageIdentifier] = identifier
        
        self.reachableSession?.sendMessage(message, replyHandler: nil, errorHandler: { (error: NSError) -> Void in
                
            errorBlock?(error)
        })
    }
    
    public func sendData(data: NSData, withIdentifier identifier: String, description: String, errorBlock: WCErrorBlock?) {
        
        let dataToSend = NSKeyedArchiver.archivedDataWithRootObject([WCDataIdentifier: identifier, WCDataDescription: description, WCData: data])
        
        self.reachableSession?.sendMessageData(dataToSend, replyHandler: nil, errorHandler: { (error: NSError) -> Void in
                
            errorBlock?(error)
        })
    }
    
    public func sendData(data: NSData, withIdentifier identifier: String, description: String, replyBlock: WCDataBlock, errorBlock: WCErrorBlock?) {
        
        let dataToSend = NSKeyedArchiver.archivedDataWithRootObject([WCDataIdentifier: identifier, WCDataDescription: description, WCData: data])
        
        self.reachableSession?.sendMessageData(dataToSend, replyHandler: { (replyData: NSData) -> Void in
            
            replyBlock(replyData, nil)
            },
            errorHandler: { (error: NSError) -> Void in
                    
            errorBlock?(error)
        })
    }
    
    public func transferFile(file: NSURL, metadata: [String : AnyObject]?) -> WCSessionFileTransfer? {
        
        return self.validSession?.transferFile(file, metadata: metadata)
    }
    
    // WCSessionDelegate
    
    #if os(iOS)
    public func sessionWatchStateDidChange(session: WCSession) {
    
        NSNotificationCenter.defaultCenter().postNotificationName(WCWatchStateDidChange, object: self, userInfo: nil)
    }
    #endif
    
    public func sessionReachabilityDidChange(session: WCSession) {
        
        let reachable = session.reachable
            
        NSNotificationCenter.defaultCenter().postNotificationName(WCSessionReachabilityDidChange, object: self, userInfo: ["reachable": reachable])
    }
    
    public func session(session: WCSession, var didReceiveMessage message: [String: AnyObject]) {
        
        let identifier = message[WCMessageIdentifier] as! String
        
        message[WCMessageIdentifier] = nil
        
        if let messageBlock = self.messageBlockForIdentifier(identifier) {
            
            messageBlock(message)
        }
    }
    
    public func session(session: WCSession, var didReceiveMessage message: [String : AnyObject], replyHandler: ([String: AnyObject]) -> Void) {
        
        let identifier = message[WCMessageIdentifier] as! String
        
        message[WCMessageIdentifier] = nil
        
        if let replyMessageBlock = self.replyMessageBlockForIdentifier(identifier) {
            
            replyHandler(replyMessageBlock(message))
        }
    }
    
    public func session(session: WCSession, didReceiveMessageData messageData: NSData) {
        
        if let receivedObject = NSKeyedUnarchiver.unarchiveObjectWithData(messageData) {
            
            let identifier = receivedObject[WCDataIdentifier] as! String
            
            if let dataBlock = self.dataBlockForIdentifier(identifier) {
                
                let description = receivedObject[WCDataDescription] as? String
                    
                dataBlock(receivedObject[WCData] as! NSData, description)
            }
            
        } else {
            
            NSLog("Cannot decode messageData")
        }
    }
    
    public func session(session: WCSession, didReceiveMessageData messageData: NSData, replyHandler: (NSData) -> Void) {
        
        if let receivedObject = NSKeyedUnarchiver.unarchiveObjectWithData(messageData) {
            
            let identifier = receivedObject[WCDataIdentifier] as! String
            
            if let replyDataBlock = self.replyDataBlockForIdentifier(identifier) {
                
                let description = receivedObject[WCDataDescription] as? String
                    
                replyHandler(replyDataBlock(receivedObject[WCData] as! NSData, description))
            }
            
        } else {
            
            NSLog("Cannot decode messageData")
        }
    }
    
    public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
            
        NSNotificationCenter.defaultCenter().postNotificationName(WCApplicationContextDidChange, object: self, userInfo: applicationContext)
    }
    
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String: AnyObject]) {
            
        NSNotificationCenter.defaultCenter().postNotificationName(WCDidReceiveUserInfo, object: self, userInfo: userInfo)
    }
    
    public func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        
        
    }
    
    public func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(WCDidReceiveFileNotification,
            object: self,
            userInfo: [WCSessionFileURL: file.fileURL, WCSessionFileMetadata: file.metadata ?? [:]])
        
        /*if let lastPathComponent = file.fileURL.lastPathComponent {
            
            let docURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
            
            NSFileManager.defaultManager().moveItemAtURL(<#T##srcURL: NSURL##NSURL#>, toURL: <#T##NSURL#>)
            
            docURL.URLByAppendingPathComponent(lastPathComponent)
        }
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            NSNotificationCenter.defaultCenter().postNotificationName(WCDidReceiveFileNotification,
                object: self,
                userInfo: [WCSessionFileURL: file.fileURL, WCSessionFileMetadata: file.metadata ?? [:]])
        }*/
    }
    
    ///////////////////
    public var outstandingUserInfoTransfers: [WCSessionUserInfoTransfer] {
        
        return self.validSession?.outstandingUserInfoTransfers ?? []
    }
    
    public func transferUserInfo(userInfo: [String: AnyObject]) -> WCSessionUserInfoTransfer? {
        
        return self.validSession?.transferUserInfo(userInfo)
    }
    
    deinit {
        
        self.messageBlocks.removeAll()
        self.replyMessageBlocks.removeAll()
        
        self.dataBlocks.removeAll()
        self.replyDataBlocks.removeAll()
    }
}

private extension WatchConnector { // access extension
    
    private func messageBlockForIdentifier(identifier: String) -> WCMessageBlock? {
        
        var messageBlock: WCMessageBlock?
        
        dispatch_sync(self.accessQueue) { () -> Void in
            
            messageBlock = self.messageBlocks[identifier]
        }
        return messageBlock
    }
    
    private func replyMessageBlockForIdentifier(identifier: String) -> WCReplyMessageBlock? {
        
        var replyMessageBlock: WCReplyMessageBlock?
        
        dispatch_sync(self.accessQueue) { () -> Void in
            
            replyMessageBlock = self.replyMessageBlocks[identifier]
        }
        return replyMessageBlock
    }
    
    private func dataBlockForIdentifier(identifier: String) -> WCDataBlock? {
        
        var dataBlock: WCDataBlock?
        
        dispatch_sync(self.accessQueue) { () -> Void in
            
            dataBlock = self.dataBlocks[identifier]
        }
        return dataBlock
    }
    
    private func replyDataBlockForIdentifier(identifier: String) -> WCReplyDataBlock? {
        
        var replyDataBlock: WCReplyDataBlock?
        
        dispatch_sync(self.accessQueue) { () -> Void in
            
            replyDataBlock = self.replyDataBlocks[identifier]
        }
        return replyDataBlock
    }
}