//
//  NSDate+CustomFormat.swift
//  WatchInteraction
//
//  Created by NSSimpleApps on 06.12.15.
//  Copyright © 2015 NSSimpleApps. All rights reserved.
//

import Foundation

extension Date {
    
    var customFormat: String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy HH:mm"
        
        return dateFormatter.string(from: self)
    }
}
