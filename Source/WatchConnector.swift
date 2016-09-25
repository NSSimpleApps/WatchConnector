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
public let WCApplicationContextDidChangeNotification = Notification.Name("WCApplicationContextDidChangeNotification")
@available(iOS 9.0, watchOS 2.0, *)
public let WCDidReceiveUserInfoNotification = Notification.Name("WCDidReceiveUserInfoNotification")

@available(iOS 9.0, watchOS 2.0, *)
public let WCSessionReachabilityDidChangeNotification = Notification.Name("WCSessionReachabilityDidChangeNotification")
@available(iOS 9.0, watchOS 2.0, *)
public let WCReachableSessionKey = "WCReachableSessionKey"
@available(iOS 9.3, watchOS 2.2, *)
public let WCSessionActivationStateKey = "WCSessionActivationStateKey"

@available(iOS 9.3, watchOS 2.2, *)
public let WCSessionActivationDidCompleteNotification = Notification.Name("WCSessionActivationDidCompleteNotification")


#if os(iOS)
@available(iOS 9.0, *)
public let WCWatchStateDidChangeNotification = Notification.Name("WCWatchStateDidChangeNotification")

@available(iOS 9.3, *)
public let WCSessionDidBecomeInactiveNotification = Notification.Name("WCSessionDidBecomeInactiveNotification")
    
@available(iOS 9.3, *)
public let WCSessionDidDeactivateNotification = Notification.Name("WCSessionDidDeactivateNotification")
    
#endif

@available(iOS 9.0, watchOS 2.0, *)
public let WCDidReceiveFileNotification = Notification.Name("WCDidReceiveFileNotification")
@available(iOS 9.0, watchOS 2.0, *)
public let WCSessionFileKey = "WCSessionFileKey"

@available(iOS 9.0, watchOS 2.0, *)
public let WCDidFinishFileTransferNotification = Notification.Name("WCDidFinishFileTransferNotification")
@available(iOS 9.0, watchOS 2.0, *)
public let WCSessionFileTransferKey = "WCSessionFileTransferKey"

@available(iOS 9.0, watchOS 2.0, *)
public typealias WCMessageType = [String : Any]

@available(iOS 9.0, watchOS 2.0, *)
public typealias WCMessageBlock = (WCMessageType) -> Void
@available(iOS 9.0, watchOS 2.0, *)
public typealias WCReplyMessageBlock = (WCMessageType) -> WCMessageType

@available(iOS 9.0, watchOS 2.0, *)
public typealias WCDataBlock = (Data, String?) -> Void
@available(iOS 9.0, watchOS 2.0, *)
public typealias WCReplyDataBlock = (Data, String?) -> Data

@available(iOS 9.0, watchOS 2.0, *)
public typealias WCErrorBlock = (Error) -> Void


@available(iOS 9.0, watchOS 2.0, *)
public class WatchConnector: NSObject {
    
    fileprivate var _session: WCSession?
    
    fileprivate var messageBlocks: [String: WCMessageBlock] = [:]
    fileprivate var replyMessageBlocks: [String: WCReplyMessageBlock] = [:]
    
    fileprivate var dataBlocks: [String: WCDataBlock] = [:]
    fileprivate var replyDataBlocks: [String: WCReplyDataBlock] = [:]
    
    fileprivate let accessQueue = DispatchQueue(label: "ns.simple.apps", attributes: .concurrent)
    
    
    public static let shared = WatchConnector()
    
    override private init() {
        
        super.init()
    }
    
