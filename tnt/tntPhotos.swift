//
//  tntPhotos.swift
//  tnt
//
//  Created by Luke Everett on 4/12/18.
//  Copyright © 2018 ozzieozumo. All rights reserved.
//

import Foundation
import Photos

extension PHPhotoLibrary {
    
    class func testOrRequestPhotoAccess(completion: @escaping (Bool)-> Void) {
        
        // Check if photo access has already been granted, otherwise request it
        
        let status = PHPhotoLibrary.authorizationStatus()
        
        if (status == PHAuthorizationStatus.authorized) {
            // Access has been granted.
            print("TNT Photo Library: access has already been granted")
            completion(true)
            
        }
            
        else if (status == PHAuthorizationStatus.denied) {
            // Access has been denied.
            print("TNT Photo Library:  access was (previously) denied")
            completion(false)
        }
            
        else if (status == PHAuthorizationStatus.notDetermined) {
            
            // Access has not been determined.
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                
                if (newStatus == PHAuthorizationStatus.authorized) {
                    print("TNT Photo Library: access was granted interactively")
                    completion(true)
                }
                    
                else {
                    print("TNT Photo Library: interactive access request failed")
                    completion(false)
                }
            })
        }
            
        else if (status == PHAuthorizationStatus.restricted) {
            // Restricted access - normally won't happen.
            print("TNT Photo Library: access to photo librarty is restricted (weird)")
            completion(false)
        }
    }
}
