//
//  ViewController.swift
//  Photo Alarm
//
//  Created by Jack Cook on 12/12/14.
//  Copyright (c) 2014 CosmicByte. All rights reserved.
//

import AVFoundation
import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var picker: UIImagePickerController!
    
    var player: AVAudioPlayer!
    var soundTimer: NSTimer!
    
    var tagsToMatch = [String]()
    var setImage = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func createImagePicker() {
        picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .Camera
        
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    func startAlarm() {
        playAlarmSound()
        soundTimer = NSTimer(timeInterval: 5.0, target: self, selector: "playAlarmSound", userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(soundTimer, forMode: NSRunLoopCommonModes)
    }
    
    func playAlarmSound() {
        let soundURL = NSBundle.mainBundle().URLForResource("alarm", withExtension: "mp3")
        player = AVAudioPlayer(contentsOfURL: soundURL, error: nil)
        player.prepareToPlay()
        player.play()
    }
    
    func stopAlarm() {
        player.stop()
        soundTimer.invalidate()
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
        let url = NSURL(string: "https://api.clarifai.com/v1/tag?url=http://i.imgur.com/\(imageID).png")!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        request.addValue("Bearer jhGepBFqvp22ru1vQtvo0d4yVrWPEZ", forHTTPHeaderField: "Authorization")
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) -> Void in
            self.parseTags(data)
        })
    }
    
    func parseTags(data: NSData) {
        if let responseData = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: nil) as? NSDictionary {
            if let results = responseData["results"] as? NSArray {
                if let resultsDict = results[0] as? NSDictionary {
                    if let resultArray = resultsDict["result"] as? NSDictionary {
                        if let tagArray = resultArray["tag"] as? NSDictionary {
                            if let tags = tagArray["classes"] as? [String] {
                                var newTags = [String]()
                                for tag in tags {
                                    if setImage {
                                        tagsToMatch.append(tag)
                                    } else {
                                        newTags.append(tag)
                                    }
                                }
                                
                                if !setImage {
                                    checkTags(newTags)
                                } else {
                                    println("done")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func checkTags(newTags: [String]) {
        var matches = 0
        for tag in newTags {
            if contains(tagsToMatch, tag) {
                matches += 1
            }
        }
        
        if matches > 12 {
            stopAlarm()
        }
        
        println("done: \(matches)")
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        var image = info[UIImagePickerControllerOriginalImage] as UIImage
        uploadToImgur(resizeImage(image))
        
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func setImage(sender: AnyObject) {
        setImage = true
        createImagePicker()
    }
    
    @IBAction func demonstrate(sender: AnyObject) {
        setImage = false
        createImagePicker()
        startAlarm()
    }
    
    func resizeImage(image: UIImage) -> UIImage {
        let newSize = CGSizeMake(200, 200 / (image.size.width / image.size.height))
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
