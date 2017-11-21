//
//  tntRelatedVideosTableCell.swift
//  tnt
//
//  Created by Luke Everett on 9/28/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntRelatedVideosTableCell: UITableViewCell {

    var video : Video? = nil
    weak var tableUpdatesDelegate: tntRelatedCellDelegate?
    
 
    @IBOutlet var videoCaptureDate: UILabel!
    @IBOutlet weak var videoTitle: UILabel!
    @IBOutlet weak var videoDescription: UITextView!
    @IBOutlet weak var videoThumb: UIImageView!
    @IBOutlet weak var videoRunTime: UILabel!
    
    @IBOutlet var viewToggleButton: UIButton!
    @IBOutlet var compactView: UIView!
    
    @IBOutlet var expandedView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setVideo(videoId: String) {
        
        video = tntLocalDataManager.shared.getVideoById(videoId: videoId)
        backgroundLoadMissingThumbnail(video)
        
    }
    
    func showVideoDetails(relatedVideoDict: [String: Any]) {
    
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var dateText: String
        
        if let captureDate = video?.captureDate as Date? {
            
            dateText = dateFormatter.string(from: captureDate)
            
        } else {
            dateText = "(date unknown)"
        }
        videoCaptureDate.text = dateText
        
        if let title = video?.title {
            videoTitle.text = title
        } else {
            videoTitle.text = "(Untitled)"
            // set font to light color
        }
        
        if let notes = video?.notes {
            videoDescription.text = notes
        } else {
            videoDescription.text = "(Edit to enter notes)"
            // set font to light color
        }
        
        if let imgData = video?.thumbImage as Data? {
            
            let img = UIImage(data: imgData)
            self.videoThumb.image = img
        } else {
            self.videoThumb.image = UIImage(imageLiteralResourceName: "smile-emoticon")
        }

        videoRunTime.text = String(format: "%.2f", video?.duration ?? 0.0)
        
        displayExpansionIndicator()
    }
    
    func backgroundLoadMissingThumbnail(_ video: Video?) {
        // It is possible that the binary image data for the thumbnail image is not in coredata
        // (e.g. when "reconnecting" on a new phone, or after clearing coredata.
        // Reload the thumbnail image in such cases.
        
    
        if video?.thumbImage == nil && video?.thumbKey != nil {
            
            if video?.thumbKey != nil {
                // only the video data is missing from CoreData, load it in the background
                let thumbQueue = DispatchQueue(label: "thumbimages")
                thumbQueue.async {
                    video?.loadThumbImage(imageURL: video?.thumbKey)
                }
            } else {
                // no thumbKey for video, try to reset it from cloud DB
                
            }
        }
        
    }
    
    func displayExpansionIndicator() {
        
        if expandedView.isHidden {
            let expandImage = UIImage(imageLiteralResourceName: "moredots")
            viewToggleButton.setImage(expandImage, for: .normal)
        } else {
            let contractImage = UIImage(imageLiteralResourceName: "connect-left")
            viewToggleButton.setImage(contractImage, for: .normal)
        }
    }
    
    func toggleExpansion () {
        
        expandedView.isHidden = !expandedView.isHidden
        
        displayExpansionIndicator()
        
        
    }

    @IBAction func tapToggleExpand(_ sender: Any) {
        
        // let the delegate (table view controller) perform the actions
        
        tableUpdatesDelegate?.didToggleExpansion(for: self)
    }
    
    
    @IBAction func tapEdit(_ sender: Any) {
        
        print("TNT Videos Cell - edit tapped")
        if let video = self.video {
            print("TNT Videos Cell - edit tapped, setting video for delegate")
            tableUpdatesDelegate?.didSetVideoToEdit(video: video)
        }
        
    }
}
