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
            // Access has been denied. Ask for access
            print("TNT Photo Library:  access was previously denied, requesting interactively")
            // Note that this may be unnecessary. If the user has previously denied access or
            // has used the settings app to restrict access, then the interactive dialog will not be
            // displayed by this call to request.
            var newStatus = status
            let requestAccessGroup = DispatchGroup()
            requestAccessGroup.enter()
            requestAuthorization() { (status) in
                newStatus = status
                requestAccessGroup.leave()
            }
            requestAccessGroup .wait()
            if newStatus == .authorized {
                print("TNT Photo Library:  access authorized after interactive request")
                completion(true)
            } else {
                print("TNT Photo Library:  access was not authorized during interactive request")
                completion(false)
            }
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
