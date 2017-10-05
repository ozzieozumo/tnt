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
    
    @IBOutlet weak var videoTitle: UILabel!
    @IBOutlet weak var videoDescription: UITextView!
    @IBOutlet weak var videoThumb: UIImageView!
    @IBOutlet weak var videoRunTime: UILabel!
    
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
    
        videoTitle.text = "Untitled (date unknown)"
        videoDescription.text = "meet specific video description from the scores table"
        if let imgData = video?.thumbImage as Data? {
            
            let img = UIImage(data: imgData)
            self.videoThumb.image = img
        } else {
            self.videoThumb.image = UIImage(imageLiteralResourceName: "smile-emoticon")
        }

        videoRunTime.text = "10.0 s"
    }

}
