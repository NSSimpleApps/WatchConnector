//
//  WatchConnector.swift
//  WatchConnectorWatch Extension
//
//  Created by NSSimpleApps on 07.03.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import Foundation
import WatchConnectivity

private let CMMessageIdentifier = "CMMessageIdentifier"
private let CMDataDescription = "CMDataDescription"
private let CMDataIdentifier = "CMDataIdentifier"
private let CMData = "CMData"

let ApplicationContextDidChange = "ApplicationContextDidChange"
let DidReceiveUserInfo = "DidReceiveUserInfo"

let SessionReachabilityDidChange = "SessionReachabilityDidChange"
let DidReceiveFileNotification = "DidReceiveFileNotification"


typealias MessageType = [String : AnyObject]

typealias VoidMessageBlock = MessageType -> Void
typealias ReplyMessageBlock = MessageType -> MessageType

typealias VoidDataBlock = (NSData, String?) -> Void
typealias ReplyDataBlock = (NSData, String?) -> NSData


typealias ErrorBlock = NSError -> Void


@available(iOS 9.0, watchOS 2.0, *)

class WatchConnector: NSObject, WCSessionDelegate {
    
    private var session: WCSession?
    
    private var voidMessageBlocks: [String : VoidMessageBlock] = [:]
    private var replyMessageBlocks: [String : ReplyMessageBlock] = [:]
    
    private var voidDataBlocks: [String : VoidDataBlock] = [:]
    private var replyDataBlocks: [String : ReplyDataBlock] = [:]
    
    private let q = dispatch_queue_create("ns.simple.apps", DISPATCH_QUEUE_CONCURRENT)
    
    
    class var shared: WatchConnector {
        
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
    
    private(set) var isActivated: Bool = false
    
    func activateSession() -> Bool {
        
        self.isActivated = WCSession.isSupported()
        
        if self.isActivated {
            
            self.session = WCSession.defaultSession()
            self.session?.delegate = self
            self.session?.activateSession()
            
            self.applicationContext = self.session?.applicationContext ?? [:]
        }
        return self.isActivated
    }
    
    var receivedApplicationContext: [String: AnyObject] {
        
        //return self.validSession?.receivedApplicationContext ?? [:]
        return self.session?.receivedApplicationContext ?? [:]
    }
    
    private(set) var applicationContext: [String : AnyObject] = [:]
    
    private var reachableSession: WCSession? {
        
        if let validSession = self.validSession where validSession.reachable {
            
            return validSession
        }
        NSLog("!!!!! WCSession is not reachable")
        
        return nil
    }
    
    private var validSession: WCSession? {
        
        if let session = self.session {
            
            #if os(iOS)
                
                guard session.paired else {
                    
                    NSLog("!!!!! WCSession is not paired")
                    return nil
                }
                guard session.watchAppInstalled else {
                    
                    NSLog("!!!!! Watch application is not installed")
                    return nil
                }
            #endif
            
            guard session.delegate != nil else {
                
                NSLog("!!!!! WCSession delegate is nil")
                return nil
            }
            
            guard session.delegate!.isEqual(self) else {
                
                NSLog("!!!!! WCSession delegate is not equal to ConnectivityManager")
                return nil
            }
            
            return session
        }
        NSLog("!!!!! WCSession is not activated")
        
        return nil
    }
    
    func updateApplicationContext(context: [String : AnyObject]) throws {
        
        dispatch_barrier_sync(self.q) { () -> Void in
            
            for (key, value) in context {
                
                self.applicationContext.updateValue(value, forKey: key)
            }
        }
        
        //try self.validSession?.updateApplicationContext(context)
        try self.session?.updateApplicationContext(context)
    }
    
    var isReachable: Bool {
        
        return self.reachableSession != nil
    }
    
    func addVoidMessageBlock(voidMessageBlock: VoidMessageBlock, identifier: String) {
        
        dispatch_barrier_async(self.q) { () -> Void in
            
            self.voidMessageBlocks[identifier] = voidMessageBlock
        }
    }
    
    func addReplyMessageBlock(replyMessageBlock: ReplyMessageBlock, identifier: String) {
        
        dispatch_barrier_async(self.q) { () -> Void in
            
            self.replyMessageBlocks[identifier] = replyMessageBlock
        }
    }
    
    func addVoidDataBlock(voidDataBlock: VoidDataBlock, identifier: String) {
        
        dispatch_barrier_async(self.q) { () -> Void in
            
            self.voidDataBlocks[identifier] = voidDataBlock
        }
    }
    
    func addReplyDataBlock(replyDataBlock: ReplyDataBlock, identifier: String) {
        
        dispatch_barrier_async(self.q) { () -> Void in
            
            self.replyDataBlocks[identifier] = replyDataBlock
        }
    }
    
    func removeVoidMessageBlockWithIdentifier(identifier: String) {
        
        dispatch_barrier_async(self.q) { () -> Void in
            
            self.voidMessageBlocks[identifier] = nil
        }
    }
    
    func removeReplyMessageBlockWithIdentifier(identifier: String) {
        
        dispatch_barrier_async(self.q) { () -> Void in
            
            self.replyMessageBlocks[identifier] = nil
        }
    }
    
    func removeVoidDataBlockWithIdentifier(identifier: String) {
        
        dispatch_barrier_async(self.q) { () -> Void in
            
            self.voidDataBlocks[identifier] = nil
        }
    }
    
    func removeReplyDataBlockWithIdentifier(identifier: String) {
        
        dispatch_barrier_async(self.q) { () -> Void in
            
            self.replyDataBlocks[identifier] = nil
        }
    }
    
