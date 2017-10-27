//
//  tntUserPoolLoginViewController.swift
//  tnt
//
//  Created by Luke Everett on 10/22/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class tntUserPoolLoginViewController: UIViewController {
    
    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>?
    var usernameText: String?
    
    
    @IBOutlet var loginEmail: UITextField!
    @IBOutlet var loginPassword: UITextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        
        if (loginEmail.text != nil && loginPassword.text != nil) {
            let authDetails = AWSCognitoIdentityPasswordAuthenticationDetails(username: loginEmail.text!, password: loginPassword.text! )
            passwordAuthenticationCompletion?.set(result: authDetails)
        } else {
            let alertController = UIAlertController(title: "Missing information",
                                                    message: "Please enter a valid email and password",
                                                    preferredStyle: .alert)
            let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
            alertController.addAction(retryAction)
        }
    }
    

}

extension tntUserPoolLoginViewController: AWSCognitoIdentityPasswordAuthentication {
    
    public func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        self.passwordAuthenticationCompletion = passwordAuthenticationCompletionSource
        
    }
    
    public func didCompleteStepWithError(_ error: Error?) {
        
        if let error = error as NSError? {
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                        message: error.userInfo["message"] as? String,
                                                        preferredStyle: .alert)
                let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
                alertController.addAction(retryAction)
                
                self.present(alertController, animated: true, completion:  nil)
            }
        } else { // Authentication successful
            print("TNT User Pool Login VC: successful login")
            tntLoginManager.shared.printPoolInfo()
            // IMPORTANT: don't try to call completeLogin() here, because currentUser etc is not set yet on the pool
        }
    }
}
