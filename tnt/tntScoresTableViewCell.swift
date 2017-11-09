//
//  tntScoresTableViewCell.swift
//  tnt
//
//  Created by Luke Everett on 10/31/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntScoresTableViewCell: UITableViewCell {
    
    
    @IBOutlet var passLabel: UILabel!   
    @IBOutlet var netScoreLabel: UILabel!
    @IBOutlet var advancedScoringView: UIView!
    
    var scoreItem: tntScoreItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
       
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setupCell() {
    
        guard let scoreItem = scoreItem else {
            print("tntEditScoreItemVC - cannot setup a cell with a nil score item")
            return
        }
        
        passLabel.text = tntScoreItem.passNames[scoreItem.pass]
        netScoreLabel.text = String(format: "%.2f", scoreItem.score ?? 0.0)
        
    }

}


