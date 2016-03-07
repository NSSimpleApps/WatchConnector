//
//  NSDate+CustomFormat.swift
//  WatchInteraction
//
//  Created by NSSimpleApps on 06.12.15.
//  Copyright © 2015 NSSimpleApps. All rights reserved.
//

import Foundation

extension NSDate {
    
    var customFormat: String {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy HH:mm"
        
        return dateFormatter.stringFromDate(self)
    }
}