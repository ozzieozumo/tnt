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
        videoTitle.text = "(Untitled)"
        
        if let imgData = video?.thumbImage as Data? {
            
            let img = UIImage(data: imgData)
            self.videoThumb.image = img
        } else {
            self.videoThumb.image = UIImage(imageLiteralResourceName: "smile-emoticon")
        }

        videoRunTime.text = String(format: "%.2f", video?.duration ?? 0.0)
        
        displayExpansionIndicator()
    }
    
    func displayExpansionIndicator() {
        
        if expandedView.isHidden {
            let expandImage = UIImage(imageLiteralResourceName: "down-arrow")
            viewToggleButton.setImage(expandImage, for: .normal)
        } else {
            let contractImage = UIImage(imageLiteralResourceName: "up-arrow")
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
}
