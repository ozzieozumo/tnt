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
    
    
    
    @IBOutlet var passLabel: UILabel!
    @IBOutlet var basicPicker: UIPickerView!
    let passNames: [String] = ["1st Pass", "2nd Pass"]
    let unitValues = 0...30
    let decimalValues = [".00", ".10", ".20", ".30", ".40", ".50", ".60", ".70", ".80", ".90"]
    
    @IBOutlet var advancedScoringView: UIView!
    
    var scoreItem: tntScoreItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        basicPicker.dataSource = self
        basicPicker.delegate = self
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupCell() {
        
        guard let scoreItem = scoreItem else {
            print("tntScoresTableViewCell - cannot setup a cell with a nil score item")
            return
        }
        
        passLabel.text = passNames[scoreItem.pass - 1]
        let basicScore = scoreItem.score ?? 25.0   // use 25.0 as default value if no score yet
        
        var unitScore = Int(floor(basicScore))
        unitScore = min(unitScore, unitValues.max()!)   // cap at the number of values, just in case
        basicPicker.selectRow(unitScore, inComponent: 0, animated: false)
        
        let tenthsScore = Int(floor(basicScore.truncatingRemainder(dividingBy: 1.0) * 10))
        basicPicker.selectRow(tenthsScore, inComponent: 1, animated: false)
        
    }

}

extension tntScoresTableViewCell: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView == basicPicker {
            // components for unit score "25", and decimal score ".60"
            return 2
        }
        // other pickers here
        
        // default
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == basicPicker {
            switch component {
                
                // make these dynamic based off some arrays
                case 0: return unitValues.count
                case 1: return decimalValues.count
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
        return 60
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        switch component {
        case 0:
            return NSAttributedString(string: String(row))
        case 1:
            return NSAttributedString(string: decimalValues[row])
        default: return nil
        }
    }
    
    
}
