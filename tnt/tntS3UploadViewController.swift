//
//  tntS3UploadViewController.swift
//  tnt
//
//  Created by Luke Everett on 4/20/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import UIKit
import MobileCoreServices
import AWSS3

class tntS3UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var selectedImage: UIImage?;

    @IBOutlet weak var selectedImageView: UIImageView!
    
    override func viewDidLoad() {
        
        let uipc = UIImagePickerController()
        
        uipc.delegate = self
        uipc.sourceType = .photoLibrary
        uipc.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        uipc.modalPresentationStyle = .overCurrentContext
        
        self.present(uipc, animated: true, completion: nil)

        
        super.viewDidLoad()

    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: UIImagePickerController delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        self.selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        self.selectedImageView.image = self.selectedImage
        
        do {
            try FileManager.default.createDirectory(
                at: NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("upload")!,
                withIntermediateDirectories: true,
                attributes: nil)
        } catch {
            print("Creating 'upload' directory failed. Error: \(error)")
        }
        
        
        var filename = ""
        
        switch (info[UIImagePickerControllerMediaType] as! String){
        case kUTTypeImage as NSString as String:
            filename = "image.png";
            break;
            
        case kUTTypeMovie as NSString as String:
            filename = "movie.mp4"
            break;
            
        default: break
        }
        let uploadFileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("upload")?.appendingPathComponent("testimage.png")
        
        let imageData = UIImagePNGRepresentation(self.selectedImage!)
        
        do {
            try imageData!.write(to: uploadFileURL!, options: [.atomic])
        } catch {
            print(error)
        }
        let transferManager = AWSS3TransferManager.default()
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        
        uploadRequest!.bucket = "ozzieozumo.tnt"
        uploadRequest!.key = filename
        uploadRequest!.body = uploadFileURL!
        
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
            return task
        }
        
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
