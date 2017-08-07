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
    var scoreId : String = ""
    
    
    @IBOutlet weak var scoreTR1: UITextField!
    @IBOutlet weak var scoreTU1: UITextField!
    @IBOutlet weak var scoreTU2: UITextField!
    @IBOutlet weak var scoreDMT1: UITextField!
    @IBOutlet weak var scoreDMT2: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntScoringViewController.observerScoresLoaded(notification:)), name: Notification.Name("tntScoresLoaded"), object: nil)
        
        scoreId = "\(athleteId):\(meetId)"
        
        // if scores are available in local store, display them
        
        tntLocalDataManager.shared.fetchScores(scoreId)
        
        if let meetScores = tntLocalDataManager.shared.scores[scoreId] {
            
            
            self.displayScores(meetScores: meetScores)
            
            // TODO - display the score data and allow editing
            
        } else {
            
            
            // Ask the synch manager to load the scores for this athlete & meet
            // then wait for a notification
            
            tntSynchManager.shared.loadScores(athleteId: athleteId, meetId: meetId)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func displayScores(meetScores: NSManagedObject) {
    
        let events = meetScores.value(forKey: "events") as! Set<String>
        
        // TODO:  hide/deactivate any sections not in the event list for this athlete & meet combo
        
        let scores = meetScores.value(forKey: "scores") as! [Dictionary<String, Any>]
        
        for passDict in scores {
            
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
        
        // 1: Save to Core Data (pending = true)
        
        let scoresMO = tntLocalDataManager.shared.scores[scoreId]
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
        
        scoresMO?.setValue(scoresArray, forKey: "scores")
        scoresMO?.setValue(true, forKey: "cloudSavePending")
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext

        
        do {
            try managedContext.save()
            tntLocalDataManager.shared.scores[scoreId] = scoresMO
        } catch let error as NSError {
            print("Could not save scores to CoreData. \(error), \(error.userInfo)")
        }
        
        // 2. If WiFi available, save to CloudDB
        
        // omit check for network connection while testing Dynamao
        
        tntSynchManager.shared.saveScores(scoreId)
        
        // 2a in success handler, set pending = false 
        
        // 2b in failure / error handler leave pending = true and continue
        
        // 3. If WiFi unavailable just leave pending = true and continueSa
        
        
    }
    
    @IBAction func cancelVC(_ sender: Any) {
        
        navigationController?.popViewController(animated: true)
        
    }
    // MARK: Notification Observers
    
    func observerScoresLoaded(notification: Notification) {
        // This notification received when score data is fetched from the cloud DB into Core Data
        // Switch back to the main thread to update the UI
        
        DispatchQueue.main.async{
            self.displayScores(meetScores: tntLocalDataManager.shared.scores[self.scoreId]!)
        }
        
    }


}
