//
//  tntEditAthleteViewController.swift
//  tnt
//
//  Created by Luke Everett on 9/24/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit
import CoreData

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
            }
            firstName.text = existingAthlete.firstName ?? ""
            lastName.text = existingAthlete.lastName   ?? ""
            dobPicker.date = (existingAthlete.dob as Date?) ?? defaultDate
        } else {
            displayDefaultData()
        }
    }
    
    func displayDefaultData() {
        
    }
    
    
    @IBAction func saveAthlete(_ sender: Any) {
    
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
        
        }
        
        athleteToSave.firstName = firstName.text
        athleteToSave.lastName = lastName.text
        athleteToSave.dob = dobPicker.date as NSDate
        
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
            
        }
        
    }
    
    

}
