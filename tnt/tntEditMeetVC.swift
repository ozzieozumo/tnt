//
//  tntEditMeetVC.swift
//  tnt
//
//  Created by Luke Everett on 12/26/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntEditMeetVC: UIViewController {

    var meet: Meet?
    
    @IBOutlet var meetTitle: UITextField!
    @IBOutlet var meetStartDate: UIDatePicker!
    @IBOutlet var meetDuration: UITextField!
    @IBOutlet var saveBtn: UIBarButtonItem!
    @IBOutlet var meetDurationStepper: UIStepper!
    @IBOutlet var sharedSwitch: UISwitch!
    @IBOutlet var shareWithLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayValues()
        setButtons()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setButtons() {
        
        // Save Button
        // saveBtn.isEnabled = !(meetTitle.text ?? "").isEmpty
        saveBtn.isEnabled = true
        //TODO: check other required fields
        
        // check current team membership and set controls
        
        if let team = tntLoginManager.shared.currentTeam {
            sharedSwitch.isEnabled = true
            shareWithLabel.text = "Share with \(team.name ?? "Unnamed Team")"
        } else {
            sharedSwitch.isEnabled = false
            shareWithLabel.text = "(No Team)"
        }
        
    }
    
    func displayValues() {
        
        if let meet = self.meet {
            meetTitle.text = meet.title
            meetStartDate.date = (meet.startDate as Date?) ?? Date()
            // TODO: date arithmetic for meet duration
            meetDurationStepper.value = 2.0
            sharedSwitch.isOn = meet.sharedStatus
            
        } else {
            displayInitialValues()
        }
        
        
    }
    
    func displayInitialValues() {
        meetTitle.text = ""
        meetStartDate.date = Date()
        meetDurationStepper.value = 2.0
        sharedSwitch.isOn = tntLoginManager.shared.currentTeam != nil
        
    }
    
    func saveMeet() {
        
        if meet == nil {
            // create a new managed object for the new meet
            let newTitle = meetTitle.text ?? "Untitled"
            meet = Meet(name: newTitle)
        }
        guard let meet = meet else {
            print("TNT Edit Meet:  cannot save a nil meet")
            return
        }
        meet.title = meetTitle.text ?? "Untitled"
        meet.startDate = meetStartDate.date as NSDate
        let endDate = Calendar.current.date(byAdding: .day,
                                             value: Int(meetDurationStepper.value),
                                             to: meetStartDate.date)
        meet.endDate = (endDate ?? meetStartDate.date) as NSDate
        meet.sharedStatus = sharedSwitch.isOn
        meet.sharedTeam = tntLoginManager.shared.currentTeam?.teamId
        
        meet.saveLocal()
        
        let meetDB = tntMeet(meetMO: meet)
        meetDB.saveToCloud()
        
        self.navigationController?.popViewController(animated: true)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        saveMeet()
    }
    
    @IBAction func meetDurationChanged(_ sender: Any) {
        
        meetDuration.text = String(Int(meetDurationStepper.value))
    }
    
    @IBAction func shareStatusChanged(_ sender: Any) {
    
        // private --> shared : check for duplicate meet by name & date
        
        // shared --> private : disallow if saved data exists for other users
    }
    
}
