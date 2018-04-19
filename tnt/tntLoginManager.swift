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
    
    let resumeTimeoutSeconds = 3
    
    // Login Providers / Methods (could use actual provider strings instead? )
    let LASTLOGIN_KEY = "tntLastLoginMethod"
    let LOGIN_FB = "Facebook"
    let LOGIN_EMAIL = "AWS User Pool"
    
    // Facebook
    
    var fbToken: FBSDKAccessToken?
    var fbProfile: FBSDKProfile?
    var fbEmail: String?
    
    // Cognito (Federated Identity Pool)
    
    var cognitoId: String?
    var credentialsProvider: AWSCognitoCredentialsProvider?
    
    // Cognito (User Pool)
    var userPool: AWSCognitoIdentityUserPool? = nil
    var userPoolDefaultDelegate: AWSCognitoIdentityInteractiveAuthenticationDelegate? = nil;  // save this after pool creation but before assigning our delegate
    var userDetailAttributes: [String: String] = [:]  // user detail attributes such as email
    
    //  Teams
    
    var currentTeam: Team? = nil
    
    private init() {
        
        fbToken = nil
        fbProfile = nil
        fbEmail = nil
        cognitoId = nil
        credentialsProvider = nil
        
    }
    
    var loggedIn: Bool {
        return isLoggedInFB() || isLoggedInUserPool()
    }
    
    var loggedInUser: String? {
        guard self.loggedIn else {return nil}
        
        if isLoggedInUserPool() {
            return userPool?.currentUser()?.username
        }
        
        if isLoggedInFB() {
            let lastName = fbProfile?.lastName ?? ""
            let firstName = fbProfile?.firstName ?? ""
            if firstName + lastName == "" {
                return "Profile Name Unavailable"
            } else {
                return "\(firstName) \(lastName)"
            }
        }
        return "Unknown Login Method"
    }
    
    var loggedInEmail: String? {
        guard self.loggedIn else {return nil}
        
        if isLoggedInUserPool() {
            // will need to save getDetails result after each successful login, similar to saving FB profile
            return "User Pool Email"
        }
        
        if isLoggedInFB() {
            // if let fbEmail = fbProfile?.
            return self.fbEmail ?? "FB Email Unavailable"
        }
        return "Unknown Login Method"
        
    }
    
    func logout() {
        guard loggedIn else {return}
        
        if isLoggedInFB() {
            fbLogout()
        }
        if isLoggedInUserPool() {
            userPoolLogout()
        }
        
        //TODO : decide whether core data should be cleared on logout
        //       app should be usable when not connected to internet
        //       provided meets & athletes have been setup in advance.
        //       need to clarify this in UI.
        
        tntLocalDataManager.shared.clearTNTObjects()
    }
    func attemptSilentLogin() {
        
        // Try to automatically login using the last known login method
        
        print("TNT Login Manager - starting silent login")
        let defaults = UserDefaults.standard
        let lastLoginMethod = defaults.string(forKey: LASTLOGIN_KEY) ?? "UNRECOGNIZED"
        
        switch lastLoginMethod {
            case LOGIN_FB: resumeFBLogin()
            case LOGIN_EMAIL: resumeUserPoolLogin()
            
            default: print("TNT Login Manager: unrecognized last login method (treat as first time use)")
        }
        
        print("TNT Login Manager - done with silent login")
    }
    
    // MARK: Facebook
    
    func isLoggedInFB() -> Bool {
        return (fbToken != nil) && (cognitoId != nil)
    }
    
    func fbLogout() {
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logOut()
        cognitoId = nil
        currentTeam = nil
    }
    
    func resumeFBLogin() {
        // 1. Check for the global FB Access Token
        
        self.fbToken = FBSDKAccessToken.current()
        if self.fbToken != nil {
            // TODO:  check expiration date of token?  (FB tokens are long lived, but still ... )
            print("tntLogin Manager - attempting silent login with FB token")
            
            let waitGroup = DispatchGroup()
            waitGroup.enter()
            self.completeLoginWithFB(clearKeys: false) {
                waitGroup.leave()
            }
            let waitResult = waitGroup.wait(timeout: DispatchTime.now() + .seconds(resumeTimeoutSeconds))
            if waitResult == .timedOut {
                print("TNT Login Manager - timed out waiting to complete FB login")
            }
            
        } else {
            // 2. No access token, so just leave fbToken as nil (wait for interactive login)
            print("tntLogin Manager - FB token missing or expired during silent login attempt")
            return
        }
    }
    
    func completeLoginWithFB(clearKeys: Bool, handler: (()-> Void)? ) {
        
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
                // save the profile object
                
                self.fbProfile = FBSDKProfile.current()
                
                // do a graph request to get the email
                
                let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"id,email"])
                graphRequest.start(completionHandler: { (connection, result, error) -> Void in
                    
                    if error != nil {
                        print("Error retrieving Facebook email: \(String(describing: error))")
                        return
                    }
                    if let result = result as! [String: Any]?  {
                        self.fbEmail = (result["email"] as! String?)
                    }
                })
                
            }
        }
        
        let fblogin = [Constants.FACEBOOK_PROVIDER : fbToken!.tokenString!]
            
        // Create an IdentityProviderManager to return the FB login info when requested
        
        let idpm = tntIdentityProvider(logins: fblogin)
        
        // Instantiate the Cognito credentials provider using region, pool and the FB provider/token pair
        
        self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.COGNITO_REGIONTYPE, identityPoolId: Constants.COGNITO_IDENTITY_POOL_ID, identityProviderManager: idpm)
        
        if clearKeys {
            
            credentialsProvider?.clearKeychain()
            assert(credentialsProvider?.identityId == nil)
        }
        let configuration = AWSServiceConfiguration(region: Constants.COGNITO_REGIONTYPE, credentialsProvider: self.credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        print("tntLoginManager:  service manager initialized")
        print("tntLoginManager (AWS user agent info): \(configuration?.userAgent ?? "Default")")
        print("tntLoginManager: credentials provider has \(self.credentialsProvider?.identityId ?? "nil") for federated id")
        
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
        currentTeam = nil
        disableInteractiveUserPoolLogin()  

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
        
        // register this pool configuration
        AWSCognitoIdentityUserPool.register(with: configuration, userPoolConfiguration: poolConfiguration, forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        
        // fetch a default user pool based on the configuration registered in the previous step
        // LDE: I beieve this step will reconstruct the pool from the keychain, incuding any unexpired logins (if the user had successfully signed into the pool before)
        let pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        
        self.userPool = pool
        
        // save the default delegate but do not turn on interactive authentication yet
        self.userPoolDefaultDelegate = pool.delegate
        
        printPoolInfo()
        
    }
    
    func resumeUserPoolLogin() {
        // This function is called once during the silent login phase of startup
        // Note that user pool refresh tokens last for 30 days by default and session resumption should be possible in that window
        
        // init the user pool if necessary
        
        setupUserPool()
        
        // check for logged in state in the user pool
        // note that the completion handler is always called, whether for success or failure
        // TODO: consider using the AWSTask structure for this function
        
        if let user = userPool?.currentUser() {
        
            if user.isSignedIn {
                let waitGroup = DispatchGroup ()
                waitGroup.enter()
                completeLoginWithUserPool(clearKeys: false) { (success: Bool) in
                    print("TNT Login Manager: resumed from user pool login and completed Cognito login")
                    self.enableInteractiveUserPoolLogin()  // delegate must be set to allow token refreshes
                    waitGroup.leave()
                }
                let waitResults = waitGroup.wait(timeout: DispatchTime.now() + .seconds(resumeTimeoutSeconds))
                if waitResults == .timedOut {
                    print("TNT Login Manager - timed out waiting to complete user pool login")
                }
                
            } else {
                print("tntLogin Manager - cannot resume user pool session. (probably expired token)")
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
        
        // set the pool's interactive auth delegate to the AppDelegate
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        userPool?.delegate = appDelegate
    }
    
    func disableInteractiveUserPoolLogin() {
        
        // set the interactive auth delegate back to the default value from pool setup
        
        guard let defaultDelegate = userPoolDefaultDelegate else {
            print("TNT Login Manager:  disable interactive user pool login called but no default delegate saved")
            return
        }
        userPool?.delegate = defaultDelegate
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
    
    func completeLoginWithUserPool(clearKeys: Bool, completion: @escaping (_ success: Bool)->Void) {
    // convert a logged in user pool into a credential for use with AWS services
    // this should be called on successful completion of getDetails()
        
        let pool = self.userPool
        
        printPoolInfo()
        
        self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.COGNITO_REGIONTYPE, identityPoolId: Constants.COGNITO_IDENTITY_POOL_ID, identityProviderManager: pool)
        
        if clearKeys {
            
            credentialsProvider?.clearKeychain()
            assert(credentialsProvider?.identityId == nil)
        }
                    
        let configuration = AWSServiceConfiguration(region: Constants.COGNITO_REGIONTYPE, credentialsProvider: self.credentialsProvider)
                    
        AWSServiceManager.default().defaultServiceConfiguration = configuration
                    
        print("tntLoginManager:  service manager initialized")
        print("tntLoginManager (AWS user agent info): \(configuration?.userAgent ?? "Default")")
        
        self.credentialsProvider?.getIdentityId().continueWith { task in
            
                 if let error = task.error as NSError? {
                     print("TNT Login Manager, failed getting IdentityId for User Pool login. Error: \(error)")
                    completion(false)
                    
                 } else {
                     self.cognitoId  = self.credentialsProvider?.identityId
                     print("tntLoginManager: setting Cognito ID via user pool \(self.cognitoId ?? "Default")")
                    
                     let defaults = UserDefaults.standard
                     defaults.set(self.LOGIN_EMAIL, forKey: self.LASTLOGIN_KEY )
                    
                     completion(true)
                 }
                 return nil
         }
    }
    
}


