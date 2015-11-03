//
//  DateViewController.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/27/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import UIKit

class DateViewController : UIViewController {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var date : NSDate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker.date = date
    }
    
    /* if you select the change the date button, it will take the date object and push it back to tbe previous view controller, allowing you to change the date. */
    @IBAction func changeTheDateTouchUp(sender: AnyObject) {
        let controller = self.navigationController!.viewControllers[1] as! AddFillUpViewController
        controller.rightNow = datePicker.date
        self.navigationController!.popViewControllerAnimated(true)
    }
}