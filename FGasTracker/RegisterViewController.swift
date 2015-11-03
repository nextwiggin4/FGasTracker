//
//  RegisterViewController.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/7/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {
    
    /* this class is used for new users to register their username and password. If successful, they will be forwarded directly into the app. */
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var debugInfo: UILabel!
    @IBOutlet weak var registrationIndicator: UIActivityIndicatorView!
    @IBOutlet weak var registerButton: UIButton!
    
    //get the location of the user info dictionary. all pertinent userinfo will be stored here for later use.
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        return url.URLByAppendingPathComponent("userInfoArchive").path!
    }
    
    var objectId : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //clear the debugInfo text field
        self.debugInfo.text = ""
        
        
        //this code is used to allow for dismissing the keyboard when a user touches outside of the textfield
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: "didTapView")
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //this touchup allows the user to leave the register page and return to the login page.
    @IBAction func backToLogin(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //this function allows the user to attemp to register. There is no need to verify the user credentials, if they are not useable, Parse will return an error.
    @IBAction func registerButton(sender: AnyObject) {
        self.registerButton.hidden = true
        self.registrationIndicator.startAnimating()
        
        parse.sharedInstance().registerNewUser(username.text!, password: password.text!){ JSONResults, error in
            if let error = error{
                self.registerButton.hidden = false
                self.registrationIndicator.stopAnimating()
                print(error)
            } else {
                if let error = JSONResults["error"]! {
                    print(JSONResults)
                    print(error)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.registerButton.hidden = false
                        self.registrationIndicator.stopAnimating()
                        self.debugInfo.text = error as? String
                    })
                } else {
                    //if successful, the userinformation dictionary is created containing everything needed within the app to function
                    let userInfoDictionary = [
                        "username" : self.username.text! ,
                        "objectId" : JSONResults["objectId"] as! String,
                        "sessionToken" : JSONResults["sessionToken"] as! String,
                        "currentCar" : "Add a new car",
                        "mileageSwitch" : 0,
                        "priceSwitch" : 0,
                        "completeFillButton" : true
                    ]
                    
                    self.objectId = userInfoDictionary["objectId"] as! String
                    NSKeyedArchiver.archiveRootObject(userInfoDictionary, toFile: self.filePath)
                    self.completeRegistration()
                }
            }
            
        }
    }
    
    //this function brings up the main page of the app and resets all the animations and debug information to their noraml state.
    func completeRegistration() {
        dispatch_async(dispatch_get_main_queue(), {
            self.registerButton.hidden = false
            self.registrationIndicator.stopAnimating()
            self.debugInfo.text = "login successful"
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("GasTrackerNavigationController") as! UINavigationController
            self.presentViewController(controller, animated: true, completion: nil)
        })
    }
    
    func didTapView(){
        self.view.endEditing(true)
    }
}
