/*
* Copyright 2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

/*
 * Copyright 2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import Foundation
import UICKeyChainStore
import AWSCore
import AWSCognito

class AmazonClientManager : NSObject {
    static let sharedInstance = AmazonClientManager()
    
    //Properties
    var keyChain: UICKeyChainStore
    var completionHandler: AWSContinuationBlock?
    var credentialsProvider: AWSCognitoCredentialsProvider?
    var loginViewController: UIViewController?
    
    override init() {
        keyChain = UICKeyChainStore(service: "\(Bundle.main.bundleIdentifier!).\(AmazonClientManager.self)")
        print("UICKeyChainStore: \(Bundle.main.bundleIdentifier!).\(AmazonClientManager.self)")
        
        
        super.init()
    }
    
    // MARK: General Login
    func isConfigured() -> Bool {
        return !(Constants.COGNITO_IDENTITY_POOL_ID == "YourCognitoIdentityPoolId" || Constants.COGNITO_REGIONTYPE == AWSRegionType.Unknown)
    }
    
    func resumeSession(completionHandler: @escaping AWSContinuationBlock) {
        self.completionHandler = completionHandler
        
        if self.keyChain[Constants.BYOI_PROVIDER] != nil {
            self.reloadBYOISession()
        }
        
        if self.credentialsProvider == nil {
            self.completeLogin(logins: nil)
        }
    }
    
    func completeLogin(logins: [NSObject : AnyObject]?) {
        var task: AWSTask<AnyObject>?
        
        if self.credentialsProvider == nil {
            task = self.initializeClients(logins: logins)
        } else {
            credentialsProvider?.invalidateCachedTemporaryCredentials()
            task = credentialsProvider?.getIdentityId() as! AWSTask<AnyObject>?
        }
        _ = task?.continueWith {
            (task: AWSTask!) -> AnyObject! in
            if (task.error != nil) {
                let userDefaults = UserDefaults.standard
                let currentDeviceToken: NSData? = userDefaults.object(forKey: Constants.DEVICE_TOKEN_KEY) as? NSData
                var currentDeviceTokenString : String
                
                if currentDeviceToken != nil {
                    currentDeviceTokenString = ""
                } else {
                    currentDeviceTokenString = ""
                }
                
                if currentDeviceToken != nil && currentDeviceTokenString != userDefaults.string(forKey: Constants.COGNITO_DEVICE_TOKEN_KEY) {
                    
                    AWSCognito.default().registerDevice(currentDeviceToken as! Data).continueWith { (task: AWSTask!) -> AnyObject! in
                        if (task.error == nil) {
                            userDefaults.set(currentDeviceTokenString, forKey: Constants.COGNITO_DEVICE_TOKEN_KEY)
                            userDefaults.synchronize()
                        }
                        return nil
                    }
                }
            }
            return task
            }
    }
    
    func initializeClients(logins: [NSObject : AnyObject]?) -> AWSTask<AnyObject>? {
        print("Initializing Clients...")
        
        AWSLogger.default().logLevel = AWSLogLevel.verbose
        
        self.credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: Constants.COGNITO_REGIONTYPE, identityPoolId: Constants.COGNITO_IDENTITY_POOL_ID)
        
        let configuration = AWSServiceConfiguration(region: Constants.COGNITO_REGIONTYPE, credentialsProvider: self.credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        return self.credentialsProvider?.getIdentityId() as! AWSTask<AnyObject>?
    }
    
    func loginFromView(theViewController: UIViewController, withCompletionHandler completionHandler: @escaping AWSContinuationBlock) {
        self.completionHandler = completionHandler
        self.loginViewController = theViewController
        self.displayLoginSheet()
    }
    
    func logOut(completionHandler: @escaping AWSContinuationBlock) {
    
        
        AWSCognito.default().wipe()
        self.credentialsProvider?.clearKeychain()
        
        AWSTask(result: nil).continueWith(block: completionHandler)
    }
    
    func isLoggedIn() -> Bool {
        return isLoggedInWithBYOI()
    }
    
    
    // MARK: BYOI
    func isLoggedInWithBYOI() -> Bool {
        return false
    }
    
    func reloadBYOISession() {
        print("Reloading Developer Authentication Session")
    }
    
    func BYOILogin() {
        print("BYOI login")
        
    }
    
    func completeBYOILogin( username: String?, password: String?) {
        
        print("complete BYOI login")
    }
    
    // MARK: UI Helpers
    func displayLoginSheet() {
        let loginProviders = UIAlertController(title: nil, message: "Login With:", preferredStyle: .actionSheet)
        
        let byoiLoginAction = UIAlertAction(title: "Developer Authenticated", style: .default) {
            (alert: UIAlertAction) -> Void in
            self.BYOILogin()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
            (alert: UIAlertAction!) -> Void in
            AWSTask(result: nil).continueWith(block: self.completionHandler!)
        }
        
        loginProviders.addAction(byoiLoginAction)
        loginProviders.addAction(cancelAction)
        
        self.loginViewController?.present(loginProviders, animated: true, completion: nil)
    }
    
    func errorAlert(message: String) {
        let errorAlert = UIAlertController(title: "Error", message: "\(message)", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { (alert: UIAlertAction) -> Void in }
        
        errorAlert.addAction(okAction)
        
        self.loginViewController?.present(errorAlert, animated: true, completion: nil)
    }
}
