//
//  tntOptionsTableCell.swift
//  tnt
//
//  Created by Luke Everett on 4/12/18.
//  Copyright © 2018 ozzieozumo. All rights reserved.
//

import UIKit

class tntOptionsTableCell: UITableViewCell {

    @IBOutlet var optionIcon: UIImageView!
    @IBOutlet var optionName: UILabel!
    @IBOutlet var optionSubtitle: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
