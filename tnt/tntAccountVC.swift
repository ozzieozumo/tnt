//
//  tntAccountVC.swift
//  tnt
//
//  Created by Luke Everett on 12/26/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntAccountVC: UIViewController {

    @IBOutlet var loginMethodLabel: UILabel!
    
    @IBOutlet var loggedInUserName: UITextField!
    
    @IBOutlet var loggedInEmail: UITextField!
    
    @IBOutlet var verifiedTeamName: UITextField!
    
    @IBOutlet var logOutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDisplay()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setDisplay() {
        
        loginMethodLabel.text = loginMethod()
        
        loggedInUserName.text = tntLoginManager.shared.loggedInUser
        
        loggedInEmail.text = tntLoginManager.shared.loggedInEmail
        
        verifiedTeamName.text = tntLoginManager.shared.currentTeam?.name ?? "Create or Join a Team"
        
        logOutButton.isEnabled = tntLoginManager.shared.loggedIn
        
    }
    
    func loginMethod() -> String {
        
        if tntLoginManager.shared.isLoggedInFB() {
            return "Logged in via Facebook"
        }
        if tntLoginManager.shared.isLoggedInUserPool() {
            return "Logged in via Email"
        }
        
        return "Not logged in"
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func logOutTapped(_ sender: Any) {
        
        tntLoginManager.shared.logout()
        
        // reset the view hierarchy
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.setInitialVC()
    }
    
}
