//
//  ViewController.swift
//  WatchConnector
//
//  Created by NSSimpleApps on 07.03.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import UIKit
import CoreData
import WatchConnectivity

class TableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tableView.estimatedRowHeight = 80.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self,
                       selector: #selector(self.managedObjectContextDidSave(_:)),
                       name: NSManagedObjectContextDidSaveNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(self.didFinishFileTransfer(_:)),
                       name: WCDidFinishFileTransferNotification,
                       object: WatchConnector.shared)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func managedObjectContextDidSave(notification: NSNotification) {
        
        let context = notification.object as! NSManagedObjectContext
        
        if context.name == BackgroundContext {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.fetchedResultsController.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
            })
        }
    }
    
    func didFinishFileTransfer(notification: NSNotification) {
        
        if let error = notification.userInfo?[NSUnderlyingErrorKey] as? NSError {
            
            print(error)
            
        } else {
            
            let watchConnector = notification.object as! WatchConnector
            watchConnector.sendMessage([:],
                                       withIdentifier: ReloadData,
                                       errorBlock: nil)
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.navigationItem.leftBarButtonItem?.enabled = true
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let note = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Note
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.text = note.url
        cell.detailTextLabel?.text = note.timestamp!.customFormat
        
        if let data = note.image {
            
            cell.imageView?.image = UIImage(data: data)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
            
            do {
                try context.save()
            } catch let error as NSError {
                
                print("Unresolved error \(error), \(error.userInfo)")
                
                abort()
            }
        }
    }
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let managedObjectContext = CoreDataManager.shared.managedObjectContext
        
        let entity = NSEntityDescription.entityForName(String(Note), inManagedObjectContext: managedObjectContext)
        
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entity
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        _fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        _fetchedResultsController.delegate = self
        
        do {
            
            try _fetchedResultsController.performFetch()
            
        } catch let error as NSError {
            
            print("Unresolved error \(error), \(error.userInfo)")
            
            abort()
        }
        
        return _fetchedResultsController
    }
    var _fetchedResultsController: NSFetchedResultsController!
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            
        case .Delete:
            
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            
        case .Update:
            
            self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            
        case .Move:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        self.tableView.endUpdates()
        
        do {
            
            try WatchConnector.shared.updateApplicationContext([NeedUpdateUI: true])
            
        } catch let error as NSError {
            
            print(error)
        }
    }
    
    @IBAction func addURL(sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: "Add URL") { (text: String) -> Void in
            
            FavIconFetcher.fetchFavIconWithAddress(text, completionHandler: { (data: NSData, URLResponse: NSURLResponse?) -> Void in
                
                let managedObjectContext = self.fetchedResultsController.managedObjectContext
                
                let note = NSEntityDescription.insertNewObjectForEntityForName(String(Note), inManagedObjectContext: managedObjectContext) as! Note
                
                note.image = data
                note.url = URLResponse?.URL?.host
                note.timestamp = NSDate()
                
                do {
                    
                    try managedObjectContext.save()
                    
                } catch let error as NSError {
                    
                    print(error)
                }
            })
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func sendFile(sender: UIBarButtonItem) {
        
        sender.enabled = false
        
        let URL = CoreDataManager.shared.coreDataDirectory
        
        do {
            
            let content = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(URL,includingPropertiesForKeys: nil, options: .SkipsSubdirectoryDescendants)
            
            for url in content {
                
                WatchConnector.shared.transferFile(url, metadata: nil)
            }
            
        } catch let error as NSError {
            
            print(error)
            
            sender.enabled = true
        }
    }
}

