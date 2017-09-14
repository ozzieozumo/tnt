//
//  tntVideoUploadViewController.swift
//  tnt
//
//  Created by Luke Everett on 6/20/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import UIKit
import MobileCoreServices
import AWSS3

class tntVideoUploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // The picker delegate will either set a URL to upload or leave it as nil
    // The calling view controller is responsible for doing the upload, displaying spinners etc
    
    var uploadURL: URL? = nil
    weak var uploadDelegate : tntVideoUploadPickerDelegate?

    override func viewDidLoad() {
        
        let uipc = UIImagePickerController()
        uipc.delegate = self
        
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alertMessageOk(title: "Error", message: "The Photo Library is not available")
        }
        
        uipc.sourceType = .photoLibrary
        
        let mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)
        
        if !(mediaTypes?.contains(kUTTypeMovie as String))! {
            alertMessageOk(title: "Error", message: "Movie media type is not supported")
        }
        uipc.mediaTypes = [kUTTypeMovie as String]
        uipc.modalPresentationStyle = .overCurrentContext
        
        self.present(uipc, animated: true, completion: nil)
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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

    
    
    // MARK: UIImagePickerController delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        // self.selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // self.selectedImageView.image = self.selectedImage
        
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
        
        guard let uploadFileURL = info[UIImagePickerControllerMediaURL] as? NSURL else {
            print("TNT video upload : local file URL not available, cannot upload")
            return
        }
        
        
        uploadDelegate?.didChooseUploadURL(sender: self, uploadURL: uploadFileURL as URL)
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    func s3VideoUpload(url: URL) {
        let transferManager = AWSS3TransferManager.default()
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        
        uploadRequest!.bucket = "ozzieozumo.tnt"
        let videoKey = "videos/" + UUID().uuidString.lowercased() + ".mov"
        uploadRequest!.key = videoKey
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
            
            tntSynchManager.shared.createVideo(s3VideoKey: videoKey)
            
            return task
        }
        
    }
    

}

extension UIViewController {
    func alertMessageOk(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}

