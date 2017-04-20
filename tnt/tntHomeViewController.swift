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

class tntHomeViewController: UIViewController {
    
    @IBOutlet weak var tntName: UITextField!
    
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
                
                DispatchQueue.main.async { self.tntName.text = athlete.firstName! + athlete.lastName! }
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
    
}
