//
//  ViewController.swift
//  oneclick
//
//  Created by twodayslate on 8/20/15.
//  Copyright (c) 2015 twodayslate. All rights reserved.
//

import UIKit
import CoreData
import GameKit
import AVFoundation

class ViewController: UIViewController {

    var button : UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    
    var background : UIImage?
    var backgroundView : UIImageView?
    
    var authStatus : AVAuthorizationStatus?
    var stillImageOutput = AVCaptureStillImageOutput()
    var previewLayer : AVCaptureVideoPreviewLayer?
    let captureSession = AVCaptureSession()
    var previewView : UIView?
    
    var captureDevice : AVCaptureDevice?
    var scoreLabel : UILabel = UILabel.new()
    var timer = NSTimer()
    
    
    var score : Int = 0
    var gameCenterEnabled = false
    var leaderboardIdentifier = ""
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    let seconds = 98847.0;
    var latestTime = NSDate(timeIntervalSinceNow: -98847.0)
    // FOR TESTING
    //let seconds = 10.0; //
    //var latestTime = NSDate(timeIntervalSinceNow: -10)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.authenticateLocalPlayer()
        
        button.frame = self.view.frame
        button.bounds = self.view.bounds
        button.center = self.view.center
        button.backgroundColor = UIColor.clearColor()
        button.titleLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        button.titleLabel?.textAlignment = NSTextAlignment.Center
        
        button.titleLabel?.layer.shadowColor = UIColor.blackColor().CGColor
        button.titleLabel?.layer.shadowRadius = 2
        button.titleLabel?.layer.shadowOffset = CGSizeZero
        button.titleLabel?.layer.masksToBounds = false
        button.titleLabel?.layer.shadowOpacity = 1.0
       
        button.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleTopMargin | UIViewAutoresizing.FlexibleBottomMargin | UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        
        let singleTap = UITapGestureRecognizer(target: self, action: Selector("singleTap:"))
        let doubleTap = UITapGestureRecognizer(target: self, action: Selector("doubleTap:"))
        singleTap.numberOfTapsRequired = 1;
        doubleTap.numberOfTapsRequired = 2;
        singleTap.requireGestureRecognizerToFail(doubleTap)
        button.addGestureRecognizer(singleTap)
        button.addGestureRecognizer(doubleTap)
        
