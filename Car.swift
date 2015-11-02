//
//  Car.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/13/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import UIKit
import CoreData

@objc(Car)

class Car : NSManagedObject {
    
    struct Keys {
        static let Make = "make"
        static let Model = "model"
        static let Year = "year"
        static let ObjectId = "objectId"
        static let Nickname = "nickname"
        static let userObjectId = "userjObectId"
    }
    
    /* the variables used in this class are used for keeping track of car information mostly. The objectIds are used for keeping synced with parse. updates and deletes require a known Id */
    @NSManaged var make: String?
    @NSManaged var model: String?
    @NSManaged var year: NSNumber?
    @NSManaged var objectId : String?
    @NSManaged var userObjectId : String?
    @NSManaged var nickname: String
    @NSManaged var gasFill: [GasFill]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    //adds all the necessary fields if available form a dictionary. This can be built on the same dictionary used to post to Parse.
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Car", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        make = dictionary[Keys.Make] as? String
        model = dictionary[Keys.Model] as? String
        year = dictionary[Keys.Year] as? NSNumber
        objectId = dictionary[Keys.ObjectId] as? String
        userObjectId = dictionary[Keys.userObjectId] as? String
        nickname = dictionary[Keys.Nickname] as! String
        
    }
    
    
    
}
