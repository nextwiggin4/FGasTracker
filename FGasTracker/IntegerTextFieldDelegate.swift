//
//  IntegerTextFieldDelegate.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/23/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import UIKit

class IntegerTextFieldDelegate: NSObject, UITextFieldDelegate {
    
    var significantFigures: Int
    
    /* the zero string is created anytime the value is 0, it is set to the correct number of significant figures. 
        By using a lazy variable it isn't created until the first time the text field is touched, allowing it to create the correct string if the number of sigfigs changes */
    lazy var zeroString: String = {
        var tempZeroString = "0"
        
        if self.significantFigures <= 0 {
            tempZeroString = "0"
        } else {
            tempZeroString = "0."
        
            for var index = 0; index < self.significantFigures; ++index {
                tempZeroString = tempZeroString + "0"
            }
        }
        
        return tempZeroString
    }()
    
    init(sigFig: Int){
        self.significantFigures = sigFig
    }
    
    /* this function just grabs the text form the text field, gets rid of all non-numeric chacters, then re-creates the string with the decimals and commas in the right place. */
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        let oldText = textField.text! as NSString
        var newText = oldText.stringByReplacingCharactersInRange(range, withString: string)
        var newTextString = String(newText)
        
        let digits = NSCharacterSet.decimalDigitCharacterSet()
        var digitText = ""
        for c in newTextString.unicodeScalars{
            if digits.longCharacterIsMember(c.value){
                digitText.append(c)
            }
        }
        
        //print(digitText)
        if significantFigures > 0 {
            if let intNumber = Int(digitText) {
                newText =  self.integerStringFromInt(intNumber) + "." + self.decimalStringFromInt(intNumber)
            } else {
                newText = self.zeroString
            }
        } else {
            if let intNumber = Int(digitText) {
                newText =  self.integerStringFromInt(intNumber)
            } else {
                newText = self.zeroString
            }
        }
        
       
        newText = stringFromInt(Int(digitText))
        
        
        textField.text = newText
        
        return false
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField.text!.isEmpty {
            textField.text = self.zeroString
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
    
    /* this method is used to take a string of integers and converts it into a number with commas and decimals at the object's global sig. fig. */
    func stringFromInt(digitText: Int?) -> String{
        var newText: String
        
        if significantFigures > 0 {
            if let intNumber = digitText {
                newText =  self.integerStringFromInt(intNumber) + "." + self.decimalStringFromInt(intNumber)
            } else {
                newText = self.zeroString
            }
        } else {
            if let intNumber = digitText {
                newText =  self.integerStringFromInt(intNumber)
            } else {
                newText = self.zeroString
            }
        }
        return newText
    }
    
    /* creates a string and adds commans to the whole interger. */
    func integerStringFromInt(value: Int) -> String {
        //this takes the long integer and converts it to just the whole integer part
        let numberToAddCommas = String(value/Int(pow(Double(10),Double(self.significantFigures))))
        
        let digits = NSCharacterSet.decimalDigitCharacterSet()
        var intDigitText = ""
        var i = numberToAddCommas.unicodeScalars.count - 1
        for c in numberToAddCommas.unicodeScalars{
            if digits.longCharacterIsMember(c.value){
                intDigitText.append(c)
                if (i%3 == 0 && i != 0){
                    intDigitText = intDigitText + ","
                }
                i--
            }
        }
        
        return intDigitText
        
    }
    
    /* creates a decimal string at the correct significant figures.  */
    func decimalStringFromInt(value: Int) -> String{
        //this takes the short integer and converts it to just the decimal portion
        let devisor = Int(pow(Double(10),Double(self.significantFigures)))
        let decimal = value % devisor
        var decimalString = String(decimal)
        var check = 10
        
        //adds the necessary zeros preceding the decimal (if necessary)
        for var index = 1; index < significantFigures; ++index {
            
            if decimal < check {
                decimalString = "0" + decimalString
            }
            check = check * 10
        }

        return decimalString

    }
    
    
    
}
