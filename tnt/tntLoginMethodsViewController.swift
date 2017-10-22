//
//  tntLoginMethodsViewController.swift
//  tnt
//
//  Created by Luke Everett on 10/16/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class tntLoginMethodsViewController: UIViewController {
    
    var fbLoginManager = FBSDKLoginManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func FBLogin() {
        
        // TODO - should probably move this func to the login manager, allowing login from any VC
        
        // Note: don't try to make the fbLoginManager a local variable of this function, it should either be a property
        // of the VC invoking the login or a property of the LoginManager singleton
        
        fbLoginManager.logIn(withReadPermissions: ["public_profile"], from: self) {
            (result, error) -> Void in
                
                if (error != nil) {
                    DispatchQueue.main.async {
                        
                        let alert = UIAlertController(title: "Error logging in with FB", message: error!.localizedDescription, preferredStyle: .alert)
                        self.present(alert, animated: true, completion: nil)
                    }
                } else if result!.isCancelled {
                    
                    print("FB Login result was cancelled")
                    
                } else {
                    
                    // Now that we have the FBToken (in this thread), proceed to setup the Cognito Service
                    tntLoginManager.shared.CognitoLogin()
                    
                    // TODO: since we are logged in now, we should re-run anything that was skipped/failed in startup, e.g. loadCache
                    
                    DispatchQueue.main.async {
                        
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        appDelegate.setInitialVC()
                    }
                }
            }
        
    }
    
    
    // MARK: - Button Actions
    
    @IBAction func fbLoginTapped(_ sender: Any) {
        
        
        FBLogin()
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
