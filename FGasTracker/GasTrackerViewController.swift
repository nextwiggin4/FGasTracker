//
//  GasTrackerViewController.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/14/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import UIKit
import CoreData

class GasTrackerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    var userInfoDictionary : [String:AnyObject]!
    var currentCar: Car?
    let formatter = NSDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addGasStopTouchUp")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .Plain, target: self, action: "logoutTouchUp")
        

        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = .LongStyle
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let userInfo = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            userInfoDictionary = userInfo
        }
        
        do {
            try carFetchedResultsController.performFetch()
        } catch let error as NSError {
            print(error.localizedDescription)
            abort()
        }
        
        currentCar = nil
        
        for car in carFetchedResultsController.fetchedObjects! {
            if car.nickname == userInfoDictionary["currentCar"] as? String {
                currentCar = car as? Car
            }
        }
        
        _gasFillFetchedResultsController = nil
        
        do {
            try gasFillFetchedResultsController.performFetch()
            if gasFillFetchedResultsController.fetchedObjects!.isEmpty {
                getGasFills()
            }
            
        } catch let error as NSError {
            print(error.localizedDescription)
            abort()
        }
        
        gasFillFetchedResultsController.delegate = self
        tableView.reloadData()
        
    }
    
    lazy var carFetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Car")
        
        fetchRequest.sortDescriptors = []
        let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchResultsController
    }()
    
    var gasFillFetchedResultsController: NSFetchedResultsController {
        get {
            if let carCurrent = currentCar as Car! {
                
                if(_gasFillFetchedResultsController == nil){
                    let fetchRequest = NSFetchRequest(entityName: "GasFill")
        
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                    fetchRequest.predicate = NSPredicate(format: "car == %@", carCurrent)
                    _gasFillFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
                }
            
            } else {
                if(_gasFillFetchedResultsController == nil){
                    let fetchRequest = NSFetchRequest(entityName: "GasFill")
                    
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                    fetchRequest.predicate = NSPredicate(format: "car == %@", "NA")
                    _gasFillFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
                }
            }
            return _gasFillFetchedResultsController!
        }
        
        set {
            
        }
    }
    
    var _gasFillFetchedResultsController:NSFetchedResultsController?
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        return url.URLByAppendingPathComponent("userInfoArchive").path!
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.gasFillFetchedResultsController.sections![section]
        
        //print(sectionInfo.numberOfObjects)
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "GasFillCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! GasTrackerTableViewCell
        let fillup = gasFillFetchedResultsController.objectAtIndexPath(indexPath) as! GasFill
        
        configureCell(cell, fillup: fillup)
        return cell
        
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
            
            switch (editingStyle) {
            case .Delete:
                //Here we get the fillup object then delete it from parse
                let fillup = gasFillFetchedResultsController.objectAtIndexPath(indexPath) as! GasFill
                parse.sharedInstance().deleteFromParse(parse.Resources.GasFill, objectId: fillup.objectId!){JSONResults, error in
                    
                    if let error = error{
                        print(error)
                    } else {
                        //then delete it from core data
                        self.sharedContext.deleteObject(fillup)
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                }
                
            default:
                break
            }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("AddFillUpViewController") as! AddFillUpViewController
        controller.gasFillToEdit = gasFillFetchedResultsController.objectAtIndexPath(indexPath) as? GasFill
        self.navigationController!.pushViewController(controller, animated: true)
    }
    
    // MARK: - Fetched Results Controller Delegate
    
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
    
    //
    // This is the most interesting method. Take particular note of way the that newIndexPath
    // parameter gets unwrapped and put into an array literal: [newIndexPath!]
    //
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
            
            switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
                
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                
            case .Update:
                let cell = tableView.cellForRowAtIndexPath(indexPath!) as! GasTrackerTableViewCell
                let fillup = controller.objectAtIndexPath(indexPath!) as! GasFill
                self.configureCell(cell, fillup: fillup)
                
            case .Move:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
                
            default:
                return
            }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    func addGasStopTouchUp(){
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("AddFillUpViewController") as UIViewController
        self.navigationController!.pushViewController(controller, animated: true)
    }
    
    func logoutTouchUp(){
        parse.sharedInstance().logoutUser(userInfoDictionary["sessionToken"] as! String){JSONResults, error in
            
            if let error = error {
                print(error)
            } else {
                
                for car in self.carFetchedResultsController.fetchedObjects! {
                    self.sharedContext.deleteObject(car as! NSManagedObject)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                do {
                    try _ = NSFileManager.defaultManager().removeItemAtPath(self.filePath)
                } catch let error as NSError {
                    print(error.localizedDescription)
                    abort()
                }

            }
            
        }
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func configureCell(cell: GasTrackerTableViewCell, fillup: GasFill) {
        formatter.timeStyle = .NoStyle
        
        cell.gallonsLabel!.text = String(fillup.gallonsDecimal)
        cell.dateLabel!.text = formatter.stringFromDate(fillup.date)
        formatter.timeStyle = .LongStyle
    }
    
    func getGasFills(){
        
        if let carCurrent = currentCar {
            let methodArguments = [
                "where" : "{\"carObjectId\":\"" + carCurrent.objectId! as String! + "\"}"
            ]
            
            //print(methodArguments)
            parse.sharedInstance().getFromParse(parse.Resources.GasFill, methodArguments: methodArguments) {JSONResults, error in
            
                if let error = error{
                    print(error)
                } else {
                    if let gasFillInfo = JSONResults["results"] as? [[String:AnyObject]]{
                        for fillup in gasFillInfo {
                            //print(fillup)
                            //print("\n")
                            var newFillupDictionary = Dictionary<String, AnyObject>()
                        
                            if let totalMillage = fillup["totalMillage"]{
                                newFillupDictionary["totalMillage"] = totalMillage
                            }
                            if let currentTrip = fillup["currentTrip"]{
                                newFillupDictionary["currentTrip"] = currentTrip
                            }
                            if let gallons = fillup["gallons"]{
                                newFillupDictionary["gallons"] = gallons
                            }
                            if let pricePerGallon = fillup["pricePerGallon"]{
                                newFillupDictionary["pricePerGallon"] = pricePerGallon
                            }
                            if let totalCost = fillup["totalCost"]{
                                newFillupDictionary["totalCost"] = totalCost
                            }
                            
                            newFillupDictionary["car"] = carCurrent
                            
                            if let date = fillup["date"]{
                                
                                let dateString = date as! String
                                print(dateString)
                                newFillupDictionary["date"] = self.formatter.dateFromString(dateString)
                                print(newFillupDictionary["date"])
                            }
                            
                            if let completeFill = fillup["completeFill"]{
                                newFillupDictionary["completeFill"] = completeFill
                            }
                            
                            newFillupDictionary["objectId"] = fillup["objectId"]
                            newFillupDictionary["userObjectId"] = fillup["userObjectId"]
                            newFillupDictionary["carObjectId"] = fillup["carObjectId"]
                        
                            _ = GasFill(dictionary: newFillupDictionary, context: self.sharedContext)
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                    }
                }
            }
        }
    }
    
}
