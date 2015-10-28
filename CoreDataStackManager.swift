//
//  CoreDataStackManager.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/13/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import Foundation
import CoreData

private let SQLITE_FILE_NAME = "GasFill.sqlite"

class CoreDataStackManager {
    
    /* Welcome to the CoreDataStackManager! there's noting of any praticular importance going on here, honestly. Just most of the normal stuff for core data. Have you checked out the AddCarViewController? It's much more original, or my personal favorite: the GasTrackerViewController. It's a bit more... exciting! */
    
    class func sharedInstance() -> CoreDataStackManager {
        struct Static{
            static let instance = CoreDataStackManager()
        }
        
        return Static.instance
    }
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("FGasTrackerModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME)
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()


    lazy var managedObjectContext: NSManagedObjectContext? = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    func saveContext(){
        if let _ = self.managedObjectContext {
            if let context = self.managedObjectContext {
                var error: NSError? = nil
                if context.hasChanges {
                    do {
                        try context.save()
                    } catch let error1 as NSError {
                        error = error1
                        NSLog("Unresolved error \(error), \(error!.userInfo)")
                        abort()
                    }
                }
            }
        }
    }

}