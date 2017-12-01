//
//  tntEditTeamVC.swift
//  tnt
//
//  Created by Luke Everett on 11/30/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntEditTeamVC: UIViewController {

    var team: Team? = nil
    
    @IBOutlet var teamName: UITextField!
    @IBOutlet var teamSecret: UITextField!
    
    @IBOutlet var randomButton: UIButton!
    @IBOutlet var joinButton: UIButton!
    @IBOutlet var createButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        teamName.delegate = self
        teamSecret.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setButtons()
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
    
    func createTeam(name: String, secret: String, completion: @escaping (Error?, Team?) -> Void) {
        
        tntTeam.checkNameAvailable(name) { (available: Bool) in
            if available {
                // proceed with object creation
                
            } else {
                // TODO : use enum for error codes in constants/globals
                let error = NSError(domain: "TNT", code: 1, userInfo: ["message": "team name unavailable"])
                completion(error, nil)
            }
        }
    }
    
    // MARK: - Button Actions
    func setButtons() {
        
        
        
        let allButtons = [randomButton, joinButton, createButton]
        let actionButtons = [joinButton, createButton]
        
        // once a team has been joined or created, all buttons are disabled
        if team != nil {
            allButtons.forEach() { $0?.isEnabled = false }
            return
        }
        
        // otherwise, enable the action buttons only if both fields have been entered
        
        let nameEmpty = teamName.text?.isEmpty ?? true
        let secretEmpty = teamSecret.text?.isEmpty ?? true
        
        actionButtons.forEach() { $0?.isEnabled = !nameEmpty && !secretEmpty }
        
    }
    
    func disableButtons() {
        let allButtons = [randomButton, joinButton, createButton]
        allButtons.forEach() { $0?.isEnabled = false }
    }
    
    @IBAction func randomTapped(_ sender: UIButton) {
    }
    
    
    @IBAction func joinTapped(_ sender: UIButton) {
    }
    
    
    @IBAction func createTapped(_ sender: UIButton) {
        
        disableButtons()
        
        createTeam(name: teamName.text!, secret: teamSecret.text!) { (error, result) in
            
        }
        
        // show button to segue to add athletes
        
    }
    
    
}

extension tntEditTeamVC: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        setButtons()
    }
}
