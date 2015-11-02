//
//  AddCarExtension.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/24/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import UIKit

extension AddCarViewController {
    
    func subscribeToKeyboardNotifications() {
        //there are two observers in the default NotificationCenter we care about, the Keyboard appearing and disappearing. This is where we add both observers.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications(){
        //this is where the observers are removed when whenever the viewWillDisapear is called.
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillShow(Notification: NSNotification) {
        //this function is called when the keyboard is called, but we only really care when the bottom text field calls for it. Check to make sure that it is the bottom text field, then set the height of frame to the height of the keybaord. This shifts the entire frame up so the bottom text field is visible when the keyboard is up. Digital high five!
        if nicknameTextField.isFirstResponder(){
            self.view.frame.origin.y = 0.0
            self.view.frame.origin.y -= getKeyboardHeight(Notification)
        } else if ((!nicknameTextField.isFirstResponder() && self.view.frame.origin.y < 0 )){
            self.view.frame.origin.y = 0.0
        }
    }
    
    func keyboardWillHide(Notification: NSNotification) {
        //As much fun as it was moving the whole frame out of the way for the keybaord, we should probably put it back now that the keyboard is disappearing. Here we'll again to check to make sure it's the bottom keyboard we're dealing with, than move the frame back in place as the keyboard leaves.
        
        self.view.frame.origin.y = 0.0
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        //here we create a notification an object of the user info that is sent by the keyboard.
        let userInfo = notification.userInfo
        //the user info is a dictionary, one of the key values hapens to hold a CGRect of the keyboard. Well grab just the height parameter and retun that.
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
}