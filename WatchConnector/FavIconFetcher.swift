//
//  FavIconFetcher.swift
//  WatchInteraction
//
//  Created by NSSimpleApps on 20.11.15.
//  Copyright © 2015 NSSimpleApps. All rights reserved.
//

import UIKit

class FavIconFetcher: NSObject {
    
    class func fetchFavIconWithURL(var URL: NSURL, completionHandler: (NSData, NSURLResponse?) -> Void) {
        
        URL = URL.URLByAppendingPathComponent("favicon.ico")
        
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