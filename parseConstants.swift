//
//  parseConstants.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/7/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import Foundation

extension parse {
    struct Constants {
        static let ApiKey = "K1fLxczAW8TOyZL0Ryx4UHP93lmCOpdwI1RPErXP"
        static let AppID = "QM4LPtnjSuqEn6tSUjzZNqrOesrCooKhjCA1elko"
        static let BaseURL = "https://api.parse.com/1/"
    }
    
    struct Resources {
        static let Users = "users"
        static let Login = "login"
        static let Logout = "logout"
        static let Cars = "classes/car"
        static let GasFill = "classes/gasFill"
    }
    
    struct Keys {
        static let ErrorStatusMessage = "status_message"
    }
}