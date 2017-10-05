//
//  tntVideoUploadViewController.swift
//  tnt
//
//  Created by Luke Everett on 6/20/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices
import AWSS3
import AVKit
import AVFoundation

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
        
        // let asset = AVURLAsset(url: uploadFileURL as URL)
        
        var phasset : PHAsset? = nil
        
        if let referenceURL = info[UIImagePickerControllerReferenceURL] {
            
            if let phasset = PHAsset.fetchAssets(withALAssetURLs: [referenceURL as! URL], options: nil).firstObject {
                
                uploadDelegate?.didChooseUploadVideo(sender: self, localMediaURL: uploadFileURL as URL, photosAsset: phasset)
            } else {
                print("TNT video upload: failure - could not retrieve Photos Asset for chosen video")
                return
            }
        }
        
        
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
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

