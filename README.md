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
Since version 1.0  `WatchConnector` uses internal NotificationCenter instead of default NotificationCenter.
Please use methods `-[WatchConnector addObserver:selector:name:]`, `-[WatchConnector removeObserver:selector:name:]`, `-[WatchConnector addObserver:]`.

```objc
class SomeViewController: UIViewController { // or InterfaceController
    override func viewDidLoad() {
        super.viewDidLoad()
        let connector = WatchConnector.shared
        // broadcast notifications
        connector.addObserver(self, selector: #selector(self.applicationContextDidChange(_:)), name: .WCApplicationContextDidChange)
        connector.addObserver(self, selector: #selector(self.didReceiveUserInfo(_:)), name: .WCDidReceiveUserInfo)
        connector.addObserver(self, selector: #selector(self.sessionReachabilityDidChange(_:)), name: .WCSessionReachabilityDidChange)
        connector.addObserver(self, selector: #selector(self.watchStateDidChange(_:)), name: .WCWatchStateDidChange)
        
        if #available(iOS 9.3, *) {
            connector.addObserver(self, selector: #selector(self.sessionDidBecomeInactive(_:)), name: .WCSessionDidBecomeInactive)
            connector.addObserver(self, selector: #selector(self.sessionDidDeactivate(_:)), name: .WCSessionDidDeactivate)
            connector.addObserver(self, selector: #selector(self.sessionActivationDidComplete(_:)), name: .WCSessionActivationDidComplete)
        }
        connector.addObserver(self, selector: #selector(self.didReceiveFile(_:)), name: .WCDidReceiveFile)
        connector.addObserver(self, selector: #selector(self.didFinishFileTransfer(_:)), name: .WCDidFinishFileTransfer)

        connector.listenToMessageBlock({ [unowned self] (message: WCMessageType) in
            //let someValue = message["SomeKey"] as! SomeType
            DispatchQueue.main.async {
                // update UI
            }
        },
            withIdentifier: "MessageIdentifier")
                        
        connector.listenToReplyMessageBlock({ (message: WCMessageType) -> WCMessageType in
            let someValue = message["SomeKey"] ?? ""
            return ["SomeKey": someValue]
            },
            withIdentifier: "SomeReplyMessageIdentifier")
            
        connector.listenToDataBlock({ [unowned self] (data: Data, description: String?) in
            let image = UIImage(data: data)
            DispatchQueue.main.async {
                self.imageView?.image = image
                self.title = description
            }
            },
            withIdentifier: "SomeDataIdentifier")
            
        connector.listenToReplyDataBlock({ (data: Data, description: String?) -> Data in
            let image = UIImage(named: description!)
            return UIImagePNGRepresentation(self.concatenateData(data, withImage: image))
            },
            withIdentifier: "SomeReplyDataIdentifier")
        }
        
        deinit { // Don't forget to remove blocks added in -[Self viewDidLoad]
            WatchConnector.shared.removeMessageBlock(with: "MessageIdentifier")
            WatchConnector.shared.removeReplyMessageBlock(with: "SomeReplyMessageIdentifier")
            WatchConnector.shared.removeDataBlock(with: "SomeDataIdentifier")
            WatchConnector.shared.removeReplyDataBlock(with: "SomeReplyDataIdentifier")
            WatchConnector.shared.removeObserver(self)
        }

    @objc func applicationContextDidChange(_ notification: Notification) {
        let context = notification.userInfo as! [String: Any]
        print(context)
        DispatchQueue.main.async {
            // update UI with context
        }
    }
    @objc func didReceiveUserInfo(_ notification: Notification) {
        let userInfo = notification.userInfo as! [String: Any]
        print(userInfo)
        DispatchQueue.main.async {
            // update UI with user info
        }
    }
    @objc func sessionReachabilityDidChange(_ notification: Notification) {
        let userInfo = notification.userInfo as! [String: Any]
        let reachable = userInfo[WatchConnector.Keys.sessionReachabilityState] as! Bool
        if #available(iOS 9.3, *) {
            let activationState = userInfo[WatchConnector.Keys.sessionActivationState] as! WCSessionActivationState
            print("activationState =", activationState)
        }
        DispatchQueue.main.async {
            // update UI with stuff
        }
        print("reachable =", reachable)
    }
    #if os(iOS)
    @objc func watchStateDidChange(_ notification: Notification) {
        let userInfo = notification.userInfo as! [String: Any]
        let reachable = userInfo[WatchConnector.Keys.sessionReachabilityState] as! Bool
        if #available(iOS 9.3, *) {
            let activationState = userInfo[WatchConnector.Keys.sessionActivationState] as! WCSessionActivationState
            print("activationState =", activationState)
            DispatchQueue.main.async {
                // update UI with stuff
            }
        }
        print("reachable =", reachable)
    }
    @objc @available(iOS 9.3, *)
    func sessionDidBecomeInactive(_ notification: Notification) {
        let userInfo = notification.userInfo as! [String: Any]
        let reachable = userInfo[WatchConnector.Keys.sessionReachabilityState] as! Bool
        let activationState = userInfo[WatchConnector.Keys.sessionActivationState] as! WCSessionActivationState
        print("activationState =", activationState)
        print("reachable =", reachable)
        DispatchQueue.main.async {
            // update UI with stuff
        }
    }
    @objc @available(iOS 9.3, *)
    func sessionDidDeactivate(_ notification: Notification) {
        let userInfo = notification.userInfo as! [String: Any]
        let reachable = userInfo[WatchConnector.Keys.sessionReachabilityState] as! Bool
        let activationState = userInfo[WatchConnector.Keys.sessionActivationState] as! WCSessionActivationState
        print("activationState =", activationState)
        print("reachable =", reachable)
        DispatchQueue.main.async {
            // update UI with stuff
        }
    }
    @objc @available(iOS 9.3, *)
    func sessionActivationDidComplete(_ notification: Notification) {
        let userInfo = notification.userInfo as! [String: Any]
        let reachable = userInfo[WatchConnector.Keys.sessionReachabilityState] as! Bool
        let activationState = userInfo[WatchConnector.Keys.sessionActivationState] as! WCSessionActivationState
        print("activationState =", activationState)
        print("reachable =", reachable)
        if let error = userInfo[NSUnderlyingErrorKey] as? Error {
            print("error =", error)
        }
        DispatchQueue.main.async {
            // update UI with stuff
        }
    }
    #endif
    @objc func didReceiveFile(_ notification: Notification) {
        let userInfo = notification.userInfo as! [String: Any]
        let file = userInfo[WatchConnector.Keys.sessionFile] as! WCSessionFile
        print("file =", file)
        DispatchQueue.main.async {
            // update UI with stuff
        }
    }
    @objc func didFinishFileTransfer(_ notification: Notification) {
        let userInfo = notification.userInfo as! [String: Any]
        let fileTransfer = userInfo[WatchConnector.Keys.sessionFileTransfer] as! WCSessionFileTransfer
        print("fileTransfer =", fileTransfer)
        if let error = userInfo[NSUnderlyingErrorKey] as? Error {
            print("error =", error)
        }
        DispatchQueue.main.async {
            // update UI with stuff
        }
    }
    func sendMessages() {
        WatchConnector.shared.sendMessage(["SomeKey": "SomeValue"],
                                          withIdentifier: "MessageIdentifier",
                                          errorBlock: { (error: Error) in
                                          DispatchQueue.main.async {
                                            // show alert
                                          }
                                          WatchConnector.shared.sendMessage(["SomeKey": "SomeValue"],
                                                                            withIdentifier: "SomeIdentifier",
                                                                            replyBlock: { (message: WCMessageType) in
                                                                            // do something with reply message
                                                                            DispatchQueue.main.async {
                                                                                // update UI with stuff
                                                                            }
                                            }, errorBlock: { (error: Error) in
                                                // show alert
                                            })
    })
    func sendData() {
        let someData = Data()
        WatchConnector.shared.sendData(someData,
                                       withIdentifier: "DataIdentifier",
                                       description: "SomeDescription",
                                       errorBlock: { (error: Error) in
                                        // show alert
        })
        WatchConnector.shared.sendData(someData,
                                       withIdentifier: "DataIndentifier",
                                       description: "SomeDescription",
                                       replyBlock: { (data: Data, description: String?) in
                                        // do something with data and description
                                        DispatchQueue.main.async {
                                            // update UI with stuff
                                        }
        }, errorBlock: { (error: Error) in
            // show alert
        })
    }
}
```