    func sendMessage(var message: MessageType, identifier: String, replyBlock: VoidMessageBlock, errorBlock: ErrorBlock?) {
        
        message[CMMessageIdentifier] = identifier
        
        self.reachableSession?.sendMessage(message, replyHandler: { (reply: [String : AnyObject]) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                replyBlock(reply)
            })
            },
            errorHandler: { (error: NSError) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    errorBlock?(error)
                })
        })
    }
    
    func sendMessage(var message: MessageType, identifier: String, errorBlock: ErrorBlock?) {
        
        message[CMMessageIdentifier] = identifier
        
        self.reachableSession?.sendMessage(message, replyHandler: nil, errorHandler: { (error: NSError) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                errorBlock?(error)
            })
        })
    }
    
    func sendData(data: NSData, identifier: String, description: String, errorBlock: ErrorBlock?) {
        
        let dataToSend = NSKeyedArchiver.archivedDataWithRootObject([CMDataIdentifier: identifier, CMDataDescription: description, CMData: data])
        
        self.reachableSession?.sendMessageData(dataToSend, replyHandler: nil, errorHandler: { (error: NSError) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                errorBlock?(error)
            })
        })
    }
    
    func sendData(data: NSData, identifier: String, description: String, replyBlock: VoidDataBlock, errorBlock: ErrorBlock?) {
        
        let dataToSend = NSKeyedArchiver.archivedDataWithRootObject([CMDataIdentifier: identifier, CMDataDescription: description, CMData: data])
        
        self.reachableSession?.sendMessageData(dataToSend, replyHandler: { (replyData: NSData) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                replyBlock(replyData, nil)
            })
            },
            errorHandler: { (error: NSError) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    errorBlock?(error)
                })
        })
    }
    
    func transferFile(file: NSURL, metadata: [String : AnyObject]?) -> WCSessionFileTransfer? {
        
        return self.reachableSession?.transferFile(file, metadata: metadata)
    }
    
    // WCSessionDelegate
    
    func sessionReachabilityDidChange(session: WCSession) {
        
        let reachable = session.reachable
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            NSNotificationCenter.defaultCenter().postNotificationName(SessionReachabilityDidChange, object: reachable, userInfo: nil)
        }
    }
    
    func session(session: WCSession, var didReceiveMessage message: [String : AnyObject]) {
        
        let identifier = message[CMMessageIdentifier] as! String
        
        message[CMMessageIdentifier] = nil
        
        dispatch_async(self.q) { () -> Void in
            
            if let voidMessageBlock = self.voidMessageBlocks[identifier] {
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    voidMessageBlock(message)
                })
            }
        }
    }
    
    func session(session: WCSession, var didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        
        let identifier = message[CMMessageIdentifier] as! String
        
        message[CMMessageIdentifier] = nil
        
        dispatch_async(self.q) { () -> Void in
            
            if let replyMessageBlock = self.replyMessageBlocks[identifier] {
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    replyHandler(replyMessageBlock(message))
                })
            }
        }
    }
    
    func session(session: WCSession, didReceiveMessageData messageData: NSData) {
        
        if let receivedObject = NSKeyedUnarchiver.unarchiveObjectWithData(messageData) {
            
            let identifier = receivedObject[CMDataIdentifier] as! String
            
            dispatch_async(self.q) { () -> Void in
                
                if let voidDataBlock = self.voidDataBlocks[identifier] {
                    
                    let description = receivedObject[CMDataDescription] as? String
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        voidDataBlock(receivedObject[CMData] as! NSData, description)
                    })
                }
            }
            
        } else {
            
            NSLog("!!!!! Cannot decode messageData")
        }
    }
    
    func session(session: WCSession, didReceiveMessageData messageData: NSData, replyHandler: (NSData) -> Void) {
        
        if let receivedObject = NSKeyedUnarchiver.unarchiveObjectWithData(messageData) {
            
            let identifier = receivedObject[CMDataIdentifier] as! String
            
            dispatch_async(self.q) { () -> Void in
                
                if let replyDataBlock = self.replyDataBlocks[identifier] {
                    
                    let description = receivedObject[CMDataDescription] as? String
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        replyHandler(replyDataBlock(receivedObject[CMData] as! NSData, description))
                    })
                }
            }
            
        } else {
            
            NSLog("!!!!! Cannot decode messageData")
        }
    }
    
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        
        dispatch_barrier_sync(self.q) { () -> Void in
            
            for (key, value) in applicationContext {
                
                self.applicationContext.updateValue(value, forKey: key)
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            NSNotificationCenter.defaultCenter().postNotificationName(ApplicationContextDidChange, object: nil, userInfo: applicationContext)
        }
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        
        dispatch_barrier_sync(self.q) { () -> Void in
            
            self.userInfo = userInfo
        }
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            NSNotificationCenter.defaultCenter().postNotificationName(DidReceiveUserInfo, object: nil, userInfo: userInfo)
        }
    }
    
    func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        
        //print(__FUNCTION__)
    }
    
    ///////////////////
    var outstandingUserInfoTransfers: [WCSessionUserInfoTransfer]? {
        
        return self.validSession?.outstandingUserInfoTransfers
    }
    
    private(set) var userInfo: [String : AnyObject] = [:]
    
    func transferUserInfo(userInfo: [String : AnyObject]) -> WCSessionUserInfoTransfer? {
        
        return self.validSession?.transferUserInfo(userInfo)
    }
    
    deinit {
        
        self.voidMessageBlocks.removeAll()
        self.replyMessageBlocks.removeAll()
        
        self.voidDataBlocks.removeAll()
        self.replyDataBlocks.removeAll()
    }
}