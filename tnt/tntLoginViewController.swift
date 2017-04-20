//
//  tntLoginViewController.swift
//  tnt
//
//  Created by Luke Everett on 4/13/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import UIKit
import UICKeyChainStore
import FBSDKLoginKit
import AWSCognito

class tntLoginViewController: UIViewController {
    
    var fbToken: FBSDKAccessToken?
    var credentialsProvider: AWSCognitoCredentialsProvider?
    var fbLoginManager: FBSDKLoginManager?
    
    
    @IBOutlet weak var btnDynamo: UIButton!
    
    override func viewDidLoad() {
        
        // Try to automatically login using FaceBook and AWS Cognito
        
        // 1. Check for the global FB Access Token
        
        self.fbToken = FBSDKAccessToken.current()
        if self.fbToken != nil {
            
            print("LoginView - found existing FB token")
            self.CognitoLogin()
            
        } else {
            // 2. No access token, so do a FB login
            
            if self.fbLoginManager == nil {
                self.fbLoginManager = FBSDKLoginManager()
                
                self.fbLoginManager?.logIn(withReadPermissions: ["public_profile"], from: self) {
                    (result, error) -> Void in
                    
                    if (error != nil) {
                        DispatchQueue.main.async {
                            
                            let alert = UIAlertController(title: "Error logging in with FB", message: error!.localizedDescription, preferredStyle: .alert)
                            self.presentingViewController?.present(alert, animated: true, completion: nil)
                        }
                    } else if result!.isCancelled {
                        //Do nothing
                        print("FB Login result was cancelled")
                    
                    } else {
                        // Now the current access token should be set on Facebook
                        self.fbToken = FBSDKAccessToken.current()
                        
                        // Now that we have the FBToken (in this thread), proceed to setup the Cognito Service
                        self.CognitoLogin()
                    }
                }
            }
        }
        
        super.viewDidLoad()

    }

    
    func CognitoLogin() {
     
        
        // assert(self.fbToken != nil)  also, this won't be on the main thread
        
        // print out some information about the Facebook Token and User Profile
        
        print("tnt: FBSDK Version \(FBSDKSettings.sdkVersion())")
        
        FBSDKProfile.loadCurrentProfile  { (profile, error) -> Void in
            // Completion handler for loadCurrentProfile
            if (error != nil) {
                    print("tnt:error in loadCurrentProfile")
                }
            else {
                let fbProfile = FBSDKProfile.current()
                print("tnt: FBSDK User Profile \(fbProfile!.name)")
            }
        }
    
        let fblogin = [Constants.FACEBOOK_PROVIDER : fbToken!.tokenString!]
        
        if self.credentialsProvider == nil {
            
            // Create an IdentityProviderManager to return the FB login info when requested
            
            let idpm = tntIdentityProvider(logins: fblogin)
            
            // Instantiate the Cognito credentials provider using region, pool and the logins
            
            self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.COGNITO_REGIONTYPE, identityPoolId: Constants.COGNITO_IDENTITY_POOL_ID, identityProviderManager: idpm)
            let configuration = AWSServiceConfiguration(region: Constants.COGNITO_REGIONTYPE, credentialsProvider: self.credentialsProvider)
            
            AWSServiceManager.default().defaultServiceConfiguration = configuration
            
            print("tnt: Logged in to AWS Cognito")
            print("tnt: \(configuration?.userAgent)")
            
            // could call getIdentityId here and print out in continuation block
            
            self.credentialsProvider?.getIdentityId().continueWith { task in
                
                print("tnt: Cognito Identity ID \(self.credentialsProvider?.identityId)")
                
            }
            
        } else {
            // we already have a credentials provider 
            // should probably call getIdentityId or something here
        }
        
        DispatchQueue.main.async {
            
            self.btnDynamo.isUserInteractionEnabled = true
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

}
