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

    @IBOutlet var loginFacebook: UIButton!
    @IBOutlet var loginUserPool: UIButton!
    @IBOutlet var logoutFacebook: UIButton!
    @IBOutlet var logoutUserPool: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setButtons()
        
        // if nobody is logged in (by any method), enable interactive login for the user pool
        
        if !tntLoginManager.shared.loggedIn {
            tntLoginManager.shared.enableInteractiveUserPoolLogin()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func FBLogin() {
        
        
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
                    tntLoginManager.shared.completeLoginWithFB(clearKeys: true) {
                    
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
        tntLoginManager.shared.setupUserPool()                    // reset the user pool
        tntLoginManager.shared.enableInteractiveUserPoolLogin()   // enable the interactive delegate
        let pool = tntLoginManager.shared.userPool!
        let user = pool.currentUser()
        
        user?.getDetails().continueWith { (task) -> AnyObject? in
            if let error = task.error as NSError? {
                print("TNT Login Methods VC, failed user.getDetails. Error: \(error)")
            } else {
                // User Pool Login is complete, setup credential provider and get federated ID
                
                tntLoginManager.shared.completeLoginWithUserPool(clearKeys: true) { (success: Bool) in
                    print("Login Methods VC: user pool login complete")
                    print("Federated Cognito ID is:  \(tntLoginManager.shared.cognitoId ?? "nil")")
           
                    DispatchQueue.main.async {
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        appDelegate.setInitialVC()
                    }
                }
            }
            return nil
        }
    }
    // MARK: - Button Actions
    
    func setButtons() {
        loginFacebook.isEnabled = !tntLoginManager.shared.loggedIn
        loginUserPool.isEnabled = !tntLoginManager.shared.loggedIn
        logoutFacebook.isEnabled = tntLoginManager.shared.isLoggedInFB()
        logoutUserPool.isEnabled = tntLoginManager.shared.isLoggedInUserPool()
    }
    
    @IBAction func fbLoginTapped(_ sender: Any) {
        
        FBLogin()
    }
    
    
    @IBAction func fbLogoutTapped(_ sender: Any) {
        
        if tntLoginManager.shared.isLoggedInFB() {
            tntLoginManager.shared.fbLogout()
            tntLocalDataManager.shared.clearTNTObjects()
            setButtons()
        }
    }
    
    
    @IBAction func userPoolLoginTapped(_ sender: Any) {
        
        userPoolLogin()
    }
    
    
    @IBAction func userPoolLogoutTapped(_ sender: Any) {
        
        if tntLoginManager.shared.isLoggedInUserPool() {
            tntLoginManager.shared.userPoolLogout()
            tntLocalDataManager.shared.clearTNTObjects()
            setButtons()
        }
        
    }
   
}
