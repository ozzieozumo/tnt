//
//  tntLoginManager.swift
//  tnt
//  
//  For setting up the login context using Facebook and Amazon Cognito
//
//  Created by Luke Everett on 5/11/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

/* The tntLoginManager singleton is responsible for coordinating the various login options
   and maintaining information about the current loggein in user.
   The application uses AWS Cognito Federated Identity Pools to permit logging in via different methods,
   including Facebook, email (via AWS Cognito User Pool) and possibly others in the future.
   The TNT application doesn't permit merging login methods -- that is if you login once via Facebook
   and again via email you wil receive two different Cognito Identities, effectively two accounts.
 
 */

import Foundation
import FBSDKCoreKit
import FBSDKLoginKit
import AWSCognito
import AWSCognitoIdentityProvider

class tntLoginManager {
    
    static let shared = tntLoginManager()
    
    // Login Providers / Methods (could use actual provider strings instead? )
    let LASTLOGIN_KEY = "tntLastLoginMethod"
    let LOGIN_FB = "Facebook"
    let LOGIN_EMAIL = "AWS User Pool"
    
    // Facebook
    
    var fbToken: FBSDKAccessToken?
    
    // Cognito (Federated Identity Pool)
    
    var cognitoId: String?
    var credentialsProvider: AWSCognitoCredentialsProvider?
    
    // Cognito (User Pool)
    var userPool: AWSCognitoIdentityUserPool? = nil
    
    
    private init() {
        
        fbToken = nil
        cognitoId = nil
        credentialsProvider = nil
        
    }
    
    var loggedIn: Bool {
        return isLoggedInFB() || isLoggedInUserPool()
    }
    
    func attemptSilentLogin() {
        
        // Try to automatically login using the last known login method
        
        let defaults = UserDefaults.standard
        let lastLoginMethod = defaults.string(forKey: LASTLOGIN_KEY) ?? "UNRECOGNIZED"
        switch lastLoginMethod {
                case LOGIN_FB: resumeFBLogin()
                case LOGIN_EMAIL: resumeUserPoolLogin ()
                default: print("TNT Login Manager: unrecognized last login method (probably first time use)")
        }
        
        
        // after attempting silent login, enable interactive login for user pools
        
        enableInteractiveUserPoolLogin()
        
        // if not resuming a prior user pools session, clear out keychain for the user pool (just in case)
        if lastLoginMethod != LOGIN_EMAIL {
            userPool?.clearAll()
        }
        
    }
    // MARK: Facebook
    
    func isLoggedInFB() -> Bool {
        return (fbToken != nil) && (cognitoId != nil)
    }
    
    func fbLogout() {
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logOut()
        cognitoId = nil
    }
    
    func resumeFBLogin() {
        // 1. Check for the global FB Access Token
        
        self.fbToken = FBSDKAccessToken.current()
        if self.fbToken != nil {
            // TODO:  check expiration date of token?  (FB tokens are long lived, but still ... )
            print("tntLogin Manager - attempting silent login with FB token")
            self.completeLoginWithFB(handler: nil)
            
        } else {
            // 2. No access token, so just leave fbToken as nil (wait for interactive login)
            print("tntLogin Manager - FB token missing or expired during silent login attempt")
            return
        }
    }
    
    func completeLoginWithFB(handler: (()-> Void)? ) {
        
        // Make sure the FB token is set before proceeding
        
        self.fbToken = FBSDKAccessToken.current()
        
        if self.fbToken == nil {
            print("tntLogin Manager - attempted Cognito Login with no FB token set")
            return
        }
        
        // print out some information about the Facebook Token and User Profile
        
        print("tnt: FBSDK Version \(FBSDKSettings.sdkVersion())")
        
        FBSDKProfile.loadCurrentProfile  { (profile, error) -> Void in
            // Completion handler for loadCurrentProfile
            if (error != nil) {
                print("tntLoginManager: error loading current Facebook profile")
            }
            else {
                let fbProfile = FBSDKProfile.current()
                print("tnt: FBSDK User Profile \(fbProfile!.name)")
            }
        }
        
        let fblogin = [Constants.FACEBOOK_PROVIDER : fbToken!.tokenString!]
            
        // Create an IdentityProviderManager to return the FB login info when requested
        
        let idpm = tntIdentityProvider(logins: fblogin)
        
        // Instantiate the Cognito credentials provider using region, pool and the FB provider/token pair
        
        self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.COGNITO_REGIONTYPE, identityPoolId: Constants.COGNITO_IDENTITY_POOL_ID, identityProviderManager: idpm)
        let configuration = AWSServiceConfiguration(region: Constants.COGNITO_REGIONTYPE, credentialsProvider: self.credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        print("tntLoginManager:  service manager initialized")
        print("tntLoginManager (AWS user agent info): \(configuration?.userAgent ?? "Default")")
        
        // call getIdentityId here and print out in continuation block
        
        self.credentialsProvider?.getIdentityId().continueWith { task in
            
            self.cognitoId  = self.credentialsProvider?.identityId
            let defaults = UserDefaults.standard
            defaults.set(self.LOGIN_FB, forKey: self.LASTLOGIN_KEY )
            
            print("tntLoginManager: setting Cognito ID via FBlogin \(self.cognitoId ?? "Default")")
            
            handler?()
            
            return nil
        }
    }
    
