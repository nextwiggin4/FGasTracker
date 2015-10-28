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

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var debugInfo: UILabel!
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! 
        return url.URLByAppendingPathComponent("userInfoArchive").path!
    }
    
    var objectId : String!
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Car")
        
        fetchRequest.sortDescriptors = []
        let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchResultsController
        }()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        debugInfo.text = ""
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        debugInfo.text = ""
        
        if let _ = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            completeLogin()
        }
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: "didTapView")
        self.view.addGestureRecognizer(tapRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginPressed(sender: AnyObject) {
        
        let methodArguments = [
            "username": username.text!,
            "password" : password.text!
        ]
        
        parse.sharedInstance().loginUser(methodArguments){ JSONResults, error in
            
            if let error = error{
                print(error)
            } else {
                
                if let error = JSONResults["error"]! {
                    print(JSONResults)
                    print(error)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.debugInfo.text = error as? String
                    })
                } else {
                    
                    let userInfoDictionary = [
                        "username" : JSONResults["username"] as! String,
                        "objectId" : JSONResults["objectId"] as! String,
                        "sessionToken" : JSONResults["sessionToken"] as! String,
                        "currentCar" : "Add a new car",
                        "mileageSwitch" : 0,
                        "priceSwitch" : 0,
                        "completeFillButton" : true
                    ]
                    
                    self.objectId = userInfoDictionary["objectId"] as! String
                    NSKeyedArchiver.archiveRootObject(userInfoDictionary, toFile: self.filePath)
                    print(JSONResults)
                    //self.completeLogin()
                    self.getParesData()
                }
            }
            
        }
    }
    
    func completeLogin() {
        dispatch_async(dispatch_get_main_queue(), {
            self.debugInfo.text = "login successful"
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("GasTrackerNavigationController") as! UINavigationController
            self.presentViewController(controller, animated: true, completion: nil)
        })
    }
    
    func getParesData(){
        
        let methodArguments = [
            "where" : "{\"userObjectId\":\"" + self.objectId + "\"}"
            //"objectID" : self.objectId
        ]
        parse.sharedInstance().getFromParse(parse.Resources.Cars, methodArguments: methodArguments) {JSONResults, error in
            
            if let error = error{
                print(error)
            } else {
                if let carsInfo = JSONResults["results"] as? [[String:AnyObject]]{
                    for car in carsInfo {
                        var newCarDictionary = Dictionary<String, AnyObject>()
                        
                        if let make = car["make"]{
                            newCarDictionary["make"] = make
                        }
                        if let model = car["model"]{
                            newCarDictionary["model"] = model
                        }
                        if let nickname = car["nickname"]{
                            newCarDictionary["nickname"] = nickname
                        }
                        
                        if let year = car["year"]{
                            newCarDictionary["year"] = year
                        }
                        
                        newCarDictionary["objectId"] = car["objectId"]
                        newCarDictionary["userObjectId"] = car["userObjectId"]
                        
                        _ = Car(dictionary: newCarDictionary, context: self.sharedContext)
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                }
            }
            self.completeLogin()
        }
    }
    
    func didTapView(){
        self.view.endEditing(true)
    }
}

