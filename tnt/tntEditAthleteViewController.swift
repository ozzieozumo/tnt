//
//  tntEditAthleteViewController.swift
//  tnt
//
//  Created by Luke Everett on 9/24/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit
import CoreData
import Photos
import MobileCoreServices
import AWSS3
import AVKit
import AVFoundation

class tntEditAthleteViewController: UIViewController {
    
    // For editing an existing athlete, set the athlete on segue to this view
    // For a new athlete, the athlete should be nil and the new athlete will be saved to core data and set in user defaults
    
    var athlete: Athlete?
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var dobPicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayAthleteData()
        
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
    
    func displayAthleteData() {
        
        if let existingAthlete = athlete {
            
            let defaultDate = Date()
            
            if let imgData = existingAthlete.profileImage as Data? {
                
                let img = UIImage(data: imgData)
                profileImage.image = img
            } else {
                // image data not in core data, try to get it from URL
                
            }
            firstName.text = existingAthlete.firstName ?? ""
            lastName.text = existingAthlete.lastName   ?? ""
            dobPicker.date = (existingAthlete.dob as Date?) ?? defaultDate
        } else {
            displayDefaultData()
        }
    }
    
    func displayDefaultData() {
        
        // show the placeholder for the user profile image
        
        profileImage.image = #imageLiteral(resourceName: "default_profile")
        
    }
    
    
    @IBAction func saveAthlete(_ sender: Any) {
        
        /* TODO:  the save action on an existing athlete should pop the view controller (probably returing to the home view
            on a new athlete, the save action should open the home view for the new athlete
         */
    
        var athleteToSave: Athlete
        
        let localMOC = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        localMOC.parent = tntLocalDataManager.shared.moc!
        
        if let existingAthlete = athlete {
            
            // instantiate on the new context using objectID to pass a reference (necessary for thread safety)
            athleteToSave = localMOC.object(with: existingAthlete.objectID) as! Athlete
            
        } else {
            
            // make a new Athlete MO, preferably using a child context (TODO)
            
            athleteToSave = Athlete(context: localMOC)
            athleteToSave.id = UUID().uuidString
            if let cognitoId = tntLoginManager.shared.cognitoId {
                athleteToSave.cognitoId = cognitoId
            } else {
                // Log an error and return; something pretty weird must have happened
                print("TNT Save Athlete: no CognitoId available when trying to save athlete. Save canceled")
                return
            }
        
        }
        
        athleteToSave.firstName = firstName.text
        athleteToSave.lastName = lastName.text
        athleteToSave.dob = dobPicker.date as NSDate
        
        if isNameLocalDuplicate(athlete: athleteToSave) {
            
            // show alert and return
            let alertC = UIAlertController(title: "Duplicate Name", message: "Name is already taken.", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertC.addAction(defaultAction)
            self.present(alertC, animated: true, completion: nil)
            return
        }
        
        do {
            
            // push the changes up to the main context (i.e. the moc of LocalDataManager)
            try localMOC.save()
            print("TNT Edit Athlete VC saved athlete to child context with id \(athleteToSave.id!)")
        }
        catch let error as NSError {
            print("TNT Edit Athlete VC: error saving to local context \(error)")
            return
            // on error, discard the changes by releasing the localMOC
        }
        
        do {
            
            // save any changes to the persistent store
            
            try tntLocalDataManager.shared.moc!.save()
            
        } catch {
            fatalError("TNT Edit AthleteVC : Failure to save main context \(error)")
        }
        
        if athlete == nil {
            
            // Now that we have saved new object on the parent, we need to find it in that context
            // (there's no point saving the object that was created in the local/child context)
            
            let newObjectId = athleteToSave.objectID
            let newAthlete = tntLocalDataManager.shared.moc!.object(with: newObjectId) as! Athlete
            
            // This object, associated with the parent context, can be inserted into the LocalDataManager
            
            tntLocalDataManager.shared.athletes[newAthlete.id!] = newAthlete
            tntSynchManager.shared.saveAthlete(athleteId: newAthlete.id!)
            
            let defaults = UserDefaults.standard
            defaults.setValue(newAthlete.id!, forKey: "tntSelectedAthleteId")
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.setInitialVC()
        }
        
    }
    
    func isNameLocalDuplicate(athlete: Athlete) -> Bool {
        
        // Check whether an athlete with the same first and last name is already saved locally in Core Data
        
        let athleteName = (athlete.lastName ?? "") + (athlete.firstName ?? "")
        
        let existingNames = tntLocalDataManager.shared.athletes.map { (key:String, value: Athlete) -> String in
            return (value.lastName ?? "") + (value.firstName ?? "")
        }
        
        return existingNames.contains(athleteName)
        
    }
    
    func showProfilePicker()  {
        
        let uipc = UIImagePickerController()
        uipc.delegate = self
        
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alertMessageOk(title: "Error", message: "The Photo Library is not available")
        }
        
        uipc.sourceType = .photoLibrary
        
        let mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)
        
        if !(mediaTypes?.contains(kUTTypeMovie as String))! {
            alertMessageOk(title: "Error", message: "Movie media type is not supported")
        }
        uipc.mediaTypes = [kUTTypeImage as String]
        uipc.modalPresentationStyle = .overCurrentContext
        
        self.present(uipc, animated: true, completion: nil)
        
    }
    
    @IBAction func profileImageTapped(_ sender: Any) {
        
        print("Profile Image was tapped")
        
        //immediately turn of user interaction so that we don't get multiple taps
        
        profileImage.isUserInteractionEnabled = false
        
        showProfilePicker()
        
    }
    

}

extension tntEditAthleteViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        var preferredImage: UIImage?
        
        let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage
        let originalImage  = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        preferredImage = (editedImage != nil) ? editedImage : originalImage
        
        if preferredImage != nil {
            profileImage.image = preferredImage
            profileImage.isUserInteractionEnabled = true
            
        } else {
            print("TNT: profile image picker coujld not determine chosen image")
        }
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        // don't change the displayed profile image, just dismiss the picker
        
        picker.dismiss(animated: true, completion: nil)
    }
}
