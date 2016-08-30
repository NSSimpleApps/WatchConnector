//
//  WatchConnector.swift
//  WatchConnectorWatch Extension
//
//  Created by NSSimpleApps on 07.03.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import Foundation
import WatchConnectivity

private let WCMessageIdentifierKey = "WCMessageIdentifierKey"
private let WCDataDescriptionKey = "WCDataDescriptionKey"
private let WCDataIdentifierKey = "WCDataIdentifierKey"
private let WCDataKey = "WCDataKey"

@available(iOS 9.0, watchOS 2.0, *)
public let WCApplicationContextDidChangeNotification = "WCApplicationContextDidChangeNotification"
@available(iOS 9.0, watchOS 2.0, *)
public let WCDidReceiveUserInfoNotification = "WCDidReceiveUserInfoNotification"

@available(iOS 9.0, watchOS 2.0, *)
public let WCSessionReachabilityDidChangeNotification = "WCSessionReachabilityDidChangeNotification"
@available(iOS 9.0, watchOS 2.0, *)
public let WCReachableSessionKey = "WCReachableSessionKey"
@available(iOS 9.3, watchOS 2.2, *)
public let WCSessionActivationStateKey = "WCSessionActivationStateKey"

@available(iOS 9.3, watchOS 2.2, *)
public let WCSessionActivationDidCompleteNotification = "WCSessionActivationDidCompleteNotification"


#if os(iOS)
@available(iOS 9.0, *)
public let WCWatchStateDidChangeNotification = "WCWatchStateDidChangeNotification"

@available(iOS 9.3, *)
public let WCSessionDidBecomeInactiveNotification = "WCSessionDidBecomeInactiveNotification"
    
@available(iOS 9.3, *)
public let WCSessionDidDeactivateNotification = "WCSessionDidDeactivateNotification"
    
#endif

@available(iOS 9.0, watchOS 2.0, *)
public let WCDidReceiveFileNotification = "WCDidReceiveFileNotification"
@available(iOS 9.0, watchOS 2.0, *)
public let WCSessionFileKey = "WCSessionFileKey"

@available(iOS 9.0, watchOS 2.0, *)
public let WCDidFinishFileTransferNotification = "WCDidFinishFileTransferNotification"
@available(iOS 9.0, watchOS 2.0, *)
public let WCSessionFileTransferKey = "WCSessionFileTransferKey"

@available(iOS 9.0, watchOS 2.0, *)
public typealias WCMessageType = [String : AnyObject]

@available(iOS 9.0, watchOS 2.0, *)
public typealias WCMessageBlock = WCMessageType -> Void
@available(iOS 9.0, watchOS 2.0, *)
public typealias WCReplyMessageBlock = WCMessageType -> WCMessageType

@available(iOS 9.0, watchOS 2.0, *)
public typealias WCDataBlock = (NSData, String?) -> Void
@available(iOS 9.0, watchOS 2.0, *)
public typealias WCReplyDataBlock = (NSData, String?) -> NSData

@available(iOS 9.0, watchOS 2.0, *)
public typealias WCErrorBlock = NSError -> Void


@available(iOS 9.0, watchOS 2.0, *)
public class WatchConnector: NSObject {
    
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
    
    public func activateSession() {
        
        if WCSession.isSupported() {
            
            if #available(iOS 9.3, watchOS 2.2, *) {
                
                // self.session will be set in delegate method
                let session = WCSession.defaultSession()
                session.delegate = self
                session.activateSession()
                
            } else {
                
                self.session = WCSession.defaultSession()
                self.session?.delegate = self
                self.session?.activateSession()
            }
        }
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
    
    private var reachableSession: WCSession? {
        
        if let validSession = self.validSession where validSession.reachable {
            
            return validSession
        }
        NSLog("WCSession is not reachable")
        
        return nil
    }
    
