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
    
    //this is nill if we are adding a new fillup. This will have a gasFill object if it is going to be edited
    var gasFillToEdit : GasFill?

    @IBOutlet weak var carPicker: UIPickerView!
    
    let carPickerDataPrimer = ["Add a new car"]
    
    //this array will be used by the UIPickerView
    var carPickerData = [String]()
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    var currentCarNickname : String = ""
    var currentCar: Car?
    
    var userInfoDictionary : [String:AnyObject]!
    
    var rightNow = NSDate()
    let formatter = NSDateFormatter()
    
    //each fo the text fields will have their own textFieldDelegate, they are initiated here with the propper number of significant figures.
    let gallonsTextFieldDelegate = IntegerTextFieldDelegate(sigFig: 3)
    var mileageTextFieldDelegate = IntegerTextFieldDelegate(sigFig: 0)
    var priceTextFieldDelegate = IntegerTextFieldDelegate(sigFig: 3)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //this gets the userInfoDictionary.
        if let userInfo = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            userInfoDictionary = userInfo
        }
        
        //the state of the switches are persisted in the dictionary. Use the dictionary and set them to the appropriate sate.
        mileageSwitch.selectedSegmentIndex = (userInfoDictionary["mileageSwitch"] as? Int)!
        priceSwitch.selectedSegmentIndex = (userInfoDictionary["priceSwitch"] as? Int)!
        fillSwitch.on = (userInfoDictionary["completeFillButton"] as? Bool)!
        
        //this makes this view controller conform to the various protocols
        fetchedResultsController.delegate = self
        carPicker.dataSource = self
        carPicker.delegate = self
        
        //set each textfield to their appropriate delegates.
        self.gallonsTextField.delegate = self.gallonsTextFieldDelegate
        self.mileageTextField.delegate = self.mileageTextFieldDelegate
        self.priceTextField.delegate = self.priceTextFieldDelegate
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: "didTapView")
        self.view.addGestureRecognizer(tapRecognizer)
        
        //this formates the date to MediumStyle, that will display the date, but not the time. The time is editable, but it's too much to display it all the time.
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        //change the date button's title to the current date
        dateButton.setTitle(formatter.stringFromDate(rightNow), forState: .Normal)
        
        //these functions will are called to make sure textFields are formated correctly for the current state of the switches, since the significant figures change with the switches.
        formatMileageTextField()
        formatPriceTextField()
        
        //if the gasFill for edit exists, call the helper function that sets all the textfields to the proper state
        if let gasFill = gasFillToEdit {
            allowForEdit(gasFill)
        }
    }
    
    /* since this view can be shown after the AddCar view is popped, it won't always get a chance to call viewDidLoad. viewWillAppear needs to do the heavy lifting on getting new content and displaying it. */
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.subscribeToKeyboardNotifications()
        
        //get the userInfoDictionary again, incase it was changed.
        if let userInfo = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            userInfoDictionary = userInfo
        }
        
        //reset carPickerData to an empty array of Strings.
        carPickerData = [String]()
        
        //This makes the first field of the UIPicker "Add a new car" everytime
        carPickerData.append(carPickerDataPrimer[0])
        
        //perform a fetch to make sure you have all the current cars available to select.
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print(error.localizedDescription)
            abort()
        }
        //the iterator for keeping tack of location in the loop
        var i = 0
        //set to 0, since "add new car" isn't stored in the fetchedResultsController the first element is the first car
        var trace = 0
        //get the current selected car from userInfoDictionary.
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
        
        //this displays all adds all the nicknames to the carpicker
        carPicker.reloadAllComponents()
        
        //sets the UIPicker to the "current car" that saved in the userInfoDictionary
        carPicker.selectRow(trace, inComponent: 0, animated: false)
        
        dateButton.setTitle(formatter.stringFromDate(rightNow), forState: .Normal)
        
        //this function will change the Add button to an edit button whenever "add a new car" isn't selected
        setAddEditButton()
        formatMileageTextField()
        formatPriceTextField()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //unsubscribe from the KeyboardNotifications. Doing this here will unsubscribe you when the view controller is dismissed. It will also do it when the imagePickerController is dismissed. To deal with that you have to enable again when after everytime the imagePicker is dismissed.
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
    
    //this function will push a view of the AddCarViewController to the navigation controller.
    func addCarTouchUp() {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("AddCarViewController") as! AddCarViewController
        self.navigationController!.pushViewController(controller, animated: true)
    }
    
    //this function will push a view of the AddCarViewController to the navigation controller. First it grabs the Car object for the selected nickname and adds it to the new view to be edited.
    func editCarTouchUp(){
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("AddCarViewController") as! AddCarViewController
        controller.carToEdit = currentCar
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
    
    /* this function is part of the UIPicker delegate. Whenever a new item in the list is selected it is called. */
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        //first we will set the currentCar to car that's been selected. if it's set to "add car" it will be set to null
        currentCarNickname = carPickerData[row]
        if (row>0){
            currentCar = fetchedResultsController.fetchedObjects![row-1] as? Car
        } else {
            currentCar = nil
        }
        
        //save the nick name to the userInfoDictionary
        if let userInfo = userInfoDictionary {
            var userInfoMutable = userInfo
            userInfoMutable["currentCar"] = carPickerData[row]
            userInfoDictionary!["currentCar"] = carPickerData[row]
            NSKeyedArchiver.archiveRootObject(userInfoMutable, toFile: filePath)
        }
        
        //this function will change the add button to edit if currentCar isn't null
        setAddEditButton()
    }
    
    //this function will change the add button to edit if currentCar isn't null.
    func setAddEditButton(){
        if(currentCar != nil){
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit Car", style: .Plain, target: self, action: "editCarTouchUp")
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add Car", style: .Plain, target: self, action: "addCarTouchUp")
        }
    }
    
    /* this function is called for both the "add fill" and "edit fill". first you must verify a car has been selected to add the fill to.*/
    @IBAction func addFillupTouchUp(sender: AnyObject) {
        if (currentCarNickname != "Add a new car") {
            switchIndicatorOn(true)
            
            // if the gasFillToEdit is null, we must create a new gas fill object.
            if (gasFillToEdit == nil) {
                var newFillupDictionary = createDictionary()
                
                //this function posts a new object to parse.
                parse.sharedInstance().postToParse(parse.Resources.GasFill, methodArguments: newFillupDictionary){JSONResults, error in
                    
                    if let error = error{
                        dispatch_async(dispatch_get_main_queue(), {
                            self.switchIndicatorOn(false)
                            self.throwAlert(error.localizedDescription)
                        })
                    } else {
                        //if the post is successful, add the returned objectId, the date object and the current car object
                        
                        newFillupDictionary["objectId"] = JSONResults["objectId"]
                        newFillupDictionary["date"] = self.rightNow
                        newFillupDictionary["car"] = self.currentCar
                        
                        if let currentCar = self.currentCar {
                            if !currentCar.checkParseForGasFills{
                                //create a temporary gasFill object and persist it to coreData
                                _ = GasFill(dictionary: newFillupDictionary, context: self.sharedContext)
                                CoreDataStackManager.sharedInstance().saveContext()
                            }
                        }
                       
                        //switch the indicators and dismiss the view
                        dispatch_async(dispatch_get_main_queue(), {
                            self.switchIndicatorOn(false)
                            self.navigationController!.popViewControllerAnimated(true)
                        })
                    }
                    
                }
            } else {
                let newFillupDictionary = createDictionary()
                
                //if there is a gasFill object to edit, push the update to parse.
                parse.sharedInstance().putToParse(parse.Resources.GasFill, objectId: (gasFillToEdit?.objectId)!, methodArguments: newFillupDictionary){ JSONResults, error in
                    
                    if let error = error{
                        dispatch_async(dispatch_get_main_queue(), {
                            self.switchIndicatorOn(false)
                            self.throwAlert(error.localizedDescription)
                        })
                    } else {
                        //if the push is successufll, we need to change some of the strings into numbers for persisting it to coreData. If the fields are full, turn them in to Ints and change the gasFill object we will persist to coreData.
                        
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
        } else {
            throwAlert("You must select a car before adding a fill up. Sorry about that, but those are the rules. You just can't fill up nothing.")
        }
    }
    
    /* this function creates a dictionary populated by the text fields on the view. It checks for any data, turns it the correct type (if possible) and returns the new dictionary. */
    func createDictionary() -> Dictionary<String, AnyObject> {
        var newFillupDictionary = Dictionary<String, AnyObject>()
        //the delete string will be convereted to a JSON object that Parse will see that deletes the field. On a new object it won't do anything. Since the CoreData object will be looking for an int, it will ignore this and set it to null.
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
    
    /* this function takes a string with a decimal and converts it to an Int. This preserves the decimals value and signficant figures for later. How? since we know the sig figs of each field, we can always add the decimal back in later. This avoids any rounding error issues later on. This is especially important with math on money. Which is rendered less important because right now all I'm doing is persisting money... but hey, it's there for later, which is nice. */
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
    
    /* this function formats the mileageTextField based on the selected index. it changes the placeholder, the significant figures of the delegate and the label text */
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
    
    /* this function formats the priceTextField based on the selected index. it changes the placeholder, the significant figures of the delegate and the label text */
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
    
    /* this function goes through at sets all the fields and switches from the gasFillToEdit object. */
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
        
    }
    
    /* this function is a helper that switches the activity indicator on and off, hides and disable buttons that shouldn't be opperating while the app is connecting to the internet. True indicates that there is background activity you need to wait for. */
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
    
    /* this function will throw an alert for any string passed to it.*/
    func throwAlert(alertMessage: String){
        let alert = UIAlertController(title: "Alert", message: alertMessage, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    /* whenever the mileage switch is switched, this function is called. It saves that new state to the userInfoDictionary and calls the formatTextField function */
    @IBAction func mileageSwitched(sender: AnyObject) {
        userInfoDictionary["mileageSwitch"] = mileageSwitch.selectedSegmentIndex
        NSKeyedArchiver.archiveRootObject(userInfoDictionary!, toFile: self.filePath)
        
        formatMileageTextField()
        //if there is already text in the text field we need to recreate the string and move the decimal to the correct location.
        if let numberString = mileageTextField.text{
            if numberString != "" {
                let tempNumber = decimalStringToInt(numberString)
                //we can use the textFielDelegate to create the string, since it already has that function built in
                mileageTextField.text = mileageTextFieldDelegate.stringFromInt(tempNumber)
            }
        }
    }
    
    /* whenever the price switch is switched, this function is called. It saves that new state to the userInfoDictionary and calls the formatTextField function */
    @IBAction func priceSwitched(sender: AnyObject) {
        userInfoDictionary["priceSwitch"] = priceSwitch.selectedSegmentIndex
        NSKeyedArchiver.archiveRootObject(userInfoDictionary!, toFile: self.filePath)
        
        formatPriceTextField()
        //if there is already text in the text field we need to recreate the string and move the decimal to the correct location.
        if let numberString = priceTextField.text {
            if numberString != "" {
                let tempNumber = decimalStringToInt(numberString)
                //we can use the textFielDelegate to create the string, since it already has that function built in
                priceTextField.text = priceTextFieldDelegate.stringFromInt(tempNumber)
            }
        }
    }
    
    /* whenever the completely fill switch is changed, the state is saved to the userInfoDictionary */
    @IBAction func completeFillSwitched(sender: AnyObject) {
        userInfoDictionary["completeFillButton"] = fillSwitch.on
        NSKeyedArchiver.archiveRootObject(userInfoDictionary!, toFile: self.filePath)
    }
    
    /* for users wondering what we ask them to keep track of the complete fill, here's their answer. */
    @IBAction func completeFillTouchup(sender: AnyObject) {
        let alert = UIAlertController(title: "What is this?", message: "Knowing when you've completely filled the tank helps improve accuracy of your MPG. Turn the switch off whenever you don't get a full tank!", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Okie Dokie", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    /* this calls the dateViewController, there the user can change the date*/
    @IBAction func changeDateTouchUp(sender: AnyObject) {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("DateViewController") as! DateViewController
        controller.date = rightNow
        self.navigationController!.pushViewController(controller, animated: true)
    }
}
