//
//  AddCarViewController.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/14/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import UIKit
import CoreData

class AddCarViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var makeTextField: UITextField!
    @IBOutlet weak var modelTextField: UITextField!
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var buttonText: UIButton!
    @IBOutlet weak var addCarIndicator: UIActivityIndicatorView!
    
    var carToEdit: Car?
    var userObjectId : String?
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print(error.localizedDescription)
            abort()
        }
        
        fetchedResultsController.delegate = self
        
        if (carToEdit != nil) {
            instructionLabel.text = "Edit this car"
            buttonText.setTitle("Save Edit", forState: .Normal)
            makeTextField.text = carToEdit!.make
            modelTextField.text = carToEdit!.model
            yearTextField.text = carToEdit!.year?.stringValue
            nicknameTextField.text = carToEdit!.nickname
            //print(carToEdit!.objectId)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Delete Car", style: .Plain, target: self, action: "deleteCarTouchUp")
        }
        
        if let userInfo = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            userObjectId = userInfo["objectId"] as? String
            print(userObjectId!)
        }
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: "didTapView")
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //unsubscribe from the KeyboardNotifications. Doing this here will unsubscribe you when the view controller is dismissed. It will also do it when the imagePickerController is dismissed. To deal with that you have to enable again when after everytime the imagePicker is dismissed.
        self.unsubscribeFromKeyboardNotifications()
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Car")
        
        fetchRequest.sortDescriptors = []
        let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchResultsController
    }()
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        return url.URLByAppendingPathComponent("userInfoArchive").path!
    }
    

    @IBAction func addCar(sender: AnyObject) {
        
        if (self.nicknameTextField.text!.isEmpty) {
            
            instructionLabel.text = "You must include a nickname"
            
        } else {
            switchIndicatorOn(true)
            if (carToEdit == nil) {
                
                var newCarDictionary = createDicitonary()
            
                parse.sharedInstance().postToParse(parse.Resources.Cars, methodArguments: newCarDictionary){JSONResults, error in
                    
                    if let error = error{
                        print(error)
                    } else {
                        print(JSONResults)
                        
                        newCarDictionary["objectId"] = JSONResults["objectId"]
                        
                        _ = Car(dictionary: newCarDictionary, context: self.sharedContext)
                
                        CoreDataStackManager.sharedInstance().saveContext()
                        dispatch_async(dispatch_get_main_queue(), {
                            self.switchIndicatorOn(false)
                            self.navigationController!.popViewControllerAnimated(true)
                        })
                    }
                }
            } else {
                var newCarDictionary = createDicitonary()
                
                parse.sharedInstance().putToParse(parse.Resources.Cars, objectId: (carToEdit?.objectId)!, methodArguments: newCarDictionary){
                    JSONResults, error in
                    
                    if let error = error{
                        print(error)
                    } else {
                        print(JSONResults)
                        
                        newCarDictionary["objectId"] = JSONResults["objectId"]
                        
                        if let make = self.makeTextField.text {
                            self.carToEdit!.make = make
                        }
                        if let model = self.modelTextField.text {
                            self.carToEdit!.model = model
                        }
                        if let year = self.yearTextField.text {
                            if let yearNumber = Int(year) {
                                self.carToEdit!.year = yearNumber
                            }
                        }
                        
                        CoreDataStackManager.sharedInstance().saveContext()
                        dispatch_async(dispatch_get_main_queue(), {
                            self.switchIndicatorOn(false)
                            self.navigationController!.popViewControllerAnimated(true)
                        })
                    }
                }
            }
        }
    }
    
    func deleteCarTouchUp(){
        self.switchIndicatorOn(true)
        parse.sharedInstance().deleteFromParse(parse.Resources.Cars, objectId: (carToEdit?.objectId)!){JSONResults, error in
            
            if let error = error{
                print(error)
            } else {
                print(JSONResults)
                
                self.sharedContext.deleteObject(self.carToEdit!)
                
                CoreDataStackManager.sharedInstance().saveContext()
                dispatch_async(dispatch_get_main_queue(), {
                    self.switchIndicatorOn(false)
                    self.navigationController!.popViewControllerAnimated(true)
                })
            }
        }
    }
    
    func didTapView(){
        self.view.endEditing(true)
    }
    
    func createDicitonary() -> Dictionary<String, AnyObject>{
        var newCarDictionary = Dictionary<String, AnyObject>()
        
        if let make = makeTextField.text {
            newCarDictionary["make"] = make
        }
        if let model = modelTextField.text {
            newCarDictionary["model"] = model
        }
        if let year = yearTextField.text {
            if let yearNumber = Int(year) {
                newCarDictionary["year"] = yearNumber
            }
        }
        
        if let userObjectId = self.userObjectId {
            newCarDictionary["userObjectId"] = userObjectId
        }
        
        newCarDictionary["nickname"] = nicknameTextField.text!
    
        return newCarDictionary
    }
    
    func switchIndicatorOn(state: Bool){
        if state {
            buttonText.hidden = true
            addCarIndicator.startAnimating()
            self.navigationItem.rightBarButtonItem?.enabled = false
        } else {
            buttonText.hidden = false
            addCarIndicator.stopAnimating()
            self.navigationItem.rightBarButtonItem?.enabled = false
        }
        
    }
    
}
