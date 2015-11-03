//
//  LoginViewController.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/7/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import UIKit
import CoreData

class LoginViewController: UIViewController {
    
    /* the login view controller allows a user to input their username and password. If they are correct it will then download in car objects from the parse server. If the user doesn't have login credentials they can create one by goiing to the registration view controller */
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var debugInfo: UILabel!
    @IBOutlet weak var loginIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loginButton: UIButton!
    
    //this is the path that will be used for the user information dictionary. This will contain setting information, username and objectId info
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! 
        return url.URLByAppendingPathComponent("userInfoArchive").path!
    }
    
    var objectId : String!
    
    //we must set up the CoreDataStackManager since if login is successful the downloaded car objects will be added to coredata
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Car")
        
        fetchRequest.sortDescriptors = []
        let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchResultsController
        }()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //set the debug text to an empty string.
        debugInfo.text = ""
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set the debug text to an empty string.
        debugInfo.text = ""
        
        //if the userInfo data is present, skip the login in and go straight to the login.
        if let _ = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            completeLogin()
        }
        
        //this will dismiss the keyboard if you touch anywhere outside the text fields.
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: "didTapView")
        self.view.addGestureRecognizer(tapRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginPressed(sender: AnyObject) {
        
        //create a dictionary to send to Parse. There is no need to valid these values, if it's wrong (blank, for example) parse will return an error object with the needed correction.
        let methodArguments = [
            "username": username.text!,
            "password" : password.text!
        ]
        
        //hide the login button so it can't be pressed again durring the loading and start the indicator animating.
        loginButton.hidden = true
        loginIndicator.startAnimating()
        
        parse.sharedInstance().loginUser(methodArguments){ JSONResults, error in
            
            if let error = error{
                print(error)
                self.loginIndicator.stopAnimating()
                self.loginButton.hidden = false
            } else {
                
                //if parse returns an error object, set the debubg text with the information and reactivate the login button.
                if let error = JSONResults["error"]! {
                    print(JSONResults)
                    print(error)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.debugInfo.text = error as? String
                        self.loginIndicator.stopAnimating()
                        self.loginButton.hidden = false
                    })
                } else {
                    
                    //if the login was successful, create a userInfo dictionary to be stored for the app.
                    let userInfoDictionary = [
                        "username" : JSONResults["username"] as! String,
                        "objectId" : JSONResults["objectId"] as! String,
                        "sessionToken" : JSONResults["sessionToken"] as! String,
                        "currentCar" : "Add a new car",
                        "mileageSwitch" : 0,
                        "priceSwitch" : 0,
                        "completeFillButton" : true
                    ]
                    
                    //store the objectId to a local variable, so it can be used to get any car data necessary.
                    self.objectId = userInfoDictionary["objectId"] as! String
                    
                    //save the userInfoDictionary.
                    NSKeyedArchiver.archiveRootObject(userInfoDictionary, toFile: self.filePath)
                    print(JSONResults)
                    //grab car data from parse, if it's available.
                    self.getParesData()
                }
            }
            
        }
    }
    
    func completeLogin() {
        //if login is succesful, reset the login button, set the debugInfo label to a successul login message and segue to the main navigation controller
        dispatch_async(dispatch_get_main_queue(), {
            self.loginIndicator.stopAnimating()
            self.loginButton.hidden = false
            self.debugInfo.text = "login successful"
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("GasTrackerNavigationController") as! UINavigationController
            self.presentViewController(controller, animated: true, completion: nil)
        })
    }
    
    func getParesData(){
        
        //create a dictionary for getting the cars that belong to the user who loged in. The "where" field is used by parse to find the specific cars assoicated with the users objectId
        let methodArguments = [
            "where" : "{\"userObjectId\":\"" + self.objectId + "\"}"
        ]
        parse.sharedInstance().getFromParse(parse.Resources.Cars, methodArguments: methodArguments) {JSONResults, error in
            
            if let error = error{
                print(error)
                self.loginIndicator.stopAnimating()
                self.loginButton.hidden = false
            } else {
                if let carsInfo = JSONResults["results"] as? [[String:AnyObject]]{
                    for car in carsInfo {
                        /* the car dictionary can be used directly by the NSManagedObject to create new car objects */
                        
                        _ = Car(dictionary: car, context: self.sharedContext)
                        
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                }
            }
            //once complete, complete login
            self.completeLogin()
        }
    }
    
    //this will dismiss the keyboard if you touch outside of the text box field
    func didTapView(){
        self.view.endEditing(true)
    }
}

