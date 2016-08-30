//
//  FavIconLoader.swift
//  WatchInteraction
//
//  Created by NSSimpleApps on 20.11.15.
//  Copyright © 2015 NSSimpleApps. All rights reserved.
//

import UIKit

class FavIconLoader: NSObject {
    
    class func loadFavIconWithHost(host: String, completionHandler: (NSData, NSURLResponse?) -> Void) {
        
        let components = NSURLComponents()
        components.host = host
        components.scheme = "http"
        components.path = "/favicon.ico"
        
        if let URL = components.URL {
            
            let URLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
                
            let URLSessionDataTask =
            URLSession.dataTaskWithURL(URL) { (data: NSData?, URLResponse: NSURLResponse?, error: NSError?) -> Void in
                        
                    if error == nil && data != nil {
                            
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                
                            completionHandler(data!, URLResponse)
                        })
                    }
            }
            URLSessionDataTask.resume()
        }
    }
}
