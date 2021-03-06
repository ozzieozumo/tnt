//
//  tntEditVideoInfoVC.swift
//  tnt
//
//  Created by Luke Everett on 11/16/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntEditVideoInfoVC: UIViewController {
    
    // should be set on segue
    var video: Video? = nil
    
    @IBOutlet var captureDate: UILabel!
    @IBOutlet var thumbnail: UIImageView!
    
    @IBOutlet var runTime: UILabel!
    
    @IBOutlet var videoTitle: UITextField!
    @IBOutlet var videoNotes: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupVideo()
        videoTitle.delegate = self
        videoNotes.delegate = self
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // save values back to the video object
        video?.saveLocal()
    }
    
    func setupVideo() {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var dateText: String
        
        if let captureDate = video?.captureDate as Date? {
            
            dateText = dateFormatter.string(from: captureDate)
            
        } else {
            dateText = "(date unknown)"
        }
        captureDate.text = dateText
        
        if let title = video?.title {
            videoTitle.text = title
        } else {
            videoTitle.text = "(Untitled)"
            // set font to light color
        }
        
        let notes = video?.notes ?? ""
        
        if notes != "" {
            videoNotes.text = notes
            videoNotes.clearsOnInsertion = false
        } else {
            videoNotes.text = "Type some notes for this video"
            videoNotes.clearsOnInsertion = true
            videoNotes.resignFirstResponder()
        }
        
        if let imgData = video?.thumbImage as Data? {
            
            let img = UIImage(data: imgData)
            thumbnail.image = img
        } else {
            thumbnail.image = UIImage(imageLiteralResourceName: "smile-emoticon")
            // TODO : implement thumbnail chooser
        }
        
        runTime.text = String(format: "%.2f", video?.duration ?? 0.0)
        
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

extension tntEditVideoInfoVC: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        video?.title = textField.text
    }
}

extension tntEditVideoInfoVC: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        video?.notes = textView.text
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if videoNotes.text == "Type some notes for this video" {
            videoNotes.text = ""
        }
    }
    
}
