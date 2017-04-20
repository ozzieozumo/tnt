//
//  tntIdentityProvider.swift
//  
//
//  Created by Luke Everett on 4/19/17.
//
//

import AWSCognito


class tntIdentityProvider: NSObject, AWSIdentityProviderManager {
    
    var keytokens: [String:String]?
    
    init (logins: [String:String]) {
        keytokens = logins
    }
    
    func logins () -> AWSTask<NSDictionary> {
        
        let task = AWSTask(result: keytokens as AnyObject?)
        return task as! AWSTask<NSDictionary>
    }

}
