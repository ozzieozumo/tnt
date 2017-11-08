//
//  tntScoresTableHeaderView.swift
//  tnt
//
//  Created by Luke Everett on 11/2/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntScoresTableHeaderView: UIView {
    
    var eventHeader: tntScoreItem? = nil
    var controller: tntScoresTableViewController? = nil
    
    @IBOutlet var eventLabel: UILabel!
    @IBOutlet var totalScoreLabel: UILabel!
    
    @IBOutlet var medalImage: UIImageView!
    @IBOutlet var qualifiedImage: UIImageView!
    @IBOutlet var mobilizedImage: UIImageView!

    @IBOutlet var editMoreButton: UIButton!
    
    func setupHeader() {
        
        guard let eventHeader = eventHeader else {
            print("tntScoresTable Section Header has no event information")
            return
        }
        let eventName = tntScoreItem.eventNames[eventHeader.event] ?? "Other Event"
        let eventLevel = eventHeader.level
        eventLabel.text = eventName + " (\(eventLevel))"
        
        medalImage.isHidden = (eventHeader.medal == nil)
        qualifiedImage.isHidden = !eventHeader.qualified
        mobilizedImage.isHidden = !eventHeader.mobilized
        
        totalScoreLabel.text = String(format: "%.2f", eventHeader.score ?? 0.0)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    @IBAction func editHeaderTapped(_ sender: Any) {
        
        controller?.editHeader = eventHeader
        controller?.performSegue(withIdentifier: "tntEditEventHeader", sender: self)
        
    }
    
}
