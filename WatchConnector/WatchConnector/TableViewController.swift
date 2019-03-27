//
//  ViewController.swift
//  WatchConnector
//
//  Created by NSSimpleApps on 07.03.16.
//  Copyright © 2016 NSSimpleApps. All rights reserved.
//

import UIKit
import CoreData


class TableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.estimatedRowHeight = 80.0
        self.tableView.rowHeight = UITableView.automaticDimension
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.managedObjectContextDidSave(_:)),
                                               name: .NSManagedObjectContextDidSave,
                                               object: nil)
        WatchConnector.shared.addObserver(self,
                                          selector: #selector(self.didFinishFileTransfer(_:)),
                                          name: .WCDidFinishFileTransfer)
    }
    
    deinit {
        WatchConnector.shared.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func managedObjectContextDidSave(_ notification: Notification) {
        let context = notification.object as! NSManagedObjectContext
        
        if context.name == BackgroundContext {
            DispatchQueue.main.async{
                self.fetchedResultsController.managedObjectContext.mergeChanges(fromContextDidSave: notification)
            }
        }
    }
    
    @objc func didFinishFileTransfer(_ notification: Notification) {
        if let error = notification.userInfo?[NSUnderlyingErrorKey] as? Error {
            print(error)
            
        } else {
            let watchConnector = notification.object as! WatchConnector
            watchConnector.sendMessage([:],
                                       withIdentifier: ReloadData,
                                       errorBlock: nil)
        }
        DispatchQueue.main.async {
            self.navigationItem.leftBarButtonItem?.isEnabled = true
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let note = self.fetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = note.url
        cell.detailTextLabel?.text = note.timestamp!.customFormat
        
        if let data = note.image {
            cell.imageView?.image = UIImage(data: data)
        } else {
            cell.imageView?.image = nil
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.delete(self.fetchedResultsController.object(at: indexPath))
            
            do {
                try context.save()
                
            } catch let error as NSError {
                print("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }
    
    var fetchedResultsController: NSFetchedResultsController<Note> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let managedObjectContext = CoreDataManager.shared.managedObjectContext
        
        let entity = NSEntityDescription.entity(forEntityName: String(describing: Note.self), in: managedObjectContext)
        
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
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
    
    var _fetchedResultsController: NSFetchedResultsController<Note>!
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections([sectionIndex], with: .fade)
        case .delete:
            self.tableView.deleteSections([sectionIndex], with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type, indexPath, newIndexPath) {
        case (.insert, _, let new?):
            self.tableView.insertRows(at: [new], with: .fade)
            
        case (.delete, let ip?, _):
            self.tableView.deleteRows(at: [ip], with: .fade)
            
        case (.update, let ip?, _):
            self.tableView.reloadRows(at: [ip], with: .automatic)
            
        case (.move, let ip?, let new?):
            self.tableView.deleteRows(at: [ip], with: .fade)
            self.tableView.insertRows(at: [new], with: .fade)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
        
        do {
            try WatchConnector.shared.updateApplicationContext([UpdateUIKey: true, "Date": Date()])
            
        } catch let error as NSError {
            print(error)
        }
    }
    
    @IBAction func addURL(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Add URL") { (text: String) -> Void in
            FavIconLoader.loadFavIcon(from: text, completionHandler: { (data: Data, response: URLResponse?) in
                let managedObjectContext = self.fetchedResultsController.managedObjectContext
                
                let note = NSEntityDescription.insertNewObject(forEntityName: String(describing: Note.self), into: managedObjectContext) as! Note
                note.image = data
                note.url = response?.url?.host
                note.timestamp = Date()
                
                do {
                    try managedObjectContext.save()
                    
                } catch {
                    print(error)
                }
            })
        }
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func sendFile(_ sender: UIBarButtonItem) {
        sender.isEnabled = false
        
        let coreDataDirectory = CoreDataManager.shared.coreDataDirectory
        
        do {
            let content = try FileManager.default.contentsOfDirectory(at: coreDataDirectory, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
            
            for url in content {
                _ = WatchConnector.shared.transferFile(url, metadata: nil)
            }
            
        } catch let error as NSError {
            print(error)
            
            sender.isEnabled = true
        }
    }
}

