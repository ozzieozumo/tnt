//
//  tntScoringViewController.swift
//  tnt
//
//  Created by Luke Everett on 7/20/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import UIKit
import CoreData

class tntScoringViewController: UIViewController {
    
    // This view allows entry of scores for a given athlete and meet
    // The meet and athlete should be set via prepareforsegue
    var meetId : String = ""
    var athleteId : String = ""
    var athleteMO: Athlete? = nil
    var meetMO: Meet? = nil
    
    var scoreId : String = ""
    var meetScores: Scores? = nil
    
    @IBOutlet weak var athleteName: UILabel!
    @IBOutlet weak var meetName: UILabel!
    
    @IBOutlet weak var scoreTR1: UITextField!
    @IBOutlet weak var scoreTU1: UITextField!
    @IBOutlet weak var scoreTU2: UITextField!
    @IBOutlet weak var scoreDMT1: UITextField!
    @IBOutlet weak var scoreDMT2: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntScoringViewController.observerScoresLoaded(notification:)), name: Notification.Name("tntScoresLoaded"), object: nil)
        
        scoreId = "\(athleteId):\(meetId)"
        
        getScoresContext()
        
        getScores()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getScoresContext() {
    
        athleteMO = tntLocalDataManager.shared.athletes[athleteId]
        meetMO = tntLocalDataManager.shared.meets[meetId]
        
        if athleteMO == nil || meetMO == nil {
            print("TNT Scores VC could not get athlete and meet objects for context")
        }
    }
    
    
    
    func displayScoresContext() {
        
        self.athleteName.text = (self.athleteMO?.lastName ?? "") + "," + (self.athleteMO?.firstName ?? "")
        
        self.meetName.text = self.meetMO?.title ?? ""
        
        
    }

    
    
    func getScores() {
        
        // if scores are available in coredata display them
        
        tntLocalDataManager.shared.fetchScores(scoreId)
        
        if let scores = tntLocalDataManager.shared.scores[scoreId] {
            
            meetScores = scores
            displayScores()
            
        } else {
            
            // Ask the synch manager to load the scores for this athlete & meet
            
            tntSynchManager.shared.loadScores(athleteId: athleteId, meetId: meetId)
        }

    }
    
    func displayScores() {
        
        guard let scores = meetScores else {
            print("TNT scores VC cannot display a nil scores object")
            return
        }
    
        // TODO:  hide/deactivate any sections not in the event list for this athlete & meet combo
        
        let scoresDictArray = scores.scores as? [[String:Any]] ?? []
        
        for passDict in scoresDictArray {
            
            let event = passDict["event"] as! String
            let pass  = passDict["pass"] as! Int
            let score = passDict["score"] as! Double
            
            if event == "TR" && pass == 1 { scoreTR1.text = "\(score)"}
            if event == "TU" && pass == 1 { scoreTU1.text = "\(score)"}
            if event == "TU" && pass == 2 { scoreTU2.text = "\(score)"}
            if event == "DMT" && pass == 1 { scoreDMT1.text = "\(score)"}
            if event == "DMT" && pass == 2 { scoreDMT2.text = "\(score)"}
                
            }
    }
    
 

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func saveScores(_ sender: Any) {
        
        guard let scores = meetScores else {
            print("TNT scores VC - cannot save when score object is nil")
            return
        }
        
        // 1: save new scores array to core data
        
        var scoresArray: [Dictionary<String, Any>] = []
        
        
        if let doubleTR1 = Double(scoreTR1.text ?? "") {
            scoresArray.append(["event": "TR", "pass": 1, "score": doubleTR1])
        }
        if let doubleTU1 = Double(scoreTU1.text ?? "") {
            scoresArray.append(["event": "TU", "pass": 1, "score": doubleTU1])
        }
        if let doubleTU2 = Double(scoreTU2.text ?? "") {
            scoresArray.append(["event": "TU", "pass": 2, "score": doubleTU2])
        }
        if let doubleDMT1 = Double(scoreDMT1.text ?? "") {
            scoresArray.append(["event": "DMT", "pass": 1, "score": doubleDMT1])
        }
        if let doubleDMT2 = Double(scoreDMT2.text ?? "") {
            scoresArray.append(["event": "DMT", "pass": 2, "score": doubleDMT2])
        }
        
        scores.scores = scoresArray as NSObject
        scores.saveLocal()
        tntSynchManager.shared.saveScores(scores.scoreId!)
        
    }
    
    @IBAction func cancelVC(_ sender: Any) {
        
        navigationController?.popViewController(animated: true)
        
    }
    // MARK: Notification Observers
    
    func observerScoresLoaded(notification: Notification) {
        // This notification received when score data is fetched from the cloud DB into Core Data
        
        DispatchQueue.main.async{
            
            self.getScores()
            
        }
        
    }


}
