//
//  tntEditTeamVC.swift
//  tnt
//
//  Created by Luke Everett on 11/30/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit
import MessageUI

class tntEditTeamVC: UIViewController {

    var team: Team? = nil
    
    @IBOutlet var teamName: UITextField!
    @IBOutlet var teamSecret: UITextField!
    
    @IBOutlet var randomButton: UIButton!
    @IBOutlet var joinButton: UIButton!
    @IBOutlet var createButton: UIButton!
    
    var mailForm: MFMailComposeViewController? = nil
    
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
                print("TNT Team Setup VC : requested team name is available")
                
                let teamMO = Team(name: name, secret: secret)
                teamMO.saveLocal()
                
                self.team = teamMO
                
                DispatchQueue.main.async {
                    self.setButtons()
                    // self.showAddAthletes()
                }
                
                
                let teamDB = tntTeam(teamMO: teamMO)
                teamDB.saveToCloud()  // async, assumed to succeed (TODO)
                
                completion(nil, teamMO)
                
            } else {
                // TODO : use enum for error codes in constants/globals
                // Maybe send a notification instead??
                let error = NSError(domain: "TNT", code: 1, userInfo: ["message": "team name unavailable"])
                completion(error, nil)
            }
        }
    }
    
    func randomSecret(len: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for _ in 1...len{
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        
        return randomString as String
    }
    
    func showPostCreateMailForm(team: Team) {
        mailForm = MFMailComposeViewController()
        
        if let mailForm = mailForm {
            mailForm.mailComposeDelegate = nil
            mailForm.setSubject("details for our new team in the TNT tracker app")
            mailForm.setMessageBody("the team name and team secret go here", isHTML: true)
        
            present(mailForm, animated: true, completion: nil)
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
        
        teamSecret.text = randomSecret(len: 8)
        setButtons()
    }
    
    
    @IBAction func joinTapped(_ sender: UIButton) {
    }
    
    
    @IBAction func createTapped(_ sender: UIButton) {
        
        disableButtons()
        
        createTeam(name: teamName.text!, secret: teamSecret.text!) { (error, result) in
        
            if error == nil {
                // show a mail compose form to mail the team name and secret
                
                if let createdTeam = result {
                    DispatchQueue.main.async {
                        self.showPostCreateMailForm(team: createdTeam)
                    }
                }
            }
        }
        
        // show button to segue to add athletes
        
    }
    
    
}

extension tntEditTeamVC: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        setButtons()
    }
}