    public func updateApplicationContext(context: [String : AnyObject]) throws {
        
        try self.validSession?.updateApplicationContext(context)
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
    
    public func sendMessage(message: WCMessageType, withIdentifier identifier: String, replyBlock: WCMessageBlock, errorBlock: WCErrorBlock?) {
        
        var messageToSend = message
        
        messageToSend[WCMessageIdentifierKey] = identifier
        
        self.reachableSession?.sendMessage(messageToSend, replyHandler: { (reply: [String: AnyObject]) -> Void in
            
            replyBlock(reply)
            
            },
            errorHandler: { (error: NSError) -> Void in
                    
                errorBlock?(error)
        })
    }
    
    public func sendMessage(message: WCMessageType, withIdentifier identifier: String, errorBlock: WCErrorBlock?) {
        
        var messageToSend = message
        
        messageToSend[WCMessageIdentifierKey] = identifier
        
        self.reachableSession?.sendMessage(messageToSend, replyHandler: nil, errorHandler: { (error: NSError) -> Void in
                
            errorBlock?(error)
        })
    }
    
    public func sendData(data: NSData, withIdentifier identifier: String, description: String?, errorBlock: WCErrorBlock?) {
        
        var message = [WCDataIdentifierKey: identifier, WCDataKey: data]
        
        if let description = description {
            
            message[WCDataDescriptionKey] = description
        }
        self.reachableSession?.sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message),
                                               replyHandler: nil,
                                               errorHandler: { (error: NSError) -> Void in
                                                errorBlock?(error)
        })
    }
    
    public func sendData(data: NSData, withIdentifier identifier: String, description: String?, replyBlock: WCDataBlock, errorBlock: WCErrorBlock?) {
        
        var message = [WCDataIdentifierKey: identifier, WCDataKey: data]
        
        if let description = description {
            
            message[WCDataDescriptionKey] = description
        }
        
        self.reachableSession?.sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message),
                                               replyHandler: { (replyData: NSData) -> Void in
            
            replyBlock(replyData, nil)
            },
                                               errorHandler: { (error: NSError) -> Void in
                                                errorBlock?(error)
        })
    }
    
    public func transferFile(file: NSURL, metadata: [String : AnyObject]?) -> WCSessionFileTransfer? {
        
        return self.reachableSession?.transferFile(file, metadata: metadata)
    }
    
    public func transferUserInfo(userInfo: [String: AnyObject]) -> WCSessionUserInfoTransfer? {
        
        return self.validSession?.transferUserInfo(userInfo)
    }
    
    #if os(iOS)
    public func transferCurrentComplicationUserInfo(userInfo: [String: AnyObject]) -> WCSessionUserInfoTransfer? {
        
        return self.validSession?.transferCurrentComplicationUserInfo(userInfo)
    }
    #endif
    
    deinit {
        
        self.messageBlocks.removeAll()
        self.replyMessageBlocks.removeAll()
        
        self.dataBlocks.removeAll()
        self.replyDataBlocks.removeAll()
    }
}

public extension WatchConnector { // extension for computed properties
    
    public var receivedApplicationContext: [String: AnyObject] {
        
        return self.validSession?.receivedApplicationContext ?? [:]
    }
    
    public var applicationContext: [String: AnyObject] {
        
        return self.validSession?.applicationContext ?? [:]
    }
    
    public var isReachable: Bool {
        
        return self.reachableSession != nil
    }
    
    #if os(watchOS)
    public var iOSDeviceNeedsUnlockAfterRebootForReachability: Bool {
        
        return self.validSession?.iOSDeviceNeedsUnlockAfterRebootForReachability ?? true
    }
    #endif
    
    #if(iOS)
    public var isPaired: Bool {
    
        return self.validSession?.paired ?? false
    }
    
    public var isWatchAppInstalled: Bool {
    
        return self.validSession?.isWatchAppInstalled ?? false
    }
    
    public var watchDirectoryURL: NSURL? {
    
        return self.validSession?.watchDirectoryURL
    }
    
    public var isComplicationEnabled: Bool {
    
        return self.validSession?.isComplicationEnabled ?? false
    }
    #endif
    
    public var outstandingFileTransfers: [WCSessionFileTransfer] {
        
        return self.validSession?.outstandingFileTransfers ?? []
    }
    
    public var outstandingUserInfoTransfers: [WCSessionUserInfoTransfer] {
        
        return self.validSession?.outstandingUserInfoTransfers ?? []
    }
    
    @available(iOS 9.3, watchOS 2.2, *)
    public var activationState: WCSessionActivationState {
        
        return self.validSession?.activationState ?? .NotActivated
    }
}

extension WatchConnector: WCSessionDelegate {
    
    @available(iOS 9.3, watchOS 2.2, *)
    public func session(session: WCSession, activationDidCompleteWithState activationState: WCSessionActivationState, error: NSError?) {
        
        if session.activationState == .NotActivated {
            
            self.session = nil
            
        } else {
            
            self.session = session
        }
        
        var userInfo: [String: AnyObject] = [WCReachableSessionKey: session.reachable,
                                             WCSessionActivationStateKey: session.activationState.rawValue]
        
        if let error = error {
            
            userInfo[NSUnderlyingErrorKey] = error
        }
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(WCSessionActivationDidCompleteNotification,
                                object: self,
                                userInfo: userInfo)
    }
    
