//
//  tntScoresTableViewCell.swift
//  tnt
//
//  Created by Luke Everett on 10/31/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntScoresTableViewCell: UITableViewCell {
    
    
    @IBOutlet var basicScoringView: UIView!
    
    
    @IBOutlet var basicPicker: UIPickerView!
    let passNames: [String] = ["1st Pass", "2nd Pass"]
    let unitValues = 0...30
    let decimalValues = [0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90]
    
    @IBOutlet var advancedScoringView: UIView!
    
    var scoreItem: tntScoreItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        basicPicker.dataSource = self
        basicPicker.delegate = self
        
        basicPicker.selectRow(0, inComponent: 0, animated: false)
        basicPicker.selectRow(0, inComponent: 1, animated: false)
        basicPicker.selectRow(0, inComponent: 2, animated: false)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

extension tntScoresTableViewCell: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView == basicPicker {
            // components for pass ("1st pass"), unit score "25", and decimal score ".60"
            return 3
        }
        // other pickers here
        
        // default
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == basicPicker {
            switch component {
                
                // make these dynamic based off some arrays
                
                case 0: return passNames.count
                case 1: return unitValues.count
                case 2: return decimalValues.count
                default: return 0
            }
        }
        
        // other pickers here
        
        // default
        return 0
    }
}

extension tntScoresTableViewCell: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 25
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 80
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        switch component {
        case 0:
            return NSAttributedString(string: passNames[row])
        case 1:
            return NSAttributedString(string: String(row))
        case 2:
            return NSAttributedString(string: String(decimalValues[row]))
        default: return nil
        }
    }
    
    
}
