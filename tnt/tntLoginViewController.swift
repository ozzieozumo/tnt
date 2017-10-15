//
//  tntLoginViewController.swift
//  tnt
//
//  Created by Luke Everett on 4/13/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import AVKit
import UICKeyChainStore
import FBSDKLoginKit
import AWSCognito
import AWSS3

class tntLoginViewController: UIViewController {
    
    var fbToken: FBSDKAccessToken?
    var credentialsProvider: AWSCognitoCredentialsProvider?
    var fbLoginManager: FBSDKLoginManager?
    
    
    @IBOutlet weak var btnDynamo: UIButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if tntLoginManager.shared.fbToken == nil {
            self.fbLoginManager = FBSDKLoginManager()
            self.fbLoginManager?.logIn(withReadPermissions: ["public_profile"], from: self) {
                    (result, error) -> Void in
                    
                    if (error != nil) {
                        DispatchQueue.main.async {
                            
                            let alert = UIAlertController(title: "Error logging in with FB", message: error!.localizedDescription, preferredStyle: .alert)
                            self.presentingViewController?.present(alert, animated: true, completion: nil)
                        }
                    } else if result!.isCancelled {
                        //Do nothing
                        print("FB Login result was cancelled")
                        
                    } else {
                        // Now the current access token should be set on Facebook
                        self.fbToken = FBSDKAccessToken.current()
                        
                        // Now that we have the FBToken (in this thread), proceed to setup the Cognito Service
                        tntLoginManager.shared.CognitoLogin()
                    }
                }
            }
        
       
    
    }

    
    func CognitoLogin() {
     
        
        // assert(self.fbToken != nil)  also, this won't be on the main thread
        
        // print out some information about the Facebook Token and User Profile
        
        print("tnt: FBSDK Version \(FBSDKSettings.sdkVersion())")
        
        FBSDKProfile.loadCurrentProfile  { (profile, error) -> Void in
            // Completion handler for loadCurrentProfile
            if (error != nil) {
                    print("tnt:error in loadCurrentProfile")
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
            
            print("tnt: Logged in to AWS Cognito")
            print("tnt: \(configuration?.userAgent)")
            
            // could call getIdentityId here and print out in continuation block
            
            self.credentialsProvider?.getIdentityId().continueWith { task in
                
                print("tnt: Cognito Identity ID \(self.credentialsProvider?.identityId)")
                
            }
            
        } else {
            // we already have a credentials provider 
            // should probably call getIdentityId or something here
        }
        
        DispatchQueue.main.async {
            
            self.btnDynamo.isUserInteractionEnabled = true
        }
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

    @IBAction func uploadVideo(_ sender: AnyObject) {
        
        // in the iOS simulator, the UIPickerController cannot be used to choose a video. 
        // Therefore, to test video upload to S3 we choose an available video using Photos framework 
        
    
        // fetch any video asset
        
        let assets = PHAsset.fetchAssets(with: .video, options: nil)
        
        if assets.count > 0 {
            
            let videoAsset: PHAsset = assets.firstObject!
            
            _ = videoAsset.requestContentEditingInput(with: PHContentEditingInputRequestOptions(), completionHandler: { (contentEditingInput, dictInfo) in
                
                if videoAsset.mediaType == .video {
                    if let strURL = (contentEditingInput!.audiovisualAsset as? AVURLAsset)?.url.absoluteString
                    {
                        print("VIDEO URL: ", strURL)
                    }
                }
            })
            
            let imageManager = PHImageManager.default()
            let options = PHVideoRequestOptions()
            _ = imageManager.requestAVAsset(forVideo: videoAsset, options: options, resultHandler: { 
                (avasset, audio, info) in
                
                // can we cast the avasset down to an AVURLAsset
                
                let avu = avasset as? AVURLAsset
                let strURL = avu?.url.absoluteString
                print("VIDEO URL from requestAVAsset: ", strURL)
                
                
                // upload the video asset to S3
                
                self.s3VideoUpload(url: avu!.url)
                
                
            })
            
            
        }
    }
    
    func s3VideoUpload(url: URL) {
        let transferManager = AWSS3TransferManager.default()
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        
        uploadRequest!.bucket = "ozzieozumo.tnt"
        uploadRequest!.key = "movie.mov"
        uploadRequest!.body = url
        
        transferManager.upload(uploadRequest!).continueWith { (task) -> AnyObject! in
            if let error: NSError = task.error as NSError? {
                if error.domain == AWSS3TransferManagerErrorDomain as String {
                    if let errorCode = AWSS3TransferManagerErrorType(rawValue: error.code) {
                        switch (errorCode) {
                        case .cancelled, .paused:
                            // update UI on main queue
                            break;
                            
                        default:
                            print("upload() failed: [\(error)]")
                            break;
                        }
                    } else {
                        print("upload() failed: [\(error)]")
                    }
                } else {
                    print("upload() failed: [\(error)]")
                }
            }
            print("video upload success")
            
            // once the video has been uploaded, create and present a player 
            
            self.showPlayer()
            
            return task
        }

    }
    
    @IBAction func playVideoClicked(_ sender: AnyObject) {
        
        self.showPlayer()
        
    }
    
    func showPlayer() {
        
        // once the video has been uploaded, create and present a player
        
        // We cannot simply request the S3 video by URL since this would not pass any token and access would be denied
        
        // Instead we use the PreSigned URL builder
        
        let preSignedRequest = AWSS3GetPreSignedURLRequest()
        preSignedRequest.bucket = "ozzieozumo.tnt"
        preSignedRequest.key = "movie.mov"
        preSignedRequest.httpMethod = .GET
        preSignedRequest.expires = Date().addingTimeInterval(48*60*60)
        
        let preSigner = AWSS3PreSignedURLBuilder.default()
        
        preSigner.getPreSignedURL(preSignedRequest).continueWith {
            (task) in
            
            if let error = task.error as? NSError {
                print("Error: \(error)")
                return nil
            }
            
            let presignedURL = task.result! as NSURL
            print("Download presignedURL is: \(presignedURL)")
            
            
            // switch to main queue for the UI actions
            
            DispatchQueue.main.async {
                let s3videoURL = presignedURL as URL
                let player = AVPlayer(url: s3videoURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
                
            }

            
            return nil
            
        }
        
        
    }
    
    @IBAction func clearCoreDataClicked(_ sender: AnyObject) {
        
        // clear all managed objects from CoreData
        
        tntLocalDataManager.shared.clearTNTObjects()
        
    }
    
}
