//
//  tntLoginMethodsViewController.swift
//  tnt
//
//  Created by Luke Everett on 10/16/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import AWSCognitoIdentityProvider

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
                    tntLoginManager.shared.completeLoginWithFB {
                    
                        // TODO: since we are logged in now, we should re-run anything that was skipped/failed in startup, e.g. loadCache
                        
                        DispatchQueue.main.async {
                            
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            appDelegate.setInitialVC()
                        }
                    }
                }
            }
        
    }
    
    func userPoolLogin() {
        
        /* From this function we just call getDetails.
        If there is no user logged in, the pool will contact its UI delegate to show a login screen
         On success we should set the logged in information in the login singleton
         Any failures should be caught on the signIn screen and handled via alerts
         If the user cancels, we should return to the login methods screen.
 
         */
        
        let pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        let user = pool.currentUser()
        
        user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            if let error = task.error as NSError? {
                print("TNT Login Methods VC, failed user.getDetails. Error: \(error)")
            } else {
                // theoretically, we should should be logged in with a Cognito ID now
                DispatchQueue.main.async {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.setInitialVC()
                }
            }
            return nil
        }
        
        
    }
    // MARK: - Button Actions
    
    @IBAction func fbLoginTapped(_ sender: Any) {
        
        
        FBLogin()
        
    }
    
    
    @IBAction func userPoolLoginTapped(_ sender: Any) {
        
        userPoolLogin()
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
