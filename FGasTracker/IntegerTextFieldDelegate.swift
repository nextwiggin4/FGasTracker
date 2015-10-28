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
    var zeroString: String
    
    init(sigFig: Int){
        self.significantFigures = sigFig
        
        if sigFig <= 0 {
            self.zeroString = "0"
        } else {
            self.zeroString = "0."
            
            for var index = 0; index < significantFigures; ++index {
                self.zeroString = self.zeroString + "0"
            }
        }
    }
    
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
    
    func integerStringFromInt(value: Int) -> String {
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
    
    func decimalStringFromInt(value: Int) -> String{
        let devisor = Int(pow(Double(10),Double(self.significantFigures)))
        let decimal = value % devisor
        var decimalString = String(decimal)
        var check = 10
        
        for var index = 1; index < significantFigures; ++index {
            
            //print(check)
            if decimal < check {
                decimalString = "0" + decimalString
            }
            check = check * 10
            //print(decimalString)
        }
        /*
        if decimal < 10 {
            decimalString = "0" + decimalString
        }
        
        if decimal < 100{
            decimalString = "0" + decimalString
        }*/
        
        return decimalString

    }
    
    
    
}
