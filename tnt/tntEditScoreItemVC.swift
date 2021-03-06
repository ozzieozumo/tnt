//
//  tntEditScoreItemVC.swift
//  tnt
//
//  Created by Luke Everett on 11/5/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntEditScoreItemVC: UIViewController {
    
    var eventHeader: tntScoreItem?     // the header, i.e. pass 0 for the event
    var scoreItem: tntScoreItem?       // the pass being edited
    
    @IBOutlet var eventLabel: UILabel!
    @IBOutlet var passLabel: UILabel!
    @IBOutlet var baseScorePicker: UIPickerView!
    var showDecimalsInPicker: Bool = true
    
    
    
    @IBOutlet var difficultySlider: UISlider!
    @IBOutlet var difficultyLabel: UILabel!

    @IBOutlet var penaltyLabel: UILabel!

    @IBOutlet var penaltySlider: UISlider!
    @IBOutlet var flightLabel: UILabel!

    @IBOutlet var flightSlider: UISlider!
    
    
    @IBOutlet var netScoreLabel: UILabel!
    var netScore: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        baseScorePicker.dataSource = self
        baseScorePicker.delegate = self
        
        setupBasicScoring()
        
        setupAdvancedScoring()
        
        recalculate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // copy values back from controls to the scoreItem for the pass being edited
        
        scoreItem?.execution = baseScoreSelectedValue()
        scoreItem?.difficulty = Float(difficultySlider.value)
        scoreItem?.penalty = Float(penaltySlider.value)
        scoreItem?.flight = Float(flightSlider.value)
        scoreItem?.score = netScore
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   
 
    func setupBasicScoring() {
        
        guard let scoreItem = scoreItem, let eventHeader = eventHeader else {
            print("tntEditScoreItemVC - cannot setup editor without a score item")
            return
        }
        
        let eventName = tntScoreItem.eventNames[eventHeader.event] ?? "Other Event"
        let levelName = " (L\(eventHeader.level))"
        eventLabel.text = eventName + levelName
        passLabel.text = tntScoreItem.passNames[scoreItem.pass]
        let basicScore = scoreItem.score ?? 25.0   // use 25.0 as default value if no score yet
        
        var unitScore = Int(floor(basicScore))
        unitScore = min(unitScore, tntScoreItem.unitValues.max()!)   // cap at the number of values, just in case
        baseScorePicker.selectRow(unitScore, inComponent: 0, animated: false)
        
        let tenthsScore = Int(floor(basicScore.truncatingRemainder(dividingBy: 1.0) * 10))
        baseScorePicker.selectRow(tenthsScore, inComponent: 1, animated: false)
        
        recalculate()
        
    }
    
    func setupAdvancedScoring() {
    
        guard let scoreItem = scoreItem else {
            print("tntEditScoreItemVC - cannot setup editor without a score item")
            return
        }
        difficultySlider.value = Float(scoreItem.difficulty ?? 0.0)
        penaltySlider.value = Float(scoreItem.penalty ?? 0.0)
        flightSlider.value = Float(scoreItem.flight ?? 0.0)
    
    }
    
    func recalculate() {
        
        let execution = Double(baseScoreSelectedValue())
        let difficulty = Double((difficultySlider.value * 10).rounded() / 10)
        let penalty = Double((penaltySlider.value * 10).rounded() / 10)
        let flight = Double((flightSlider.value * 10).rounded() / 10)
        
        netScore = Float(execution + difficulty - penalty + flight)
        
        // update displayed values
        difficultyLabel.text = String(format: "%.2f", difficulty)
        penaltyLabel.text = String(format: "(-) %.2f", penalty)
        flightLabel.text = String(format: "%.2f",flight)
        netScoreLabel.text = String(format: "%.2f", netScore)
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func difficultyValueChanged(_ sender: UISlider) {
        
        recalculate()
    }
    
    
    @IBAction func difficultyDecrement(_ sender: Any) {
        
        difficultySlider.value -= 0.1
        recalculate()
    }
    
    @IBAction func difficultyIncrement(_ sender: Any) {
        difficultySlider.value += 0.1
        recalculate()
    }
    
    @IBAction func penaltyValueChanged(_ sender: UISlider) {
        
        recalculate()
    }
    
    @IBAction func penaltyDecrement(_ sender: Any) {
        penaltySlider.value -= 0.1
        recalculate()
    }
    
    @IBAction func penaltyIncrement(_ sender: Any) {
        penaltySlider.value += 0.1
        recalculate()
    }
    
    @IBAction func flightValueChanged(_ sender: UISlider) {
        
        recalculate()
    }
    
    @IBAction func flightDecrement(_ sender: Any) {
        flightSlider.value -= 0.1
        recalculate()
    }
    
    @IBAction func flightIncrement(_ sender: Any) {
        flightSlider.value += 0.1
        recalculate()
    }
}

extension tntEditScoreItemVC: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView == baseScorePicker {
            // components for unit score "25", and decimal score ".60"
            return 2
        }
        // any other pickers here
        
        // default
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == baseScorePicker {
            switch component {
                
            // make these dynamic based off some arrays
            case 0: return tntScoreItem.unitValues.count
            case 1: return showDecimalsInPicker ? tntScoreItem.decimalValues.count : 1
            default: return 0
            }
        }
        
        // other pickers here
        
        // default
        return 0
    }
}

extension tntEditScoreItemVC: UIPickerViewDelegate {
    
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
            return NSAttributedString(string: tntScoreItem.decimalValues[row])
        default: return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if component == 0 {
            if row == baseScorePicker.numberOfRows(inComponent: 0) - 1 {
                // showing the highest score, so reset the decimals
                if showDecimalsInPicker {
                    showDecimalsInPicker = false
                    baseScorePicker.reloadComponent(1)
                }
            } else {
                if !showDecimalsInPicker {
                    showDecimalsInPicker = true
                    baseScorePicker.reloadComponent(1)
                }
            }
        }
        recalculate()
    }
    
    func baseScoreSelectedValue() -> Float {
    
        let unitScore = Float(baseScorePicker.selectedRow(inComponent: 0))
        let tenthsScore = Float(baseScorePicker.selectedRow(inComponent: 1)) * 0.10
        
        return unitScore + tenthsScore
    }
    
    
}
