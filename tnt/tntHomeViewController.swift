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
    
    var selectedAthlete: Athlete? = nil
    var selectedMeet: Meet? = nil
    
    @IBOutlet weak var tntName: UITextField!
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet var editAthleteButton: UIButton!
    @IBOutlet var selectAthleteButton: UIButton!
    
    // current level displays
    
    @IBOutlet weak var currentLevelTR: UITextField!
    @IBOutlet weak var currentLevelDMT: UITextField!
    @IBOutlet weak var currentLevelTU: UITextField!
    @IBOutlet weak var nextMeetInfo: UITextView!
    
    // Current meet display
    @IBOutlet var meetMonth: UILabel!
    @IBOutlet var meetDay: UILabel!
    @IBOutlet var meetYear: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntHomeViewController.observerMoreAthletes(notification:)), name: Notification.Name("tntAthleteDataLoaded"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntHomeViewController.observerProfileImageLoaded(notification:)), name: Notification.Name("tntProfileImageLoaded"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntHomeViewController.observerMeetLoaded(notification:)), name: Notification.Name("tntMeetLoaded"), object: nil)
        
        // if the meet list is empty, try to load standard data from cloud
        
        if tntLocalDataManager.shared.meets.count == 0 {
            tntSynchManager.shared.loadStandardData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        setAthleteFromUserDefaults()

        
        // Display athlete data if available, otherwise request it (and wait to be notified)
        if selectedAthlete != nil {
            
            displayAthleteData()
            displayProfileImage()
            displayMeetInfo()
            
        } else {
            print("TNT Home View Controller :  selected athelete is nil")
             // disable some buttons, allowing Edit/Select only
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
    
    func setAthleteFromUserDefaults() {
        
        let defaults = UserDefaults.standard
        if let athleteId = defaults.string(forKey: "tntSelectedAthleteId") {
            
            selectedAthlete = tntLocalDataManager.shared.getAthleteById(athleteId: athleteId)
            
        } else {
            // selected Athlete is not set in User Defaults, do nothing and wait
            return
        }
    }
    
    
    func displayAthleteData() {
        // Display the data for the current athlete 
        
        if let athlete = selectedAthlete {
            let firstName = athlete.firstName ?? ""
            let lastName =  athlete.lastName ?? ""
            tntName.text = firstName + " " + lastName
        
    
            // current level display
            
            let eventLevels = athlete.eventLevels as! [String: Int]?
            
            let levelTRint  = eventLevels?["TR"]
            let levelTUint  = eventLevels?["TU"]
            let levelDMTint = eventLevels?["DMT"]
            
            currentLevelTR.text =  levelTRint != nil ? "\(levelTRint!)" : "?"
            currentLevelTU.text = levelTUint != nil ? "\(levelTUint!)" : "?"
            currentLevelDMT.text = levelDMTint != nil ? "\(levelDMTint!)" : "?"
        }
    }
    
    func displayProfileImage() {
        // display an updated profile image
        
        if let imgData = selectedAthlete?.profileImage as Data? {
        
            let img = UIImage(data: imgData)
            self.profileImage.image = img
        } else {
            // display placeholder image
        }
        
        
    }
    
    func displayMeetInfo() {
        
        if #available(iOS 11.0, *) {
            meetMonth.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            // Fallback on earlier versions
        }
        selectedMeet = Meet.lastSelected()
               
        if let meet = selectedMeet {
            // format and display info about the next meet
            if let startDate = meet.startDate as Date? {
                let cal = Calendar.current
                meetMonth.text = cal.shortMonthSymbols[cal.component(.month, from: startDate) - 1]
                meetDay.text = "\(cal.component(.day, from: startDate))"
                meetYear.text = "\(cal.component(.year, from: startDate))"
            }
            let meetTitle = meet.title ?? ""
            let meetSubtitle = meet.subTitle ?? ""
            
            nextMeetInfo.text = "\(meetTitle) \n \(meetSubtitle)"
            
        } else {
            // no saved meet 
            nextMeetInfo.text = "No Meet Selected"
        }
        
    }
    
    // Mark : Segue processing
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destvc = segue.destination as? tntScoringViewController {
            
            // Set the meet and athlete on the scoring view controller
        
            destvc.athleteId = selectedAthlete?.id ?? ""
            destvc.meetId = selectedMeet?.id ?? ""
            return
            
        }
        
        if let destvc = segue.destination as? tntScoresTableViewController {
            
            // Set the meet and athlete on the scores table view controller
            
            destvc.athleteId = selectedAthlete?.id ?? ""
            destvc.meetId = selectedMeet?.id ?? ""
            return
            
        }
        
        if let destvc = segue.destination as? tntVideosTableViewController {
            
            destvc.athleteMO = selectedAthlete
            destvc.meetMO = self.selectedMeet
            
            return
        }
    }
    
    
    @IBAction func editAthlete(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "AthleteSetup", bundle: nil)
        let editAthleteVC = storyboard.instantiateViewController(withIdentifier: "tntEditAthleteVC") as! tntEditAthleteViewController
        editAthleteVC.athlete = selectedAthlete
        self.navigationController?.pushViewController(editAthleteVC, animated: true)
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
