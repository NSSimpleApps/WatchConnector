# WatchConnector
WatchConnector is a tool for more convenient interaction between Watch and Phone.

![Alt text](https://github.com/NSSimpleApps/WatchConnector/blob/master/WatchConnector.gif)

Minimal deployment targets: `iOS 9.0`, `watchOS 2.0`

Installation guide: place this into `Podfile`
```
use_frameworks!
target 'PhoneTarget' do
    pod 'WatchConnector'
end
target 'WatchExtensionTarget' do
    pod 'WatchConnector'
end
```

Don't forget to activate `WCSession`:
```objc
// In AppDelegate
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    WatchConnector.shared.activateSession()
    return true
}

// In ExtensionDelegate
func applicationDidFinishLaunching() {
    WatchConnector.shared.activateSession()
}
```

Usage:
```objc
class SomeViewController { // or InterfaceController

override func viewDidLoad() {
    super.viewDidLoad()
    let nc = NSNotificationCenter.defaultCenter()
    // broadcast notifications
    nc.addObserver(self,
                   selector: #selector(self.applicationContextDidChange(_:)),
                   name: WCApplicationContextDidChangeNotification,
                   object: WatchConnector.shared)
    nc.addObserver(self,
                   selector: #selector(self.didReceiveUserInfo(_:)),
                   name: WCDidReceiveUserInfoNotification,
                   object: WatchConnector.shared)
    nc.addObserver(self,
                   selector: #selector(self.sessionReachabilityDidChange(_:)),
                   name: WCSessionReachabilityDidChangeNotification,
                   object: WatchConnector.shared)
    nc.addObserver(self,
                   selector: #selector(self.watchStateDidChange(_:)),
                   name: WCWatchStateDidChangeNotification,
                   object: WatchConnector.shared)
    if #available(iOS 9.3, *) {
        nc.addObserver(self,
                       selector: #selector(self.sessionDidBecomeInactive(_:)),
                       name: WCSessionDidBecomeInactiveNotification,
                       object: WatchConnector.shared)
        nc.addObserver(self,
                       selector: #selector(self.sessionDidDeactivate(_:)),
                       name: WCSessionDidDeactivateNotification,
                       object: WatchConnector.shared)
        nc.addObserver(self,
                       selector: #selector(self.sessionActivationDidComplete(_:)),
                       name: WCSessionActivationDidCompleteNotification,
                       object: WatchConnector.shared)
    }
    nc.addObserver(self,
                   selector: #selector(self.didReceiveFile(_:)),
                   name: WCDidReceiveFileNotification,
                   object: WatchConnector.shared)
    nc.addObserver(self,
                   selector: #selector(self.didFinishFileTransfer(_:)),
                   name: WCDidFinishFileTransferNotification,
                   object: WatchConnector.shared)

    WatchConnector.shared.listenToMessageBlock({ [unowned self] (message: WCMessageType) in
        let someValue = message["SomeKey"] as! SomeType
        dispatch_async(dispatch_get_main_queue(), {
            // update UI
    })
    },
    withIdentifier: "MessageIdentifier")
    
    WatchConnector.shared.listenToReplyMessageBlock({ [unowned self] (message: WCMessageType) -> WCMessageType in
        let someValue = message["SomeKey"] as! SomeType
        return ["SomeKey": self.someFunc(someValue)]
    },
    withIdentifier: "SomeReplyMessageIdentifier")
    
    WatchConnector.shared.listenToDataBlock({ [unowned self] (data: NSData, description: String?) in
        let image = UIImage(data: data)
        dispatch_async(dispatch_get_main_queue(), {
            self.imageView?.image = image
            self.title = description
        })
    },
    withIdentifier: "SomeDataIdentifier")

    WatchConnector.shared.listenToReplyDataBlock({ [unowned self] (data: NSData, description: String?) -> NSData in
        let image = UIImage(named: description!)
        return UIImagePNGRepresentation(self.concatenateData(data, withImage: image))
    },
    withIdentifier: "SomeReplyDataIdentifier")
}

deinit { // Don't forget to remove blocks added in -[Self viewDidLoad]
    WatchConnector.shared.removeMessageBlockWithIdentifier("MessageIdentifier")
    WatchConnector.shared.removeReplyMessageBlockWithIdentifier("SomeReplyMessageIdentifier")
    WatchConnector.shared.removeDataBlockWithIdentifier("SomeDataIdentifier")
    WatchConnector.shared.removeReplyDataBlockWithIdentifier("SomeReplyDataIdentifier")
    NSNotificationCenter.defaultCenter().remobeObserver(self)
}

func applicationContextDidChange(notification: NSNotification) {
    let context = notification.userInfo as! [String: AnyObject]
    dispatch_async(dispatch_get_main_queue(), {
        // update UI with context
    })
}
func didReceiveUserInfo(notification: NSNotification) {
    let userInfo = notification.userInfo as! [String: AnyObject]
    dispatch_async(dispatch_get_main_queue(), {
        // update UI with user info
    })
}
func sessionReachabilityDidChange(notification: NSNotification) {
    let userInfo = notification.userInfo as! [String: AnyObject]
    let reachable = userInfo[WCReachableSessionKey] as! Bool
    if #available(iOS 9.3, *) {
        let rawValue =
        userInfo[WCSessionActivationStateKey] as! Int
        let activationState = WCSessionActivationState(rawValue: rawValue)!
    }
    dispatch_async(dispatch_get_main_queue(), {
        // update UI with stuff
    })
}
#if os(iOS)
func watchStateDidChange(notification: NSNotification) {
    let userInfo = notification.userInfo as! [String: AnyObject]
    let reachable = userInfo[WCReachableSessionKey] as! Bool
    if #available(iOS 9.3, *) {
    let rawValue =
    userInfo[WCSessionActivationStateKey] as! Int
    let activationState = WCSessionActivationState(rawValue: rawValue)!
    dispatch_async(dispatch_get_main_queue(), {
        // update UI with stuff
    })
}
@available(iOS 9.3, *)
func sessionDidBecomeInactive(notification: NSNotification) {
    let userInfo = notification.userInfo as! [String: AnyObject]
    let reachable = userInfo[WCReachableSessionKey] as! Bool
    let rawValue = userInfo[WCSessionActivationStateKey] as! Int
    let activationState = WCSessionActivationState(rawValue: rawValue)!
    dispatch_async(dispatch_get_main_queue(), {
        // update UI with stuff
    })
}
@available(iOS 9.3, *)
func sessionDidDeactivate(notification: NSNotification) {
    let userInfo = notification.userInfo as! [String: AnyObject]
    let reachable = userInfo[WCReachableSessionKey] as! Bool
    let rawValue = userInfo[WCSessionActivationStateKey] as! Int
    let activationState = WCSessionActivationState(rawValue: rawValue)!
    dispatch_async(dispatch_get_main_queue(), {
        // update UI with stuff
    })
}
@available(iOS 9.3, *)
func sessionActivationDidComplete(notification: NSNotification) {
    let userInfo = notification.userInfo as! [String: AnyObject]
    let reachable = userInfo[WCReachableSessionKey] as! Bool
    let rawValue = userInfo[WCSessionActivationStateKey] as! Int
    let error = userInfo[NSUnderlyingErrorKey] as? NSError 
    let activationState = WCSessionActivationState(rawValue: rawValue)!
    dispatch_async(dispatch_get_main_queue(), {
        // update UI with stuff
    })
}
#endif
func didReceiveFile(notification: NSNotification) {
    let userInfo = notification.userInfo as! [String: AnyObject]
    let file = userInfo[WCSessionFileKey] as! WCSessionFile
    dispatch_async(dispatch_get_main_queue(), {
        // update UI with stuff
    })
}
func didFinishFileTransfer(notification: NSNotification) {
    let userInfo = notification.userInfo as! [String: AnyObject]
    let fileTransfer = [WCSessionFileTransferKey] as! WCSessionFileTransfer
    if let error = userInfo[NSUnderlyingErrorKey] as? NSError {
    }
    dispatch_async(dispatch_get_main_queue(), {
        // update UI with stuff
    })
}
func sendMessages() {
    WatchConnector.shared.sendMessage(["SomeKey": SomeValue],
    withIdentifier: "MessageIdentifier") { [weak self] (error: NSError) in
    dispatch_async(dispatch_get_main_queue(), {
        // show alert
    })
    WatchConnector.shared.sendMessage(["SomeKey": SomeValue],
    withIdentifier: "SomeIdentifier",
    replyBlock: { [weak self] (message: WCMessageType) in
        // do something with reply message
        dispatch_async(dispatch_get_main_queue(), {
        // update UI with stuff
        })
    }) { [weak self] (error: NSError) in
        // show alert
    }
}
func sendData() {
    WatchConnector.shared.sendData(someData,
    withIdentifier: "DataIdentifier",
    description: "SomeDescription") { [weak self] (error: NSError) in
        // show alert
    }
    WatchConnector.shared.sendData(someData,
    withIdentifier: "DataIndentifier",
    description: "SomeDescription",
    replyBlock: { [weak self] (data: NSData, description: String?) in
        // do something with data and description
        dispatch_async(dispatch_get_main_queue(), {
            // update UI with stuff
        })
    }) { [weak self] (error: NSError) in
        // show alert
    }
    }
}
```