    #if os(iOS)
    
    public func sessionWatchStateDidChange(session: WCSession) {
    
        var userInfo: [String: AnyObject] = [WCReachableSessionKey: session.reachable]
    
        if #available(iOS 9.3, *) {
    
            userInfo[WCSessionActivationStateKey] = session.activationState.rawValue
        }
    
        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(WCWatchStateDidChangeNotification,
                                object: self,
                                userInfo: userInfo)
    }
    
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(session: WCSession) {
    
        let userInfo: [String: AnyObject] = [WCReachableSessionKey: session.reachable,
                                            WCSessionActivationStateKey: session.activationState.rawValue]
    
        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(WCSessionDidBecomeInactiveNotification,
                                object: self,
                                userInfo: userInfo)
    }
    
    @available(iOS 9.3, *)
    public func sessionDidDeactivate(session: WCSession) {
    
        let userInfo: [String: AnyObject] = [WCReachableSessionKey: session.reachable,
                                            WCSessionActivationStateKey: session.activationState.rawValue]
    
        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(WCSessionDidBecomeInactiveNotification,
                                object: self,
                                userInfo: userInfo)
        }
    #endif
    
    public func sessionReachabilityDidChange(session: WCSession) {
        
        var userInfo: [String: AnyObject] = [WCReachableSessionKey: session.reachable]
        
        if #available(iOS 9.3, watchOS 2.2, *) {
            
            userInfo[WCSessionActivationStateKey] = session.activationState.rawValue
        }
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(WCSessionReachabilityDidChangeNotification,
                                object: self,
                                userInfo: userInfo)
    }
    
    public func session(session: WCSession, didReceiveMessage message: [String: AnyObject]) {
        
        let identifier = message[WCMessageIdentifierKey] as! String
        
        var receivedMessage = message
        
        receivedMessage[WCMessageIdentifierKey] = nil
        
        if let messageBlock = self.messageBlockForIdentifier(identifier) {
            
            messageBlock(receivedMessage)
        }
    }
    
    public func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String: AnyObject]) -> Void) {
        
        let identifier = message[WCMessageIdentifierKey] as! String
        
        var receivedMessage = message
        
        receivedMessage[WCMessageIdentifierKey] = nil
        
        if let replyMessageBlock = self.replyMessageBlockForIdentifier(identifier) {
            
            replyHandler(replyMessageBlock(receivedMessage))
        }
    }
    
    public func session(session: WCSession, didReceiveMessageData messageData: NSData) {
        
        if let receivedObject = NSKeyedUnarchiver.unarchiveObjectWithData(messageData) {
            
            let identifier = receivedObject[WCDataIdentifierKey] as! String
            
            if let dataBlock = self.dataBlockForIdentifier(identifier) {
                
                let description = receivedObject[WCDataDescriptionKey] as? String
                    
                dataBlock(receivedObject[WCDataKey] as! NSData, description)
            }
            
        } else {
            
            NSLog("Cannot decode messageData")
        }
    }
    
    public func session(session: WCSession, didReceiveMessageData messageData: NSData, replyHandler: (NSData) -> Void) {
        
        if let receivedObject = NSKeyedUnarchiver.unarchiveObjectWithData(messageData) {
            
            let identifier = receivedObject[WCDataIdentifierKey] as! String
            
            if let replyDataBlock = self.replyDataBlockForIdentifier(identifier) {
                
                let description = receivedObject[WCDataDescriptionKey] as? String
                    
                replyHandler(replyDataBlock(receivedObject[WCDataKey] as! NSData, description))
            }
            
        } else {
            
            NSLog("Cannot decode messageData")
        }
    }
    
    public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(WCApplicationContextDidChangeNotification,
                                object: self,
                                userInfo: applicationContext)
    }
    
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String: AnyObject]) {
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(WCDidReceiveUserInfoNotification,
                                object: self,
                                userInfo: userInfo)
    }
    
    public func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        
        var userInfo: [String: AnyObject] = [WCSessionFileTransferKey: fileTransfer]
        
        if let error = error {
            
            userInfo[NSUnderlyingErrorKey] = error
        }
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(WCDidFinishFileTransferNotification,
                                object: self,
                                userInfo: userInfo)
    }
    
    public func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        
        let userInfo: [String: AnyObject] = [WCSessionFileKey: file]
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(WCDidReceiveFileNotification,
                                object: self,
                                userInfo: userInfo)
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