    // MARK: User Pool
    
    func isLoggedInUserPool() -> Bool {
        let user = userPool?.currentUser()
        let loggedInPool = user?.isSignedIn ?? false
        return (loggedInPool) && (cognitoId != nil)
    }
    
    func userPoolLogout() {
        userPool?.clearAll()
        cognitoId = nil
    }
    
    func setupUserPool() {
        // Abort if configuration not updated
        if (Constants.CognitoIdentityUserPoolId == "YOUR_USER_POOL_ID") {
            fatalError("TNT Login Manager - cognito pool constants not set to default AWS sample program values. aborting. ")
        }
        
        // setup logging
        // AWSLogger.default().logLevel = .verbose
        
        let configuration = AWSServiceConfiguration(region: Constants.COGNITO_REGIONTYPE, credentialsProvider: nil)
        
        // create pool configuration
        let poolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: Constants.CognitoIdentityUserPoolAppClientId,
                                                                        clientSecret: Constants.CognitoIdentityUserPoolAppClientSecret,
                                                                        poolId: Constants.CognitoIdentityUserPoolId)
        
        // initialize user pool client
        AWSCognitoIdentityUserPool.register(with: configuration, userPoolConfiguration: poolConfiguration, forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        
        // fetch the user pool client we initialized in above step
        // LDE: I beieve this step will reconstruct the pool from the keychain, incuding any unexpired logins (if the user had successfully signed into the pool before)
        let pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        
        self.userPool = pool
        
    }
    
    func resumeUserPoolLogin() {
        // This function is called once during the silent login phase of startup
        // Note that user pool refresh tokens last for 30 days by default and session resumption should be possible in that window
        
        // init the user pool if necessary
        
        setupUserPool()
        
        // check for logged in state in the user pool
        
        if let user = userPool?.currentUser() {
        
            if user.isSignedIn {
                completeLoginWithUserPool() {
                    // should do something here .. more chaining
                }
            } else {
                print("tntLogin Manager - cannot resume user pool session. (probably expired token)")
                return
            }
        } else {
               print("tntLogin Manager - cannot resume.  pool has no current user")
        }
        
    }
    
    func enableInteractiveUserPoolLogin() {
        
        // setup the user pool if necessary
        if userPool == nil {
            setupUserPool()
        }
        
        // if its not seat already, set the delegate to allow interactive UI authentication
        
        if userPool?.delegate == nil {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            userPool?.delegate = appDelegate
        }
    }
    
    func printPoolInfo() {
        if let pool = self.userPool {
            print("TNT Login Manager: pool is not nil")
            
            if let user = pool.currentUser() {
                print("pool has a current user \(user.username ?? "name is nil")")
            } else {
                print("pool had a nil current user")
            }
            pool.logins().continueOnSuccessWith {
                (task) in
                
                if let loginsDict = task.result {
                    print("TNT Login Manager: user pool has \(loginsDict.count) logins")
                }
                return nil
            }
        } else {
            print("Pool was nil on Login Manager")
        }
    }
    
    func completeLoginWithUserPool(success: @escaping ()->Void) {
    // convert a logged in user pool into a credential for use with AWS services
    // this should be called on successful completion of getDetails()
        
        let pool = self.userPool
        
        printPoolInfo()
        
        self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.COGNITO_REGIONTYPE, identityPoolId: Constants.COGNITO_IDENTITY_POOL_ID, identityProviderManager: pool)
                    
        let configuration = AWSServiceConfiguration(region: Constants.COGNITO_REGIONTYPE, credentialsProvider: self.credentialsProvider)
                    
        AWSServiceManager.default().defaultServiceConfiguration = configuration
                    
        print("tntLoginManager:  service manager initialized")
        print("tntLoginManager (AWS user agent info): \(configuration?.userAgent ?? "Default")")
        
        self.credentialsProvider?.getIdentityId().continueWith { task in
            
                 if let error = task.error as NSError? {
                     print("TNT Login Manager, failed getting IdentityId for User Pool login. Error: \(error)")
                 } else {
                     self.cognitoId  = self.credentialsProvider?.identityId
                     print("tntLoginManager: setting Cognito ID via user pool \(self.cognitoId ?? "Default")")
                    
                     let defaults = UserDefaults.standard
                     defaults.set(self.LOGIN_EMAIL, forKey: self.LASTLOGIN_KEY )
                     success()
                 }
                 return nil
         }
    }
    
}


