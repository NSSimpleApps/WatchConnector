//
//  Note.swift
//  WatchConnector
//
//  Created by NSSimpleApps on 07.03.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import Foundation
import CoreData


public class Note: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note");
    }
    
    @NSManaged public var timestamp: Date?
    @NSManaged public var url: String?
    @NSManaged public var image: Data?
    
    func toDictionary() -> [String: Any] {
        var result = [String: Any]()
        
        if let url = self.url {
            result["url"] = url
        }
        
        if let image = self.image {
            result["image"] = image
        }
        return result
    }
}
