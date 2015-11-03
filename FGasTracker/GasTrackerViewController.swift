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
    
    /* this class controlls the main gasTracker view. Here we will display the calculated average MPG and a list of all the gas fills */
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var selectedCarLabel: UILabel!
    @IBOutlet weak var mpgLabel: UILabel!
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    var userInfoDictionary : [String:AnyObject]!
    var currentCar: Car?
    let formatter = NSDateFormatter()
    
    //initialize an instance of the MPGCalculator with the desired significant figures.
    let mpgCalc = MPGCalculator(sigfig: 2)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add a logout button and a add fill up button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addGasStopTouchUp")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .Plain, target: self, action: "logoutTouchUp")
        
        //create a date formater and set it's style
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = .LongStyle
        
        //We must manually set the tableview delegate since it's a subview of the class.
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //grab the userInfoDictionary
        if let userInfo = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            userInfoDictionary = userInfo
        }
        
        //We need two fetchedResultsControllers, one for the cars and one for the gas fills. Fet the cars info first.
        do {
            try carFetchedResultsController.performFetch()
        } catch let error as NSError {
            print(error.localizedDescription)
            abort()
        }
        
        //if the current car changed in the AddFillUpView then we need to reset the current car. First set it to nill, then run through the fetchedResultsController to get the managedObject
        currentCar = nil
        
        for car in carFetchedResultsController.fetchedObjects! {
            if car.nickname == userInfoDictionary["currentCar"] as? String {
                currentCar = car as? Car
            }
        }
        
        //This is black magic. Refer to the gasFillFetchedResultsController to see why.
        _gasFillFetchedResultsController = nil
        
        //perform a fetch for the gasFillFetchedResultsController
        do {
            try gasFillFetchedResultsController.performFetch()
            
            if let currentCar = currentCar {
                if currentCar.checkParseForGasFills {
                    //this function will check parse for any gasFill objects stored on the server.
                    getGasFills()
                }
            }
            
        } catch let error as NSError {
            throwAlert(error.localizedDescription)
            abort()
        }
        
        gasFillFetchedResultsController.delegate = self
        tableView.reloadData()
        
        //display the currentCar's nickname, if no currentCar is selected, display a note saying so
        if let car = currentCar {
            selectedCarLabel.text = car.nickname
        } else {
            selectedCarLabel.text = "Please Select A Vehicle"
        }
        
        //calculate the current mpg and display it
        mpgLabel.text = mpgCalc.calculateAverageMPG(gasFillFetchedResultsController.fetchedObjects as? [GasFill])
        
    }
    
    //the fetechedResultsController will grab all cars for the user from CoreData. They are do not need to be sorted in this context.
    lazy var carFetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Car")
        
        fetchRequest.sortDescriptors = []
        let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchResultsController
    }()
    
    /* since this predicate can change in this class without the class being reloaded, this needs to be a calculated variable, not a lazy varialble since lazy vars are treated like a let once intilized. */
    var gasFillFetchedResultsController: NSFetchedResultsController {
        get {
            //if there is a current car, get the object for the predicate.
            if let carCurrent = currentCar as Car! {
                //if _gasFillFetchedResultsController if nil then recreate the FetchedResultsController. By setting _gasFillFetchedResultsController to nil anywhere in the app, it will force the FetchedResultsController to be recreated next time the variable is used.
                if(_gasFillFetchedResultsController == nil){
                    let fetchRequest = NSFetchRequest(entityName: "GasFill")
        
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                    fetchRequest.predicate = NSPredicate(format: "car == %@", carCurrent)
                    _gasFillFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
                }
            
            } else {
                //if there is no currentCar selected, recreate the FetchedResultsController without a predicate that will return anything so the table is blank.
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
        //the number of cells in the table view is determined by the number of objects in the fetchedResultsController
        let sectionInfo = self.gasFillFetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "GasFillCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! GasTrackerTableViewCell
        let fillup = gasFillFetchedResultsController.objectAtIndexPath(indexPath) as! GasFill
        //this function will configure the cell each time it is created
        configureCell(cell, fillup: fillup)
        return cell
        
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
            //this function lets us delete objects directly from the table.
            switch (editingStyle) {
            case .Delete:
                //Here we get the fillup object then delete it from parse
                let fillup = gasFillFetchedResultsController.objectAtIndexPath(indexPath) as! GasFill
                parse.sharedInstance().deleteFromParse(parse.Resources.GasFill, objectId: fillup.objectId!){JSONResults, error in
                    
                    if let error = error{
                        self.throwAlert(error.localizedDescription)
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
    
    /* if a row is selected, we will then go back to the AddGasFillView to edit the object, create the view, then add the gasFillToEdit. Finally push the view to the navigation controller */
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
    
    //add all the rows to the table view and calculate the MPG for the newly added or deleted objects.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
        mpgLabel.text = mpgCalc.calculateAverageMPG(gasFillFetchedResultsController.fetchedObjects as? [GasFill])
    }
    
    /* this will push the AddGasViewController so a new gas fill can be added. */
    func addGasStopTouchUp(){
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("AddFillUpViewController") as UIViewController
        self.navigationController!.pushViewController(controller, animated: true)
    }
    
    
    /* to logout requires two steps. First we must delete the user sessionToken from parse, second we must clear all the coreData from memory, finally, we want to remove the userInfoDictionary. Three steps. It took threem not two. */
    func logoutTouchUp(){
        parse.sharedInstance().logoutUser(userInfoDictionary["sessionToken"] as! String){JSONResults, error in
            
            if let error = error {
                self.throwAlert(error.localizedDescription)
            } else {
                
                for car in self.carFetchedResultsController.fetchedObjects! {
                    self.sharedContext.deleteObject(car as! NSManagedObject)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                do {
                    try _ = NSFileManager.defaultManager().removeItemAtPath(self.filePath)
                } catch let error as NSError {
                    self.throwAlert(error.localizedDescription)
                    abort()
                }

            }
            
        }
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    /* all configuration of the cells can be done here. */
    func configureCell(cell: GasTrackerTableViewCell, fillup: GasFill) {
        //get rid of the time style, to shorten the display.
        formatter.timeStyle = .NoStyle
        
        //add the gallons for the fill and the date
        cell.gallonsLabel!.text = String(fillup.gallonsDecimal)
        cell.dateLabel!.text = formatter.stringFromDate(fillup.date)
        
        //add the formater longstyle for use elsewhere.
        formatter.timeStyle = .LongStyle
    }
    
    /* this function will throw an alert for any string passed to it.*/
    func throwAlert(alertMessage: String){
        let alert = UIAlertController(title: "Alert", message: alertMessage, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    /* this function is called once when it is needed. It will only grab gasFills for a car as it's being displayed. for each gasFill a new object is created and saved to CoreData. */
    func getGasFills(){
        
        if let carCurrent = currentCar {
            //this will grab the gasFill objects from parse for the car that is selected.
            let methodArguments = [
                "where" : "{\"carObjectId\":\"" + carCurrent.objectId! as String! + "\"}"
            ]
            
            //print(methodArguments)
            parse.sharedInstance().getFromParse(parse.Resources.GasFill, methodArguments: methodArguments) {JSONResults, error in
            
                if let error = error{
                    self.throwAlert(error.localizedDescription)
                } else {
                    if let gasFillInfo = JSONResults["results"] as? [[String:AnyObject]]{
                        for fillup in gasFillInfo {

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
                                newFillupDictionary["date"] = self.formatter.dateFromString(dateString)
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
                    self.currentCar!.checkParseForGasFills = false
                    CoreDataStackManager.sharedInstance().saveContext()
                    }
                }
            }
        }
    }
    
}
