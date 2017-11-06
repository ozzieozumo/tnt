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
    
    @IBOutlet var eventLabel: UILabel!
    
    @IBOutlet var totalScoreLabel: UILabel!
    
    
    func setupHeader() {
        
        guard let eventHeader = eventHeader else {
            print("tntScoresTable Section Header has no event information")
            return
        }
        
        eventLabel.text = tntScoreItem.eventNames[eventHeader.event] ?? "Other Event"
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    @IBAction func addPassesTapped(_ sender: Any) {
    }
}
