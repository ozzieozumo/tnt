//
//  tntHomeViewController.swift
//  tnt
//
//  Created by Luke Everett on 4/6/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import UIKit
import AWSCore
import AWSDynamoDB
import AWSCognitoIdentityProvider
import AWSS3

class tntHomeViewController: UIViewController {
    
    var athleteId: String = "1"
    var selectedMeet: Meet? = nil
    
    @IBOutlet weak var tntName: UITextField!
    @IBOutlet weak var profileImage: UIImageView!
    
    // current level displays
    
    @IBOutlet weak var currentLevelTR: UITextField!
    @IBOutlet weak var currentLevelDMT: UITextField!
    @IBOutlet weak var currentLevelTU: UITextField!
    @IBOutlet weak var nextMeetInfo: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntHomeViewController.observerMoreAthletes(notification:)), name: Notification.Name("tntAthleteDataLoaded"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntHomeViewController.observerProfileImageLoaded(notification:)), name: Notification.Name("tntProfileImageLoaded"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntHomeViewController.observerMeetLoaded(notification:)), name: Notification.Name("tntMeetLoaded"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Display athlete data if available, otherwise request it (and wait to be notified)
        if tntLocalDataManager.shared.athletes.count > 0 {
            
            displayAthleteData()
            displayProfileImage()
            displayMeetInfo()
            
        } else {
            
            requestAthleteData()
            
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    func tntPreSignedURL(unsignedURL: String) -> String {
        
        var preSignedURL : String? = nil
        let signingGroup = DispatchGroup()
        
        precondition(!Thread.isMainThread, "tntPreSignedURL : don't call this func from the main thread")
        
        let preSignedRequest = AWSS3GetPreSignedURLRequest()
        preSignedRequest.bucket = "ozzieozumo.tnt"
        
        // find the key (filename) starting after ozzieozumo.tnt/ 
        
        let keyStart = unsignedURL.index(unsignedURL.range(of: preSignedRequest.bucket)!.upperBound, offsetBy: 1)
        
        preSignedRequest.key = unsignedURL.substring(from: keyStart)
        preSignedRequest.httpMethod = .GET
        preSignedRequest.expires = Date().addingTimeInterval(48*60*60)
        
        let preSigner = AWSS3PreSignedURLBuilder.default()
        
        // not sure about this structure -- I want to treat this function as a synchronous call.  
        // Using the dispatchgroup and wait is one way to to do that.  Alternatively, the function could accept a completion handler. 
        // Perhaps, I should check inside the function that it is never being called on the main thread (which shouldn't wait on asynch tasks. 
        // However, it seems perfectly fine to have other (non main queue) tasks wait for this call to succeeed or fail
        
        signingGroup.enter()
        
        preSigner.getPreSignedURL(preSignedRequest).continueWith {
            (task) in
            
            if let error = task.error as? NSError {
                print("Error: \(error)")
                signingGroup.leave()
                return nil
            }
            
            preSignedURL = task.result!.absoluteString
            print("Download presignedURL is: \(preSignedURL)")
            signingGroup.leave()
            return nil
            
        }
        
        signingGroup.wait()
        return preSignedURL!
    }
    
    func requestAthleteData() {
    
        tntLocalDataManager.shared.clearTNTObjects()
        tntSynchManager.shared.loadCache()
    
    }
    
    func displayAthleteData() {
        // Display the data for the current athlete 
        
        if let athlete = tntLocalDataManager.shared.getAthleteById(athleteId: athleteId) {
            let firstName = athlete.firstName ?? ""
            let lastName =  athlete.lastName ?? ""
            tntName.text = firstName + " " + lastName
        }
    
        // current level display
        
        //let eventLevels = athlete.value(forKey: "eventLevels") as! [String: Int]
        
        let levelTRint = 6 // eventLevels["TR"]
        let levelTUint = 7 // eventLevels["TU"]
        let levelDMTint = 7 // eventLevels["DMT"]
        
        currentLevelTR.text =  levelTRint != nil ? "\(levelTRint)" : ""
        currentLevelTU.text = levelTUint != nil ? "\(levelTUint)" : ""
        currentLevelDMT.text = levelDMTint != nil ? "\(levelDMTint)" : ""
        
    }
    
    func displayProfileImage() {
        // display an updated profile image
        
        if let athlete = tntLocalDataManager.shared.getAthleteById(athleteId: athleteId) {
        
            let img = UIImage(data: athlete.profileImage! as Data)
            self.profileImage.image = img
        }
        
        
    }
    
    func displayMeetInfo() {
        
        // set the current meet if it is not set already 
        
        let defaults = UserDefaults.standard
        let dateSelect = defaults.bool(forKey: "nextMeetSelectByDate")
        
        if dateSelect {
            selectedMeet = Meet.nextMeet(startDate: Date())
             
        } else {
            selectedMeet = Meet.lastSelected()
            
        }
        
               
        if let meet = selectedMeet {
            // format and display info about the next meet
            
            let meetTitle = meet.title ?? ""
            let meetSubtitle = meet.subTitle ?? ""
            
            nextMeetInfo.text = "\(meetTitle) \n \(meetSubtitle)"
            
        } else {
            // no saved meet and no next meet
            nextMeetInfo.text = "No Meets Available"
        }
        
    }
    
    // Mark : Segue processing
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destvc = segue.destination as? tntScoringViewController {
            
            // Set the meet and athlete on the scoring view controller
        
            destvc.athleteId = athleteId
            destvc.meetId = selectedMeet?.id ?? ""
            return
            
        }
        
        if let destvc = segue.destination as? tntVideosTableViewController {
            
            destvc.athleteMO = tntLocalDataManager.shared.athletes[athleteId]
            destvc.meetMO = self.selectedMeet
            
            return
        }
    }
    
    
    

    
    // MARK: Notification Observers
    
    func observerMoreAthletes(notification: Notification) {
        // This notification received when athlete is loaded into local cache from cloud DB
        // Switch back to the main thread to update the UI
        
        DispatchQueue.main.async{
            self.displayAthleteData()
        }
    
    }
    
    func observerProfileImageLoaded(notification: Notification) {
        DispatchQueue.main.async{
            self.displayProfileImage()
            
        }
        
    }
    
    func observerMeetLoaded(notification: Notification) {
        DispatchQueue.main.async{
            self.displayMeetInfo()
            
        }
        
    }


    
}
