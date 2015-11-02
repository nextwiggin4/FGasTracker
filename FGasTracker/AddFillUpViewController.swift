//
//  AddFillUpViewController.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/14/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import UIKit
import CoreData

class AddFillUpViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mileageSwitch: UISegmentedControl!
    @IBOutlet weak var priceSwitch: UISegmentedControl!
    @IBOutlet weak var mileageLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var fillSwitch: UISwitch!
    @IBOutlet weak var completeFillButton: UIButton!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var addFillupButton: UIButton!
    @IBOutlet weak var addFillIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var mileageTextField: UITextField!
    @IBOutlet weak var gallonsTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    
    var gasFillToEdit : GasFill?
    
    @IBOutlet weak var carPicker: UIPickerView!
    
    let carPickerDataPrimer = ["Add a new car"]
    
    var carPickerData = [String]()
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    var currentCarNickname : String = ""
    var currentCar: Car?
    
    var userInfoDictionary : [String:AnyObject]!
    
    var rightNow = NSDate()
    let formatter = NSDateFormatter()
    
    let gallonsTextFieldDelegate = IntegerTextFieldDelegate(sigFig: 3)
    var mileageTextFieldDelegate = IntegerTextFieldDelegate(sigFig: 0)
    var priceTextFieldDelegate = IntegerTextFieldDelegate(sigFig: 3)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let userInfo = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            userInfoDictionary = userInfo
        }
        
        mileageSwitch.selectedSegmentIndex = (userInfoDictionary["mileageSwitch"] as? Int)!
        priceSwitch.selectedSegmentIndex = (userInfoDictionary["priceSwitch"] as? Int)!
        fillSwitch.on = (userInfoDictionary["completeFillButton"] as? Bool)!
        
        //this makes this view controller conform to the various protocols
        fetchedResultsController.delegate = self
        carPicker.dataSource = self
        carPicker.delegate = self
        
        self.gallonsTextField.delegate = self.gallonsTextFieldDelegate
        self.mileageTextField.delegate = self.mileageTextFieldDelegate
        self.priceTextField.delegate = self.priceTextFieldDelegate
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: "didTapView")
        self.view.addGestureRecognizer(tapRecognizer)
        
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateButton.setTitle(formatter.stringFromDate(rightNow), forState: .Normal)
        
        formatMileageTextField()
        formatPriceTextField()
        
        if let gasFill = gasFillToEdit {
            allowForEdit(gasFill)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.subscribeToKeyboardNotifications()
        
        if let userInfo = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            userInfoDictionary = userInfo
        }
        
        carPickerData = [String]()
        
        carPickerData.append(carPickerDataPrimer[0])
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print(error.localizedDescription)
            abort()
        }
        //the iterator for keeping tack of location in the loop
        var i = 0
        //set to 0, since "add new car" isn't stored in the fetchedResultsController.
        var trace = 0
        if let userInfo = userInfoDictionary{
            currentCarNickname = userInfo["currentCar"] as! String
        }

        
        //this for loop adds the nicknames for each car to the UIPicker array. Additionally, it stores the loaction of the "current car" in trace.
        for car in fetchedResultsController.fetchedObjects! {
            carPickerData.append(car.nickname!!)
            ++i
            if (car.nickname!! == currentCarNickname) {
                trace = i
                currentCar = car as? Car
            }
        }
        
        carPicker.reloadAllComponents()
        
        //sets the UIPicker to the "current car". That way you don't have to change it later.
        carPicker.selectRow(trace, inComponent: 0, animated: false)
        
        dateButton.setTitle(formatter.stringFromDate(rightNow), forState: .Normal)
        
        setAddEditButton()
        formatMileageTextField()
        formatPriceTextField()
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
    
    
    func addCarTouchUp() {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("AddCarViewController") as! AddCarViewController
        self.navigationController!.pushViewController(controller, animated: true)
    }
    
    func editCarTouchUp(){
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("AddCarViewController") as! AddCarViewController
        
        var carToEdit : Car?
        for car in fetchedResultsController.fetchedObjects!{
            if (currentCarNickname == car.nickname){
                carToEdit = (car as! Car)
            }
        }
        controller.carToEdit = carToEdit
        self.navigationController!.pushViewController(controller, animated: true)
    }
    
    
    //MARK: - Delegates and data sources
    //MARK: Data Sources
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return carPickerData.count
    }
    
    //MARK: Delegates
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return carPickerData[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        currentCarNickname = carPickerData[row]
        if (row>0){
            currentCar = fetchedResultsController.fetchedObjects![row-1] as? Car
        } else {
            currentCar = nil
        }
        
        if let userInfo = userInfoDictionary {
            var userInfoMutable = userInfo
            userInfoMutable["currentCar"] = carPickerData[row]
            NSKeyedArchiver.archiveRootObject(userInfoMutable, toFile: filePath)
        }
        
        setAddEditButton()
    }
    
    func setAddEditButton(){
        if(currentCar != nil){
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit Car", style: .Plain, target: self, action: "editCarTouchUp")
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add Car", style: .Plain, target: self, action: "addCarTouchUp")
        }
    }
    
    @IBAction func addFillupTouchUp(sender: AnyObject) {
        if (currentCarNickname != "Add a new car") {
            switchIndicatorOn(true)
            if (gasFillToEdit == nil) {
                var newFillupDictionary = createDictionary()
                
                parse.sharedInstance().postToParse(parse.Resources.GasFill, methodArguments: newFillupDictionary){JSONResults, error in
                    
                    if let error = error{
                        print(error.localizedDescription)
                    } else {
                        print(JSONResults)
                        
                        newFillupDictionary["objectId"] = JSONResults["objectId"]
                        newFillupDictionary["date"] = self.rightNow
                        newFillupDictionary["car"] = self.currentCar
                        
                        _ = GasFill(dictionary: newFillupDictionary, context: self.sharedContext)
                        
                        CoreDataStackManager.sharedInstance().saveContext()
                        dispatch_async(dispatch_get_main_queue(), {
                            self.switchIndicatorOn(false)
                            self.navigationController!.popViewControllerAnimated(true)
                        })
                    }
                    
                }
            } else {
                let newFillupDictionary = createDictionary()
                
                parse.sharedInstance().putToParse(parse.Resources.GasFill, objectId: (gasFillToEdit?.objectId)!, methodArguments: newFillupDictionary){ JSONResults, error in
                    
                    if let error = error{
                        print(error)
                    } else {
                        if let mileage = self.mileageTextField.text {
                            if let mileageNumber = self.decimalStringToInt(mileage) {
                                if self.mileageSwitch.selectedSegmentIndex == 0 {
                                    self.gasFillToEdit!.totalMilage = mileageNumber
                                    self.gasFillToEdit!.trip = nil
                                } else {
                                    self.gasFillToEdit!.totalMilage = nil
                                    self.gasFillToEdit!.trip = mileageNumber
                                }
                            }
                        }
                        
                        if let gallons = self.gallonsTextField.text {
                            if let gallonsNumber = self.decimalStringToInt(gallons) {
                                self.gasFillToEdit!.gallons = gallonsNumber
                            }
                        }
                        
                        if let price = self.priceTextField.text {
                            if let priceNumber = self.decimalStringToInt(price) {
                                if self.priceSwitch.selectedSegmentIndex == 0 {
                                    self.gasFillToEdit!.pricePerGallon = priceNumber
                                    self.gasFillToEdit!.totalPrice = nil
                                } else {
                                    self.gasFillToEdit!.pricePerGallon = nil
                                    self.gasFillToEdit!.totalPrice = priceNumber
                                }
                            }
                        }
                        
                        self.gasFillToEdit!.completeFill = (self.fillSwitch?.on)!
                        
                        self.gasFillToEdit!.date = self.rightNow
                        self.gasFillToEdit!.car = self.currentCar!
                        
                        self.gasFillToEdit!.carObjectId = newFillupDictionary["carObjectId"] as? String
                        
                        
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
    
    func createDictionary() -> Dictionary<String, AnyObject> {
        var newFillupDictionary = Dictionary<String, AnyObject>()
        let deleteString = ["__op":"Delete"]
        
        if let mileage = mileageTextField.text {
            if let mileageNumber = decimalStringToInt(mileage) {
                if mileageSwitch.selectedSegmentIndex == 0 {
                    newFillupDictionary["totalMillage"] = mileageNumber
                    newFillupDictionary["currentTrip"] = deleteString
                } else {
                    newFillupDictionary["totalMillage"] = deleteString
                    newFillupDictionary["currentTrip"] = mileageNumber
                }
            }
        }
        
        if let gallons = gallonsTextField.text {
            if let gallonsNumber = decimalStringToInt(gallons) {
                newFillupDictionary["gallons"] = gallonsNumber
            }
        }
        
        if let price = priceTextField.text {
            if let priceNumber = decimalStringToInt(price) {
                if priceSwitch.selectedSegmentIndex == 0 {
                    newFillupDictionary["pricePerGallon"] = priceNumber
                    newFillupDictionary["totalCost"] = deleteString
                } else {
                    newFillupDictionary["pricePerGallon"] = deleteString
                    newFillupDictionary["totalCost"] = priceNumber
                }
            }
        }
        
        formatter.timeStyle = .LongStyle
        
        newFillupDictionary["date"] = formatter.stringFromDate(rightNow)
        newFillupDictionary["completeFill"] = fillSwitch?.on
        
        newFillupDictionary["carObjectId"] = currentCar!.objectId
        newFillupDictionary["userObjectId"] = userInfoDictionary["objectId"]
        
        return newFillupDictionary
    }
    
    func decimalStringToInt(decimalString: String) -> Int? {
        let digits = NSCharacterSet.decimalDigitCharacterSet()
        var digitText = ""
        for c in decimalString.unicodeScalars{
            if digits.longCharacterIsMember(c.value){
                digitText.append(c)
            }
        }
        
        return Int(digitText)
    }
    
    
    func formatMileageTextField(){
        if mileageSwitch.selectedSegmentIndex == 0 {
            mileageTextField.placeholder = "0"
            mileageTextFieldDelegate.significantFigures = 0
            mileageLabel.text = "enter your car's total mileage (odometer)"
        } else {
            mileageTextField.placeholder = "0.0"
            mileageTextFieldDelegate.significantFigures = 1
            mileageLabel.text = "enter your mileage since last fill (trip)"
        }
    }
    
    func formatPriceTextField(){
        if priceSwitch.selectedSegmentIndex == 0 {
            priceTextField.placeholder = "0.000"
            priceTextFieldDelegate.significantFigures = 3
            priceLabel.text = "enter the price you paid per gallon"
        } else {
            priceTextField.placeholder = "0.00"
            priceTextFieldDelegate.significantFigures = 2
            priceLabel.text = "enter the total price paid for the fill up"
        }
    }
    
    func didTapView(){
        self.view.endEditing(true)
    }
    
    func allowForEdit(gasFill: GasFill){
        
        addFillupButton.setTitle("Edit Fill-up", forState: .Normal)
        
        //check for totalMilage
        if let totalMilage = gasFill.totalMilage{
            mileageSwitch.selectedSegmentIndex = 0
            formatMileageTextField()
            mileageTextField.text = mileageTextFieldDelegate.stringFromInt(Int(totalMilage))

        }
        
        //check for trip
        if let trip = gasFill.trip{
            mileageSwitch.selectedSegmentIndex = 1
            formatMileageTextField()
            mileageTextField.text = mileageTextFieldDelegate.stringFromInt(Int(trip))
        }
        
        //check for gallons
        if let gallons = gasFill.gallons{
            gallonsTextField.text = gallonsTextFieldDelegate.stringFromInt(Int(gallons))
        }
        
        //check for price per gallons
        if let pricePerGal = gasFill.pricePerGallon{
            priceSwitch.selectedSegmentIndex = 0
            formatPriceTextField()
            priceTextField.text = priceTextFieldDelegate.stringFromInt(Int(pricePerGal))
        }
        
        //check for total price
        if let totalPrice = gasFill.totalPrice{
            priceSwitch.selectedSegmentIndex = 1
            formatPriceTextField()
            priceTextField.text = priceTextFieldDelegate.stringFromInt(Int(totalPrice))
        }
        
        //set date
        self.rightNow = gasFill.date
        dateButton.setTitle(formatter.stringFromDate(gasFill.date), forState: .Normal)
        
        //set fill complete
        fillSwitch.on = gasFill.completeFill
        
        //setCurrentCar
        
        
    }
    
    func switchIndicatorOn(state: Bool){
        if state {
            addFillupButton.hidden = true
            addFillIndicator.startAnimating()
            self.navigationItem.rightBarButtonItem?.enabled = false
        } else {
            addFillupButton.hidden = false
            addFillIndicator.stopAnimating()
            self.navigationItem.rightBarButtonItem?.enabled = false
        }
        
    }
    
    @IBAction func mileageSwitched(sender: AnyObject) {
        userInfoDictionary["mileageSwitch"] = mileageSwitch.selectedSegmentIndex
        NSKeyedArchiver.archiveRootObject(userInfoDictionary!, toFile: self.filePath)
        
        formatMileageTextField()
        if let numberString = mileageTextField.text{
            if numberString != "" {
                let tempNumber = decimalStringToInt(numberString)
                mileageTextField.text = mileageTextFieldDelegate.stringFromInt(tempNumber)
            }
        }
    }
    
    @IBAction func priceSwitched(sender: AnyObject) {
        userInfoDictionary["priceSwitch"] = priceSwitch.selectedSegmentIndex
        
        NSKeyedArchiver.archiveRootObject(userInfoDictionary!, toFile: self.filePath)
        formatPriceTextField()
        if let numberString = priceTextField.text {
            if numberString != "" {
                let tempNumber = decimalStringToInt(numberString)
                priceTextField.text = priceTextFieldDelegate.stringFromInt(tempNumber)
            }
        }
    }
    @IBAction func completeFillSwitched(sender: AnyObject) {
        userInfoDictionary["completeFillButton"] = fillSwitch.on
        NSKeyedArchiver.archiveRootObject(userInfoDictionary!, toFile: self.filePath)
    }
    @IBAction func completeFillTouchup(sender: AnyObject) {
        let alert = UIAlertController(title: "What is this?", message: "Knowing when you've completely filled the tank helps improve accuracy of your MPG. Turn the switch off whenever you don't get a full tank!", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Okie Dokie", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    @IBAction func changeDateTouchUp(sender: AnyObject) {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("DateViewController") as! DateViewController
        controller.date = rightNow
        self.navigationController!.pushViewController(controller, animated: true)
    }
}
