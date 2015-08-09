//
//  ViewController.swift
//  AllocineTest
//
//  Created by Denis Grangé on 23/07/2015.
//  Copyright (c) 2015 Bignolles. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let ALLOCINE_URL = "http://api.allocine.fr/rest/v3/"
    //let PARTNER_KEY = "20078C967592"
    let PARTNER_KEY = "100043982026"
    let SECRET_KEY = "29d185d98c984a359e6e6f26a0474269"
    let SEARCH_API = "search?"
    let MOVIE_API = "movie?"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func testMovie() {
        // NOTE: Parameters must be in that EXACT same order
        var params: [(key: String, value: String)] = [("code", "210493"), ("profile", "large"), ("filter", "movie"), ("format", "json"), ("striptags", "synopsis,synopsisshort")]
        
        // Step 1: Build param query string (including partney key and date)
        let paramQuery = buildParamQuery(params)
        
        // Step 2: Generate signature
        var sig = "&sig=" + generateSignature(paramQuery)
        
        // Step 3: Assemble URL
        var url = ALLOCINE_URL + MOVIE_API + paramQuery + sig
        
        // Step 4: Build HTTP request
        var request = NSMutableURLRequest()
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        
        // Step 5: Send HTTP request
        var session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        var task = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            var requestReply = NSString(data: data, encoding: NSASCIIStringEncoding)
            NSLog("requestReply: %@", requestReply!);
        })
        task.resume()

    }
    
    // Build the query string from and input parameters
    private func buildParamQuery(params: [(key: String, value: String)]) -> String {
        // Prepend the partney key
        var query = "partner=" + PARTNER_KEY

        for (key, value) in params {
            let encodedValue = encodeValue(value)
            query += String(format: "&%@=%@", key, encodedValue)
        }
        
        // Append the date
        query += "&sed=" + generateDate()
        
        return query
    }
    
    // Generate signature
    private func generateSignature(query: String) -> String {
        // Step 1: Prepend secret key to query
        let clearString = SECRET_KEY + query
        
        // Step 2: Hash the string through SHA1
        let hash = sha1Hash(clearString)
        
        // Step 3: Convert hash to Base 64
        let signature = hexToBase64(hash)!
        let encodedSignature = encodeValue(signature)
        
        return encodedSignature
    }
    
    // Generate date
    private func generateDate() -> String {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.stringFromDate(NSDate())
    }
    
    // Hash string using SHA1. Returns string in hexadecimal format
    private func sha1Hash(string: String) -> String {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        var digest = [UInt8](count:Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
        CC_SHA1(data.bytes, CC_LONG(data.length), &digest)
        let output = NSMutableString(capacity: Int(CC_SHA1_DIGEST_LENGTH))
        for byte in digest {
            output.appendFormat("%02x", byte)
        }
        
        return output as String
    }
    
    // Convert String from hexadecimal to Base64 representation
    private func hexToBase64(hexString: String) -> String? {
        // Trim string
        let trimmedString = hexString.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<> ")).stringByReplacingOccurrencesOfString(" ", withString: "")
        
        // Make sure the cleaned up string consists solely of hex digits, and that we have an even number of them
        var error: NSError?
        let regex = NSRegularExpression(pattern: "^[0-9a-f]*$", options: .CaseInsensitive, error: &error)
        let found = regex?.firstMatchInString(trimmedString, options: nil, range: NSMakeRange(0, count(trimmedString)))
        if ((found == nil) || (found?.range.location == NSNotFound) || (count(trimmedString) % 2 != 0)) {
            return nil
        }
        
        // Build NSData object
        let data = NSMutableData(capacity: count(trimmedString) / 2)
        for var index = trimmedString.startIndex; index < trimmedString.endIndex; index = index.successor().successor() {
            let byteString = trimmedString.substringWithRange(Range<String.Index>(start: index, end: index.successor().successor()))
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data?.appendBytes([num] as [UInt8], length: 1)
        }
        
        // Get Base64 string from NSData
        let base64String = data!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
        
        return base64String
    }
    
    // Encode a query parameter for URL
    private func encodeValue(param: String) -> String {
        let customSet = NSCharacterSet(charactersInString: "=,\"#%<>[\\]^`{|}").invertedSet
        let encodedParam = param.stringByAddingPercentEncodingWithAllowedCharacters(customSet)
        return encodedParam!
    }
}