//
//  Constants.swift
//  tnt
//
//  Created by Luke Everett on 4/13/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import Foundation
import AWSCore


struct Constants {
    
    // MARK: Required: Amazon Cognito Configuration
    
    static let COGNITO_REGIONTYPE = AWSRegionType.USEast1
    static let COGNITO_IDENTITY_POOL_ID = "us-east-1:f35978b2-4b85-4c22-97aa-f09c3551d25e"
    
    static let DEVICE_TOKEN_KEY = "DeviceToken"
    static let COGNITO_DEVICE_TOKEN_KEY = "CognitoDeviceToken"
    static let COGNITO_PUSH_NOTIF = "CognitoPushNotification"
    
    //KeyChain Constants
    static let BYOI_PROVIDER = "BYOI"
    
}
