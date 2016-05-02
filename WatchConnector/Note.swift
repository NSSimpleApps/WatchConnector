//
//  Note.swift
//  WatchConnector
//
//  Created by NSSimpleApps on 07.03.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import Foundation
import CoreData


class Note: NSManagedObject {
    
    func toDictionary() -> [String: AnyObject] {
        
        var result = [String: AnyObject]()
        
        if let url = self.url {
            
            result["url"] = url
        }
        
        if let image = self.image {
            
            result["image"] = image
        }
        return result
    }
}
