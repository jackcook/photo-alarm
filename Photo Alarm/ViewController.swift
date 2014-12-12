//
//  ViewController.swift
//  Photo Alarm
//
//  Created by Jack Cook on 12/12/14.
//  Copyright (c) 2014 CosmicByte. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var picker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .Camera
        
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    func uploadToImgur(image: UIImage) {
        let imageData = UIImagePNGRepresentation(image)
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
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        var image = info[UIImagePickerControllerOriginalImage] as UIImage
        uploadToImgur(resizeImage(image))
        
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func resizeImage(image: UIImage) -> UIImage {
        let newSize = CGSizeMake(400, 400 / (image.size.width / image.size.height))
        let imageRef = image.CGImage
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh)
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        
        CGContextConcatCTM(context, flipVertical)
        CGContextDrawImage(context, CGRectMake(0, 0, newSize.width, newSize.height), imageRef)
        
        let newImageRef = CGBitmapContextCreateImage(context)
        let newImage = UIImage(CGImage: newImageRef)
        
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
