//
//  FavIconLoader.swift
//  WatchInteraction
//
//  Created by NSSimpleApps on 20.11.15.
//  Copyright © 2015 NSSimpleApps. All rights reserved.
//

import UIKit

class FavIconLoader: NSObject {
    
    class func loadFavIcon(from host: String, completionHandler: @escaping (Data, URLResponse?) -> Void) {
        
        let components = NSURLComponents()
        components.host = host
        components.scheme = "http"
        components.path = "/favicon.ico"
        
        if let URL = components.url {
            
            let urlSession = URLSession(configuration: URLSessionConfiguration.default)
            
            let urlSessionDataTask = urlSession.dataTask(with: URL, completionHandler: { (data: Data?, responce: URLResponse?, error: Error?) in
                
                if error == nil && data != nil {
                    
                    DispatchQueue.main.async(execute: {
                        
                        completionHandler(data!, responce)
                    })
                }
            })
            
            urlSessionDataTask.resume()
        }
    }
}
