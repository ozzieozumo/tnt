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
    override func viewDidLoad() {
        super.viewDidLoad()

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
        
    }
    
    func saveMeet() {
        
        guard let title = meetTitle.text else {
            return
        }
        if meet == nil {
            // create a new managed object for the new meet
            meet = Meet(name: title)
        }
        guard let meet = meet else {
            print("TNT Edit Meet:  cannot save a nil meet")
            return
        }
        meet.startDate = meetStartDate.date as NSDate
        let endDate = Calendar.current.date(byAdding: .day,
                                             value: Int(meetDurationStepper.value),
                                             to: meetStartDate.date)
        meet.endDate = (endDate ?? meetStartDate.date) as NSDate
        meet.saveLocal()
        
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
}
