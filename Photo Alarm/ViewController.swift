//
//  ViewController.swift
//  Photo Alarm
//
//  Created by Jack Cook on 12/12/14.
//  Copyright (c) 2014 CosmicByte. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageData = UIImagePNGRepresentation(UIImage(named: "jackcook.png"))
        IMGImageRequest.uploadImageWithData(imageData, title: "Image", success: { (image) -> Void in
            println("\(image.imageID)")
            self.submitImggaRequest(image.imageID)
        }, progress: nil) { (error) -> Void in
            println("\(error.localizedDescription)")
        }
    }
    
    func submitImggaRequest(imageID: String) {
        let url = NSURL(string: "http://api.imagga.com/v1/tagging?url=http://i.imgur.com/\(imageID).png")!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        request.addValue("Basic YWNjXzJlNTZmOTk0YjI0N2M1ZDphYTY0YjM5YzMyNTFlNjA4Njc2ODkyMmFhNjk3MDExYw==", forHTTPHeaderField: "Authorization")
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) -> Void in
            self.parseTags(data)
        })
    }
    
    func parseTags(data: NSData) {
        if let responseData = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: nil) as? NSDictionary {
            if let results = responseData["results"] as? NSArray {
                if let resultsDict = results[0] as? NSDictionary {
                    if let tags = resultsDict["tags"] as? NSArray {
                        for tag in tags {
                            if let tagDict = tag as? NSDictionary {
                                if let confidence = tagDict["confidence"] as? Float {
                                    if let tag = tagDict["tag"] as? String {
                                        println("\(tag): \(confidence)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
