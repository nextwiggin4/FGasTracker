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
    
    /* this class deals with the Add Car view. In it, the user will be able to add new cars, edit cars and delete cars. */
    
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
        
        
        //fetch all cars in stored in coredata.
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print(error.localizedDescription)
            abort()
        }
        
        fetchedResultsController.delegate = self
        
        //if the carToEdit object is not nil (there is a car to edit) put all the information in the propper feild and a button to allow for deleting the car.
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
        
        //check for the userInfoDictionary and grab the objectId (this is the users objectId from Parse) and store it for later use.
        if let userInfo = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            userObjectId = userInfo["objectId"] as? String
        }
        
        //this code is used to allow for dismissing the keyboard when a user touches outside of the textfield
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: "didTapView")
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //subscribe to the keyboard notifcations. This is used to allow the screen to be moved outof the way for textfields that can't be seen.
        self.subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //unsubscribe from the KeyboardNotifications. Doing this here will unsubscribe you when the view controller is dismissed.
        self.unsubscribeFromKeyboardNotifications()
    }
    
    //the fetechedResultsController will grab all cars for the user from CoreData. They are do not need to be sorted in this context.
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Car")
        
        fetchRequest.sortDescriptors = []
        let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchResultsController
    }()
    
    //this creates the file path for the userInfoDictionary.
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        return url.URLByAppendingPathComponent("userInfoArchive").path!
    }
    
    /* the addCar touchup function is called if there is a car to edit or not. First verify there is a nick name (the only necessary filed) then add a new car or edit an old one if appropriate */
    @IBAction func addCar(sender: AnyObject) {
        
        if (self.nicknameTextField.text!.isEmpty) {
            
            instructionLabel.text = "You must include a nickname"
            
        } else {
            switchIndicatorOn(true)
            if (carToEdit == nil) {
                //this function creates a mutable dictionary populated with all the text fields.
                var newCarDictionary = createDicitonary()
                //call the parse function to add a car to Parse
                parse.sharedInstance().postToParse(parse.Resources.Cars, methodArguments: newCarDictionary){JSONResults, error in
                    
                    if let error = error{
                        dispatch_async(dispatch_get_main_queue(), {
                            self.switchIndicatorOn(false)
                            self.throwAlert(error.localizedDescription)
                        })
                    } else {
                        print(JSONResults)
                        // if the car object was succesfully added to parse, then grab the car's objectId and add it to the dictionary.
                        newCarDictionary["objectId"] = JSONResults["objectId"]
                        
                        //create a new car object
                        _ = Car(dictionary: newCarDictionary, context: self.sharedContext)
                        
                        //persist the car to coreData. Awesome.
                        CoreDataStackManager.sharedInstance().saveContext()
                        //dismiss the view controller and do the stuff that resets the buttons and indicators.
                        dispatch_async(dispatch_get_main_queue(), {
                            self.switchIndicatorOn(false)
                            self.navigationController!.popViewControllerAnimated(true)
                        })
                    }
                }
            } else {
                //this function creates a mutable dictionary populated with all the text fields.
                var newCarDictionary = createDicitonary()
                
                //this function will make a put car to parse, updating a current car object
                parse.sharedInstance().putToParse(parse.Resources.Cars, objectId: (carToEdit?.objectId)!, methodArguments: newCarDictionary){
                    JSONResults, error in
                    
                    if let error = error{
                        dispatch_async(dispatch_get_main_queue(), {
                            self.switchIndicatorOn(false)
                            self.throwAlert(error.localizedDescription)
                        })
                    } else {
                        
                        //if successfull, update the car NSManaged object with the text fields.
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
                        
                        //save the fields to coreData
                        CoreDataStackManager.sharedInstance().saveContext()
                        //dismiss the view controller and once again do the stuff that resets the buttons and indicators.
                        dispatch_async(dispatch_get_main_queue(), {
                            self.switchIndicatorOn(false)
                            self.navigationController!.popViewControllerAnimated(true)
                        })
                    }
                }
            }
        }
    }
    
    /* if the delete button is tapped, it will call this function. The carToEdit will be deleted from Parse and from CoreData. Suck on that car data, you never stood a chance! */
    func deleteCarTouchUp(){
        self.switchIndicatorOn(true)
        //this function calls a delete from Parse.
        parse.sharedInstance().deleteFromParse(parse.Resources.Cars, objectId: (carToEdit?.objectId)!){JSONResults, error in
            
            if let error = error{
                dispatch_async(dispatch_get_main_queue(), {
                    self.switchIndicatorOn(false)
                    self.throwAlert(error.localizedDescription)
                })
            } else {
                print(JSONResults)
                
                //if the delete from Parse is successful, delete the object from CoreData too
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
    
    /* this function creates a dictionary populated by the text fields on the view. It checks for any data, turns it the correct type (if possible) and returns the new dictionary. */
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
    
    /* this function is a helper that switches the activity indicator on and off, hides and disable buttons that shouldn't be opperating while the app is connecting to the internet. True indicates that there is background activity you need to wait for. */
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
    
    /* this function will throw an alert for any string passed to it.*/
    func throwAlert(alertMessage: String){
        let alert = UIAlertController(title: "Alert", message: alertMessage, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}
