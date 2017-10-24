//
//  tntLoginManager.swift
//  tnt
//  
//  For setting up the login context using Facebook and Amazon Cognito
//
//  Created by Luke Everett on 5/11/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import AWSCognito
import AWSCognitoIdentityProvider

class tntLoginManager {
    
    static let shared = tntLoginManager()
    
    var loggedIn: Bool {
        return (fbToken != nil) && (cognitoId != nil)
    }
    var fbToken: FBSDKAccessToken?
    var cognitoId: String?
    var credentialsProvider: AWSCognitoCredentialsProvider?
    
    
    private init() {
        
        fbToken = nil
        cognitoId = nil
        credentialsProvider = nil
        
    }
    
    func loginWithSavedCredentials() {
        
        // Try to automatically login using FaceBook and AWS Cognito
        
        // 1. Check for the global FB Access Token
        
        self.fbToken = FBSDKAccessToken.current()
        if self.fbToken != nil {
            
            print("tntLogin Manager - found existing FB token, passing to Cognito")
            self.CognitoLogin()
            
        } else {
            // 2. No access token, so just leave fbToken as nil
            print("tntLogin Manager - no FB token, deferring login to view controller")
            return
        }
    }
    
    func CognitoLogin() {
        
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
        
        if self.credentialsProvider == nil {
            
            // Create an IdentityProviderManager to return the FB login info when requested
            
            let idpm = tntIdentityProvider(logins: fblogin)
            
            // Instantiate the Cognito credentials provider using region, pool and the logins
            
            self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.COGNITO_REGIONTYPE, identityPoolId: Constants.COGNITO_IDENTITY_POOL_ID, identityProviderManager: idpm)
            let configuration = AWSServiceConfiguration(region: Constants.COGNITO_REGIONTYPE, credentialsProvider: self.credentialsProvider)
            
            AWSServiceManager.default().defaultServiceConfiguration = configuration
            
            print("tntLoginManager:  service manager initialized")
            print("tntLoginManager (AWS user agent info): \(configuration?.userAgent ?? "Default")")
            
            // call getIdentityId here and print out in continuation block
            
            self.credentialsProvider?.getIdentityId().continueWith { task in
                
                // TODO: check for errors here
                
                self.cognitoId  = self.credentialsProvider?.identityId
                print("tntLoginManager: setting Cognito ID via FBlogin \(self.cognitoId ?? "Default")")
                
                return nil
                }
            
        }

    }
    
    func completeLoginWithUserPool() {
    // convert a logged in user pool into a credential for use with AWS services
        
        // get the Cognito user pool
        
        let pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        
        self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.COGNITO_REGIONTYPE, identityPoolId: Constants.COGNITO_IDENTITY_POOL_ID, identityProviderManager: pool)
        
        let cognitoIdBeforegetId = self.credentialsProvider?.identityId
                    
        let configuration = AWSServiceConfiguration(region: Constants.COGNITO_REGIONTYPE, credentialsProvider: self.credentialsProvider)
                    
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        // is it necessary to re-register the pool with the default service config?
        
        // AWSCognitoIdentityUserPool.register(with: configuration, userPoolConfiguration: pool.userPoolConfiguration, forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
                    
        print("tntLoginManager:  service manager initialized")
        print("tntLoginManager (AWS user agent info): \(configuration?.userAgent ?? "Default")")
        
        // if everything is honky dory, we should be able to access Dynamo DB.  If not, this will crash pretty fast. 
        
        tntSynchManager.shared.loadAthletes()
                    
        self.credentialsProvider?.getIdentityId().continueWith { task in
                     
                 if let error = task.error as NSError? {
                     print("TNT Login Manager, failed getting IdentityId for User Pool login. Error: \(error)")
                 } else {
                     self.cognitoId  = self.credentialsProvider?.identityId
                     print("tntLoginManager: setting Cognito ID via user pool \(self.cognitoId ?? "Default")")
                 }
                 return nil
         }
    }
}
