//
//  GasFill.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/13/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import UIKit
import CoreData

@objc(GasFill)

class GasFill : NSManagedObject {
    
    struct Keys {
        static let TotalMillage = "totalMillage"
        static let Trip = "currentTrip"
        static let Gallons = "gallons"
        static let PricePerGallon = "pricePerGallon"
        static let TotalPrice = "totalCost"
        static let Car = "car"
        static let Date = "date"
        static let CompleteFill = "completeFill"
        static let ObjectId = "objectId"
        static let CarObjectId = "carObjectId"
        static let UserObjectId = "userObjectId"
    }
    
    @NSManaged var totalMilage: NSNumber?
    @NSManaged var trip: NSNumber?
    @NSManaged var gallons: NSNumber?
    @NSManaged var pricePerGallon: NSNumber?
    @NSManaged var totalPrice: NSNumber?
    @NSManaged var car: Car
    @NSManaged var date: NSDate
    @NSManaged var completeFill: Bool
    @NSManaged var objectId: String?
    @NSManaged var carObjectId: String?
    @NSManaged var userObjectId: String?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("GasFill", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        totalMilage = dictionary[Keys.TotalMillage] as? NSNumber
        trip = dictionary[Keys.Trip] as? NSNumber
        gallons = dictionary[Keys.Gallons] as? NSNumber
        pricePerGallon = dictionary[Keys.PricePerGallon] as? NSNumber
        totalPrice = dictionary[Keys.TotalPrice] as? NSNumber
        car = dictionary[Keys.Car] as! Car
        date = dictionary[Keys.Date] as! NSDate
        completeFill = dictionary[Keys.CompleteFill] as! Bool
        objectId = dictionary[Keys.ObjectId] as? String
        carObjectId = dictionary[Keys.CarObjectId] as? String
        userObjectId = dictionary[Keys.UserObjectId] as? String

    }
    
    var gallonsDecimal: Double {
        get{
            return Double(gallons!)/1000.0
        }
    }
    
    
}
