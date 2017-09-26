//
//  tntEditAthleteViewController.swift
//  tnt
//
//  Created by Luke Everett on 9/24/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntEditAthleteViewController: UIViewController {
    
    // For editing an existing athlete, set the athlete on segue to this view
    // For a new athlete, the athlete should be nil and the new athlete will be saved to core data and set in user defaults
    
    var athlete: Athlete?
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var dobText: UITextField!
    @IBOutlet weak var dobPicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let existingAthlete = athlete {
            
            displayAthleteData()
            
        } else {
            
            displayDefaultData()
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
    
    func displayAthleteData() {
        
        if let existingAthlete = athlete {
            
            firstName.text = athlete?.firstName ?? ""
            lastName.text = athlete?.lastName   ?? ""
            //dobPicker.date = athlete?.dob
        }
        
        
    }
    
    func displayDefaultData() {
        
    }
    
    
    @IBAction func saveAthlete(_ sender: Any) {
        
        
    }

}
