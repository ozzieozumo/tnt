//
//  tntMeetSetupListCell.swift
//  tnt
//
//  Created by Luke Everett on 12/26/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntMeetSetupListCell: UITableViewCell {

    var meet: Meet? = nil  {
        didSet {
            displayMeet()
        }
    }
    
    @IBOutlet var meetName: UILabel!
    @IBOutlet var meetDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
 
    func displayMeet() {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        
        meetDate.text = dateFormatter.string(from: meet!.startDate! as Date)
        meetName.text = meet?.title
    }
}