    public func activateSession() {
        
        if WCSession.isSupported() {
            
            if #available(iOS 9.3, watchOS 2.2, *) {
                
                // self.session will be set in delegate method
                let session = WCSession.default()
                session.delegate = self
                session.activate()
                
            } else {
                
                self.session = WCSession.default()
                self.session?.delegate = self
                self.session?.activate()
            }
        }
    }
    
    fileprivate var validSession: WCSession? {
        
        if let session = self.session {
            
            #if os(iOS)
                
                guard session.isPaired else {
                    
                    NSLog("WCSession is not paired")
                    return nil
                }
                guard session.isWatchAppInstalled else {
                    
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
    
    fileprivate var reachableSession: WCSession? {
        
        if let validSession = self.validSession, validSession.isReachable {
            
            return validSession
        }
        NSLog("WCSession is not reachable")
        
        return nil
    }
    
    public func updateApplicationContext(_ context: [String : Any]) throws {
        
        try self.validSession?.updateApplicationContext(context)
    }
    
    public func listenToMessageBlock(_ messageBlock: @escaping WCMessageBlock, withIdentifier identifier: String) {
        
        self.accessQueue.async(flags: .barrier) {
            
            self.messageBlocks[identifier] = messageBlock
        }
    }
    
    public func listenToReplyMessageBlock(_ replyMessageBlock: @escaping WCReplyMessageBlock, withIdentifier identifier: String) {
        
        self.accessQueue.async(flags: .barrier) {
            
            self.replyMessageBlocks[identifier] = replyMessageBlock
        }
    }
    
    public func listenToDataBlock(_ dataBlock: @escaping WCDataBlock, withIdentifier identifier: String) {
        
        self.accessQueue.async(flags: .barrier) {
            
            self.dataBlocks[identifier] = dataBlock
        }
    }
    
    public func listenToReplyDataBlock(_ replyDataBlock: @escaping WCReplyDataBlock, withIdentifier identifier: String) {
        
        self.accessQueue.async(flags: .barrier) {
            
            self.replyDataBlocks[identifier] = replyDataBlock
        }
    }
    
    public func removeMessageBlock(with identifier: String) {
        
        self.accessQueue.async(flags: .barrier) {
            
            self.messageBlocks[identifier] = nil
        }
    }
    
    public func removeReplyMessageBlock(with identifier: String) {
        
        self.accessQueue.async(flags: .barrier) {
            
            self.replyMessageBlocks[identifier] = nil
        }
    }
    
    public func removeDataBlock(with identifier: String) {
        
        self.accessQueue.async(flags: .barrier) {
            
            self.dataBlocks[identifier] = nil
        }
    }
    
    public func removeReplyDataBlock(with identifier: String) {
        
        self.accessQueue.async(flags: .barrier) {
            
            self.replyDataBlocks[identifier] = nil
        }
    }
    
    public func sendMessage(_ message: WCMessageType, withIdentifier identifier: String, replyBlock: @escaping WCMessageBlock, errorBlock: WCErrorBlock?) {
        
        var messageToSend = message
        messageToSend[WCMessageIdentifierKey] = identifier
        
        self.reachableSession?.sendMessage(messageToSend, replyHandler: { (reply: [String : Any]) in
            
            replyBlock(reply)
            
            },
                                           errorHandler: { (error: Error) in
                                            errorBlock?(error)
        })
    }
    
    public func sendMessage(_ message: WCMessageType, withIdentifier identifier: String, errorBlock: WCErrorBlock?) {
        
        var messageToSend = message
        messageToSend[WCMessageIdentifierKey] = identifier
        
        self.reachableSession?.sendMessage(messageToSend, replyHandler: nil, errorHandler: { (error: Error) -> Void in
                
            errorBlock?(error)
        })
    }
    
    public func sendData(_ data: Data, withIdentifier identifier: String, description: String?, errorBlock: WCErrorBlock?) {
        
        var message: [String : Any] = [WCDataIdentifierKey: identifier, WCDataKey: data]
        
        if let description = description {
            
            message[WCDataDescriptionKey] = description
        }
        
        self.reachableSession?.sendMessageData(NSKeyedArchiver.archivedData(withRootObject: message), replyHandler: nil, errorHandler: { (error: Error) in
            
            errorBlock?(error)
        })
    }
    
    public func sendData(_ data: Data, withIdentifier identifier: String, description: String?, replyBlock: @escaping WCDataBlock, errorBlock: WCErrorBlock?) {
        
        var message: [String : Any] = [WCDataIdentifierKey: identifier, WCDataKey: data]
        
        if let description = description {
            
            message[WCDataDescriptionKey] = description
        }
        
        self.reachableSession?.sendMessageData(NSKeyedArchiver.archivedData(withRootObject: message),
                                               replyHandler: { (replyData: Data) in
                                                
                                                replyBlock(replyData, nil)
                                                
            }, errorHandler: { (error: Error) in
                
                errorBlock?(error)
        })
    }
    
    public func transferFile(_ file: URL, metadata: [String : Any]?) -> WCSessionFileTransfer? {
        
        return self.reachableSession?.transferFile(file, metadata: metadata)
    }
    
    public func transferUserInfo(userInfo: [String: Any]) -> WCSessionUserInfoTransfer? {
        
        return self.validSession?.transferUserInfo(userInfo)
    }
    
    #if os(iOS)
    public func transferCurrentComplicationUserInfo(userInfo: [String: Any]) -> WCSessionUserInfoTransfer? {
    
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
    
    public var receivedApplicationContext: [String: Any] {
        
        return self.validSession?.receivedApplicationContext ?? [:]
    }
    
    public var applicationContext: [String: Any] {
        
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
    
    public var watchDirectoryURL: URL? {
    
        return self.validSession?.watchDirectoryURL
    }
    
    public var isComplicationEnabled: Bool {
    
        return self.validSession?.isComplicationEnabled ?? false
    }
    
    @available(iOS 10.0, *)
    public var remainingComplicationUserInfoTransfers: Int {
    
        return self.validSession?.remainingComplicationUserInfoTransfers ?? 0
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
        
        return self.validSession?.activationState ?? .notActivated
    }
    
    @available(iOS 10.0, watchOS 3.0, *)
    public var hasContentPending: Bool {
        
        return self.validSession?.hasContentPending ?? false
    }
}

extension WatchConnector: WCSessionDelegate {
    
    @available(iOS 9.3, watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        if session.activationState == .notActivated {
            
            self.session = nil
            
        } else {
            
            self.session = session
        }
        
        var userInfo: [String: Any] = [WCReachableSessionKey: session.isReachable,
                                             WCSessionActivationStateKey: session.activationState]
        
        if let error = error {
            
            userInfo[NSUnderlyingErrorKey] = error
        }
        
        self.notificationCenter.post(name: WCSessionActivationDidCompleteNotification,
                object: self,
                userInfo: userInfo)
    }
    
    #if os(iOS)
    
    public func sessionWatchStateDidChange(_ session: WCSession) {
    
        var userInfo: [String: Any] = [WCReachableSessionKey: session.isReachable]
    
        if #available(iOS 9.3, *) {
    
            userInfo[WCSessionActivationStateKey] = session.activationState
        }
    
        self.notificationCenter.post(name: WCWatchStateDidChangeNotification,
                                object: self,
                                userInfo: userInfo)
    }
    
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {
    
        let userInfo: [String: Any] = [WCReachableSessionKey: session.isReachable,
                                            WCSessionActivationStateKey: session.activationState]
    
        self.notificationCenter.post(name:  WCSessionDidBecomeInactiveNotification,
                                object: self,
                                userInfo: userInfo)
    }
    
    @available(iOS 9.3, *)
    public func sessionDidDeactivate(_ session: WCSession) {
    
        let userInfo: [String: Any] = [WCReachableSessionKey: session.isReachable,
                                            WCSessionActivationStateKey: session.activationState]
    
        self.notificationCenter.post(name:  WCSessionDidBecomeInactiveNotification,
                                object: self,
                                userInfo: userInfo)
        }
    #endif
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        
        var userInfo: [String: Any] = [WCReachableSessionKey: session.isReachable]
        
        if #available(iOS 9.3, watchOS 2.2, *) {
            
            userInfo[WCSessionActivationStateKey] = session.activationState
        }
        
        self.notificationCenter.post(name: WCSessionReachabilityDidChangeNotification,
                                object: self,
                                userInfo: userInfo)
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        
        let identifier = message[WCMessageIdentifierKey] as! String
        
        var receivedMessage = message
        receivedMessage[WCMessageIdentifierKey] = nil
        
        if let messageBlock = self.messageBlock(for: identifier) {
            
            messageBlock(receivedMessage)
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Swift.Void) {
        
        let identifier = message[WCMessageIdentifierKey] as! String
        
        var receivedMessage = message
        
        receivedMessage[WCMessageIdentifierKey] = nil
        
        if let replyMessageBlock = self.replyMessageBlock(for: identifier) {
            
            replyHandler(replyMessageBlock(receivedMessage))
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        
        if let receivedObject = NSKeyedUnarchiver.unarchiveObject(with: messageData) as? WCMessageType {
            
            let identifier = receivedObject[WCDataIdentifierKey] as! String
            
            if let dataBlock = self.dataBlock(for: identifier) {
                
                let description = receivedObject[WCDataDescriptionKey] as? String
                    
                dataBlock(receivedObject[WCDataKey] as! Data, description)
            }
            
        } else {
            
            NSLog("Cannot decode messageData")
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Swift.Void) {
        
        if let receivedObject = NSKeyedUnarchiver.unarchiveObject(with: messageData) as? WCMessageType {
            
            let identifier = receivedObject[WCDataIdentifierKey] as! String
            
            if let replyDataBlock = self.replyDataBlock(for: identifier) {
                
                let description = receivedObject[WCDataDescriptionKey] as? String
                    
                replyHandler(replyDataBlock(receivedObject[WCDataKey] as! Data, description))
            }
            
        } else {
            
            NSLog("Cannot decode messageData")
        }
    }
    
    private var notificationCenter: NotificationCenter {
        
        return NotificationCenter.default
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        
        self.notificationCenter.post(name: WCApplicationContextDidChangeNotification,
                                object: self,
                                userInfo: applicationContext)
    }
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        
        self.notificationCenter.post(name: WCDidReceiveUserInfoNotification,
                                object: self,
                                userInfo: userInfo)
    }
    
    public func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        
        var userInfo: [String: Any] = [WCSessionFileTransferKey: fileTransfer]
        
        if let error = error {
            
            userInfo[NSUnderlyingErrorKey] = error
        }
        
        self.notificationCenter.post(name: WCDidFinishFileTransferNotification,
                                object: self,
                                userInfo: userInfo)
    }
    
    public func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
        let userInfo: [String: Any] = [WCSessionFileKey: file]
        
        self.notificationCenter.post(name:WCDidReceiveFileNotification,
                                object: self,
                                userInfo: userInfo)
    }
}

private extension WatchConnector { // access extension
    
    var session: WCSession? {
        
        get {
            
            var s: WCSession?
            
            self.accessQueue.sync {
                
                s = self._session
            }
            
            return s
        }
        
        set {
            
            self.accessQueue.async(flags: .barrier) {
                
                self._session = newValue
            }
        }
    }
    
    func messageBlock(for identifier: String) -> WCMessageBlock? {
        
        var messageBlock: WCMessageBlock?
        
        self.accessQueue.sync { 
            
            messageBlock = self.messageBlocks[identifier]
        }
        
        return messageBlock
    }
    
    func replyMessageBlock(for identifier: String) -> WCReplyMessageBlock? {
        
        var replyMessageBlock: WCReplyMessageBlock?
        
        self.accessQueue.sync {
            
            replyMessageBlock = self.replyMessageBlocks[identifier]
        }
        return replyMessageBlock
    }
    
    func dataBlock(for identifier: String) -> WCDataBlock? {
        
        var dataBlock: WCDataBlock?
        
        self.accessQueue.sync {
            
            dataBlock = self.dataBlocks[identifier]
        }
        return dataBlock
    }
    
    func replyDataBlock(for identifier: String) -> WCReplyDataBlock? {
        
        var replyDataBlock: WCReplyDataBlock?
        
        self.accessQueue.sync {
            
            replyDataBlock = self.replyDataBlocks[identifier]
        }
        return replyDataBlock
    }
}
