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