        scoreLabel.frame = CGRect(x: self.view.center.x - self.view.frame.width/2, y: self.view.frame.height - 35, width: self.view.frame.width, height: 30)
        scoreLabel.textAlignment = NSTextAlignment.Center
        scoreLabel.textColor = UIColor.whiteColor()
        scoreLabel.font = UIFont(name: scoreLabel.font.fontName, size: 14)
        scoreLabel.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleTopMargin | UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        
        let size = self.view.frame.size
        UIGraphicsBeginImageContextWithOptions(size, true, 0);
        UIColor.redColor().setFill()
        UIRectFill(CGRectMake(0, 0, size.width, size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        background = image
        
        
//        button.addTarget(self, action: "buttonClicked:", forControlEvents: UIControlEvents.TouchUpInside)
//        button.addTarget(self, action: "buttonClicked:", forControlEvents: UIControlEvents.)
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateButton"), userInfo: nil, repeats: true)
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateScore"), userInfo: nil, repeats: true)
        
        getDataStoreValues()
        
        println("Latest Time = " + latestTime.description)
        println("Score = " + score.description)
        println("Background = " + background!.description)
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        let devices = AVCaptureDevice.devices()
        authStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        if authStatus != AVAuthorizationStatus.Authorized && !NSUserDefaults.standardUserDefaults().boolForKey("hasLaunched") {
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: {
                (granted: Bool) -> Void in
                // If permission hasn't been granted, notify the user.
                if !granted {
                    dispatch_async(dispatch_get_main_queue(), {
                        UIAlertView(
                            title: "Opted out of camera usage.",
                            message: "You can change this in your privacy settings.",
                            delegate: self,
                            cancelButtonTitle: "OK").show()
                    })
                }
            })
        }
        
        if(authStatus == AVAuthorizationStatus.Authorized) {
            for device in devices {
                // Make sure this particular device supports video
                if (device.hasMediaType(AVMediaTypeVideo)) {
                    // Finally check the position and confirm we've got the back camera
                    if(device.position == AVCaptureDevicePosition.Front) {
                        captureDevice = device as? AVCaptureDevice
                        if captureDevice != nil {
                            println("Capture device found")
                            
                            var err : NSError? = nil
                            captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
                            
                            if err != nil {
                                println("error: \(err?.localizedDescription)")
                            }
                            captureSession.startRunning()
                            
                            stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                            
                            captureSession.addOutput(stillImageOutput)
                        }
                    }
                }
            }
        }
        // Loop through all the capture devices on this phone
        
        
        
        backgroundView = UIImageView(frame: self.view.frame)
        backgroundView?.contentMode = UIViewContentMode.ScaleAspectFit
        backgroundView?.image = background
    
        
        println("current time = " + NSDate().description)
        println("latestTime = "+latestTime.description)
        
        println(managedObjectContext)
        
        updateButton()
        updateScore()
        
        previewView = UIView(frame: self.view.frame)
        
        self.view.addSubview(backgroundView!)
        
        if authStatus == AVAuthorizationStatus.Authorized {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = self.view.layer.frame
            
            previewView?.layer.insertSublayer(previewLayer, below: backgroundView?.layer)
            self.view.insertSubview(previewView!, belowSubview: backgroundView!)
            //self.view.layer.insertSublayer(previewLayer, below: backgroundView?.layer)
        }
        self.view.addSubview(button)
        self.view.insertSubview(scoreLabel, aboveSubview: button)
        
        if !NSUserDefaults.standardUserDefaults().boolForKey("hasLaunched") {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasLaunched")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    
        func authenticateLocalPlayer() {
            var localPlayer = GKLocalPlayer.localPlayer()
            localPlayer.authenticateHandler = {(viewController : UIViewController!, error : NSError!) -> Void in
                if viewController != nil {
                    self.presentViewController(viewController, animated: true, completion: nil)
                } else {
                    if localPlayer.authenticated {
                        self.gameCenterEnabled = true
                        
                        localPlayer.loadDefaultLeaderboardIdentifierWithCompletionHandler({ (leaderboardIdentifier : String!, error : NSError!) -> Void in
                            if error != nil {
                                println(error.localizedDescription)
                            } else {
                                self.leaderboardIdentifier = leaderboardIdentifier
                            }
                        })
                        
                    } else {
                        self.gameCenterEnabled = false
                    }
                }
            }
        }
    
    func reportScore() {
        let gcscore = GKScore.init(leaderboardIdentifier: leaderboardIdentifier)
        gcscore.value = Int64(score) as Int64;

        GKScore.reportScores([gcscore], withCompletionHandler: {(error : NSError!) -> Void in
            if (error != nil) {
                print(error.localizedDescription)
            }
        })
    }
        
    func takePicture() {
        println("Capturing image")
        
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo){
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {
                (sampleBuffer, error) in
                var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                var dataProvider = CGDataProviderCreateWithCFData(imageData)
                var cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, kCGRenderingIntentDefault)
                var image = UIImage(CGImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.LeftMirrored)
                
                self.background = image
                self.backgroundView?.image = self.background
                
                println("Background set")
                self.updateDataStore(defaults: true)
                println("Newest latestTime = " + self.latestTime.description)
                self.updateButton()
                self.updateScore()
            })
        } else {
            self.updateDataStore(tm: self.latestTime, scr: self.score, bkg: self.background)
        }
    }
    
    func updateDataStore(tm : NSDate? = nil, scr : NSNumber? = nil, bkg :UIImage? =  nil, defaults : Bool? = false) {
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Entity]
        
        if fetchResults?.count <= 0 {
            println("Core Data does not exist")
            let newItem = NSEntityDescription.insertNewObjectForEntityForName("Entity", inManagedObjectContext: self.managedObjectContext!) as! Entity
            
            if tm != nil {
                newItem.date = tm!
            } else {
                newItem.date = latestTime
            }
            if scr != nil {
                newItem.score = scr!
            } else {
                newItem.score = score
            }
            if bkg != nil {
                newItem.background = UIImageJPEGRepresentation(bkg, 1)
            } else {
                newItem.background = UIImageJPEGRepresentation(background, 1)
            }
        } else {
            println("Core Data exists")
            let t : Entity = (fetchResults!.first as Entity?)!
            
            
            if defaults == true {
                t.date = latestTime
                t.score = score
                t.background = UIImageJPEGRepresentation(background, 1)
            }
            
            if tm != nil {
                println("Updating t.date =" + tm!.description)
                t.date = tm!
            }
            if scr != nil {
                t.score = scr!
            }
            if bkg != nil {
                t.background = UIImageJPEGRepresentation(bkg!, 1)
            }
            
            
        }
        
        var error : NSError? = nil
        if !self.managedObjectContext!.save(&error) {
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        getDataStoreValues()
        println("Latest Time = " + latestTime.description)
        println("Score = " + score.description)
        println("Background = " + background!.description)
    }
    
    func getDataStoreValues() {
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Entity]
        
        if fetchResults?.count <= 0 {
            println("Core Data does not exist")
            updateDataStore(defaults: true)
        } else {
            println("Core Data exists")
            let t : Entity = (fetchResults!.first as Entity?)!
            latestTime = t.date
            score = Int(t.score)
            background = UIImage(data: t.background)
        }
    }
    
    func doubleTap (gesture : UIGestureRecognizer) {
        println("double tapped")
        let goal : NSDate = NSDate(timeInterval: seconds as NSTimeInterval, sinceDate: latestTime) as NSDate
        let timeTuple = secondsToHoursMinutesSeconds(Int(goal.timeIntervalSinceNow))
        
        if goal.timeIntervalSinceNow < -120.0 {
            
            reportScore()
            latestTime = NSDate()
            score = 1
            takePicture()
        }
        
        updateButton()
        updateScore()
    }
    
    func singleTap (gesture : UIGestureRecognizer) {
        println(NSDate().description)
        
        let goal : NSDate = NSDate(timeInterval: seconds as NSTimeInterval, sinceDate: latestTime) as NSDate
        let timeTuple = secondsToHoursMinutesSeconds(Int(goal.timeIntervalSinceNow))
        
        if goal.timeIntervalSinceNow < 0 && goal.timeIntervalSinceNow > -120.0 {
            println("updating time")
            reportScore()
            latestTime = NSDate()
            score = score + 1
            takePicture()
        }
        
        updateButton()
        updateScore()
    }
    
    func error() {
        println("error")
    }
    
    func updateScore() {
        scoreLabel.text = "Current Streak: "+score.description
    }
    
    func updateButton() {
        
        let goal : NSDate = NSDate(timeInterval: seconds as NSTimeInterval, sinceDate: latestTime) as NSDate
        let timeTuple = secondsToHoursMinutesSeconds(Int(goal.timeIntervalSinceNow))
        
        var title : String = timeTuple.0.description + " hours "
        title += timeTuple.1.description + " minutes "
        title += timeTuple.2.description + " seconds"
        
        if goal.timeIntervalSinceNow < 0 && goal.timeIntervalSinceNow > -120.0 {
            title = "Tap Me!"
            if authStatus != AVAuthorizationStatus.Authorized {
                button.backgroundColor = UIColor.greenColor()
            } else {
                button.backgroundColor = UIColor.clearColor()
            }
            backgroundView?.hidden = true
        } else {
            button.backgroundColor = UIColor.clearColor()
            backgroundView?.hidden = false
        }
        
        if goal.timeIntervalSinceNow < -120.0 {
            title = "You Lose!\nDouble Tap to Restart!"
            if authStatus != AVAuthorizationStatus.Authorized {
                button.backgroundColor = UIColor.redColor()
            } else {
                button.backgroundColor = UIColor.clearColor()
            }
            backgroundView?.hidden = true
        }
        
        
        button.setTitle(title, forState: UIControlState.Normal)
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    override func shouldAutorotate() -> Bool {
     return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        
        var rotation : CGFloat = 0.0

        if toInterfaceOrientation == UIInterfaceOrientation.Portrait {
            rotation = 0
        } else if toInterfaceOrientation == UIInterfaceOrientation.LandscapeLeft {
            rotation = CGFloat(M_PI/2.0)
        } else if toInterfaceOrientation == UIInterfaceOrientation.LandscapeRight {
                    rotation = CGFloat(-M_PI/2.0)
        } else {
            rotation = CGFloat(M_PI)
        }
        
        UIView.animateWithDuration(duration, animations: {() in
            self.previewView?.transform = CGAffineTransformMakeRotation(rotation)
            self.previewView?.frame = self.view.frame
            self.backgroundView?.transform = CGAffineTransformMakeRotation(rotation)
            self.backgroundView?.frame = self.view.frame
        })
    }

}

