//
//  tntHomeViewController.swift
//  tnt
//
//  Created by Luke Everett on 4/6/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import UIKit
import AWSCore
import AWSDynamoDB
import AWSCognitoIdentityProvider
import AWSS3

class tntHomeViewController: UIViewController {
    
    @IBOutlet weak var tntName: UITextField!
    
    @IBOutlet weak var profileImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        /*
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
                                                                identityPoolId:"us-east-1:f35978b2-4b85-4c22-97aa-f09c3551d25e")
        
        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
 
        
        print("AWS SDK Agent String %@", configuration?.userAgent)
        
        // Retrieve your Amazon Cognito ID
        credentialsProvider.getIdentityId().continueWith(block: { (task) -> AnyObject? in
            if (task.error != nil) {
                print("Error: " + task.error!.localizedDescription)
            }
            else {
                // the task result will contain the identity id
                let cognitoId = task.result!
                print("Cognito id: \(cognitoId)")
            }
            return task;
        })
 */
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.load(tntAthlete.self, hashKey: "1", rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as? NSError {
                print("The request failed. Error: \(error)")
            } else if let athlete = task.result as? tntAthlete {
                
                print("TNT: retrieved name" + athlete.firstName! + athlete.lastName!)
                
                DispatchQueue.main.async {
                    self.tntName.text = athlete.firstName! + athlete.lastName!
                    
                    // load the profile image from the URL
                    
                    
                    let s3imgURL = URL(string: self.tntPreSignedURL(unsignedURL: athlete.profileImageURL!))
                    let imgData = try? Data(contentsOf: s3imgURL!, options: [])
                    
                    self.profileImage.image = UIImage (data: imgData!)
                    }
            }
            return nil
        })
        
        
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
    
    func tntPreSignedURL(unsignedURL: String) -> String {
        
        var preSignedURL : String? = nil
        let signingGroup = DispatchGroup()
        
        precondition(!Thread.isMainThread, "tntPreSignedURL : don't call this func from the main thread")
        
        let preSignedRequest = AWSS3GetPreSignedURLRequest()
        preSignedRequest.bucket = "ozzieozumo.tnt"
        
        // find the key (filename) starting after ozzieozumo.tnt/ 
        
        let keyStart = unsignedURL.index(unsignedURL.range(of: preSignedRequest.bucket)!.upperBound, offsetBy: 1)
        
        preSignedRequest.key = unsignedURL.substring(from: keyStart)
        preSignedRequest.httpMethod = .GET
        preSignedRequest.expires = Date().addingTimeInterval(48*60*60)
        
        let preSigner = AWSS3PreSignedURLBuilder.default()
        
        // not sure about this structure -- I want to treat this function as a synchronous call.  
        // Using the dispatchgroup and wait is one way to to do that.  Alternatively, the function could accept a completion handler. 
        // Perhaps, I should check inside the function that it is never being called on the main thread (which shouldn't wait on asynch tasks. 
        // However, it seems perfectly fine to have other (non main queue) tasks wait for this call to succeeed or fail
        
        signingGroup.enter()
        
        preSigner.getPreSignedURL(preSignedRequest).continueWith {
            (task) in
            
            if let error = task.error as? NSError {
                print("Error: \(error)")
                signingGroup.leave()
                return nil
            }
            
            preSignedURL = task.result!.absoluteString
            print("Download presignedURL is: \(preSignedURL)")
            signingGroup.leave()
            return nil
            
        }
        
        signingGroup.wait()
        return preSignedURL!
    }
    
}
