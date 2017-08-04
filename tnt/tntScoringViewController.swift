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
    
    // MARK: Notification Observers
    
    func observerScoresLoaded(notification: Notification) {
        // This notification received when score data is fetched from the cloud DB into Core Data
        // Switch back to the main thread to update the UI
        
        DispatchQueue.main.async{
            self.displayScores(meetScores: tntLocalDataManager.shared.scores[self.scoreId]!)
        }
        
    }


}
