//
//  tntEditEventHeaderVC.swift
//  tnt
//
//  Created by Luke Everett on 11/7/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntEditEventHeaderVC: UIViewController {
    
    var eventHeader: tntScoreItem? = nil
    
    @IBOutlet var eventNameLabel: UILabel!
    @IBOutlet var currentLevelInfoLabel: UILabel!
    @IBOutlet var levelStepper: UIStepper!
    @IBOutlet var eventLevelLabel: UILabel!
    @IBOutlet var podiumStepper: UIStepper!
    @IBOutlet var medalImage: UIImageView!
    @IBOutlet var qualifyingSwitch: UISwitch!
    @IBOutlet var qualifyingImage: UIImageView!
    @IBOutlet var mobilizingSwitch: UISwitch!
    @IBOutlet var mobilizingImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureControls()
        setupEditor()
        updateDisplay()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        // copy values back to the header item
        
        eventHeader?.level = Int(levelStepper.value)
        let podiumPosition = Int(podiumStepper.value)
        
        eventHeader?.medal = tntScoreItem.medalKeys[podiumPosition]
        
        eventHeader?.qualified = qualifyingSwitch.isOn
        eventHeader?.mobilized = mobilizingSwitch.isOn
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureControls() {
        
        podiumStepper.minimumValue = 0
        podiumStepper.maximumValue = Double(tntScoreItem.medalKeys.count - 1)
        

    }
    
    func setupEditor() {
        
        guard let eventHeader = self.eventHeader else {
            print("tntEditEventHeaderVC - event header is nil")
            return
        }
        
        let athleteLevel = 6  // need to get from athlete
        eventNameLabel.text = tntScoreItem.eventNames[eventHeader.event]
        currentLevelInfoLabel.text = "Your current level for this event is \(athleteLevel)"
        
        levelStepper.value = Double(eventHeader.level)
        podiumStepper.value = Double(tntScoreItem.medalKeys.index(of: eventHeader.medal ?? "other") ?? 0)
        qualifyingSwitch.isOn = eventHeader.qualified
        mobilizingSwitch.isOn = eventHeader.mobilized
        
    }
    
    func updateDisplay() {
        
       eventLevelLabel.text = String(Int(levelStepper.value))
       
       let medalKey = tntScoreItem.medalKeys[Int(podiumStepper.value)]
       medalImage.image = tntScoreItem.medalInfo[medalKey]?.image
       qualifyingImage.image = qualifyingSwitch.isOn ? #imageLiteral(resourceName: "nationalqualify") : nil
       mobilizingImage.image = mobilizingSwitch.isOn ? #imageLiteral(resourceName: "levelup") : nil
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func levelStepperChanged(_ sender: Any) {
        
        updateDisplay()
        
    }
    
    @IBAction func podiumStepperChanged(_ sender: Any) {
        
        updateDisplay()
    }
    
    @IBAction func qualifyingSwitchChanged(_ sender: Any) {
        
        updateDisplay()
        
    }
    
    @IBAction func mobilizingSwitchChanged(_ sender: Any) {
        
         updateDisplay()
    }
    
    
}
