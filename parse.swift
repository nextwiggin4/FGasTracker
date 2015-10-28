//
//  parse.swift
//  FGasTracker
//
//  Created by Matthew Dean Furlo on 10/7/15.
//  Copyright © 2015 FurloBros. All rights reserved.
//

import Foundation

class parse : NSObject {
    
    typealias CompletionHandler = (result: AnyObject!, error: NSError?) -> Void
    
    var session : NSURLSession
    
    override init(){
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    func registerNewUser(username: String, password: String, completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        
        let session = NSURLSession.sharedSession()
        let urlString = parse.Constants.BaseURL + parse.Resources.Users
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.addValue(parse.Constants.AppID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(parse.Constants.ApiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("1", forHTTPHeaderField: "X-Parse-Revocable-Session")
        request.HTTPBody = "{\"username\":\"\(username)\",\"password\":\"\(password)\"}".dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                let newError = parse.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                parse.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        task.resume()
        
        return task
    }
    
    func loginUser(methodArguments: [String : AnyObject], completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        
        let session = NSURLSession.sharedSession()
        let urlString = parse.Constants.BaseURL + parse.Resources.Login + parse.escapedParameter(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        request.addValue(parse.Constants.AppID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(parse.Constants.ApiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("1", forHTTPHeaderField: "X-Parse-Revocable-Session")
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                let newError = parse.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                parse.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        task.resume()
        
        return task
        
    }
    
    func logoutUser(sessionToken: String, completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        
        let session = NSURLSession.sharedSession()
        let urlString = parse.Constants.BaseURL + parse.Resources.Logout
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.addValue(parse.Constants.AppID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(parse.Constants.ApiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue(sessionToken, forHTTPHeaderField: "X-Parse-Session-Token")
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                let newError = parse.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                parse.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        task.resume()
        
        return task
        
    }
    
    func getFromParse(method: String, methodArguments: [String : AnyObject], completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        
        let session = NSURLSession.sharedSession()
        let urlString = parse.Constants.BaseURL + method + parse.escapedParameter(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        request.addValue(parse.Constants.AppID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(parse.Constants.ApiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                let newError = parse.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                parse.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        task.resume()
        
        return task
        
    }
    
    func postToParse(method: String, methodArguments: [String : AnyObject], completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        
        let session = NSURLSession.sharedSession()
        let urlString = parse.Constants.BaseURL + method
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.addValue(parse.Constants.AppID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(parse.Constants.ApiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        var JSONData : NSData
        var JSONText : NSString?
        
        do{
            JSONData = try NSJSONSerialization.dataWithJSONObject(methodArguments, options: NSJSONWritingOptions.PrettyPrinted)
            JSONText = NSString(data: JSONData, encoding: NSASCIIStringEncoding)!
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        request.HTTPBody = JSONText!.dataUsingEncoding(NSUTF8StringEncoding)
        
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                let newError = parse.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                parse.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        task.resume()
        
        return task
        
    }
    
    func putToParse(method: String, objectId: String, methodArguments: [String : AnyObject], completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        
        let session = NSURLSession.sharedSession()
        let urlString = parse.Constants.BaseURL + method + "/" + objectId
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PUT"
        request.addValue(parse.Constants.AppID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(parse.Constants.ApiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        var JSONData : NSData
        var JSONText : NSString?
        
        do{
            JSONData = try NSJSONSerialization.dataWithJSONObject(methodArguments, options: NSJSONWritingOptions.PrettyPrinted)
            JSONText = NSString(data: JSONData, encoding: NSASCIIStringEncoding)!
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        request.HTTPBody = JSONText!.dataUsingEncoding(NSUTF8StringEncoding)
        
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                let newError = parse.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                parse.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        task.resume()
        
        return task
        
    }
    
    func deleteFromParse(method: String, objectId: String, completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        
        let session = NSURLSession.sharedSession()
        let urlString = parse.Constants.BaseURL + method + "/" + objectId
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "DELETE"
        request.addValue(parse.Constants.AppID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(parse.Constants.ApiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                let newError = parse.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                parse.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        task.resume()
        
        return task
        
    }
    
    // MATTHEW: - Helpers
    
    
    // Try to make a better error, based on the status_message from Parse. If we cant then return the previous error
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject] {
            if let errorMessage = parsedResult[parse.Keys.ErrorStatusMessage] as? String {
                
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                
                return NSError(domain: "Parse Error", code: 1, userInfo: userInfo)
            }
        }
        
        return error
    }
    
    
    // Parsing the JSON
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHandler) {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        
        do{
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    
    // URL Encoding a dictionary into a parameter string
    class func escapedParameter(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            let stringValue = "\(value)"
            
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            
            urlVars += [key + "=" + "\(escapedValue)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    class func sharedInstance() -> parse {
        
        struct Singleton {
            static var sharedInstance = parse()
        }
        
        return Singleton.sharedInstance
    }
    
    
    
}