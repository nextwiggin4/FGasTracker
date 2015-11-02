//
//  RegisterViewController.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/7/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var debugInfo: UILabel!
    @IBOutlet weak var registrationIndicator: UIActivityIndicatorView!
    @IBOutlet weak var registerButton: UIButton!
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        return url.URLByAppendingPathComponent("userInfoArchive").path!
    }
    
    var objectId : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.debugInfo.text = ""
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: "didTapView")
        self.view.addGestureRecognizer(tapRecognizer)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backToLogin(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
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
