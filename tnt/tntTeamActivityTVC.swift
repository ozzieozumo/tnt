//
//  tntTeamActivityTVC.swift
//  tnt
//
//  Created by Luke Everett on 12/14/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit
import AWSCore

enum tntActivity {
    case scoreUpdate
    case videoUpdate
}

struct teamActivity {
    var timestamp: Date
    var type: tntActivity
    var scores: tntScores?
    var video: tntVideo?
}

class tntTeamActivityTVC: UITableViewController {

    var team: Team? = nil
    var activities: [teamActivity] = []
    
    @IBOutlet var teamName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntTeamActivityTVC.observerRefreshComplete(notification:)), name: Notification.Name("tntTeamActivityRefreshComplete"), object: nil)

        if let currentTeam = tntLoginManager.shared.currentTeam {
            self.team = currentTeam
            getActivities()
        } else {
            teamName.text = "Please join or create a team"
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tntTeamActivity", for: indexPath)

        let activity = activities[indexPath.row]
        let athleteId = activity.scores?.athleteId ?? "<Athlete Unknown>"
        let meetId = activity.scores?.meetId ?? "<Meet Uknown>"
        
        cell.textLabel?.text = "Score Update for \(athleteId) at \(meetId)"

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    func getActivities() {
    
        // 1. get the latest team definition from cloud (in case athletes have been added)
        // 2. get all meets with an end date within the last 7 days
        // 3. for each athlete in the team and for each recent meet, query the scores table
        // 4. determine if scores or videos have been updated
        
        tntTeam.loadTeamById(teamId: team?.teamId) { dbTeam in
            
            let athleteIds = dbTeam.athleteIds ?? []
            let meetIds = tntLocalDataManager.shared.meets.values.map {$0.id!}
            var scoreIds: [String] = []
            
            for meetId in meetIds {
                
                let meetEndDate = tntLocalDataManager.shared.meets[meetId]?.endDate as Date?
                
                if self.isRecent(date: meetEndDate) {
                    for athleteId in athleteIds {
                        let scoreId = athleteId + ":" + meetId
                        scoreIds.append(scoreId)
                    }
                }
            }
            
            // Now, query each scoreId separately, waiting for all tasks to complete
            
            tntSynchManager.shared.loadTeamScores(teamScoreIds: scoreIds).continueWith(block: { (task:AWSTask<tntTeamScores>!) -> Any? in
                if let error = task.error as NSError? {
                    print("Error loading team scores  \(error)")
                } else  {
                    let count = task.result?.teamScores.count ?? 0
                    print("TNT Team Activity VC : retrieved team scores \(count)")
                    // update UI and reload table
                    
                    self.activities = []
                    for score in task.result?.teamScores ?? [] {
                        let scoreActivity = teamActivity(timestamp: Date(), type: .scoreUpdate, scores: score, video: nil)
                        self.activities.append(scoreActivity)
                    }
                    
                    DispatchQueue.main.async {self.tableView.reloadData()}
                }
                return nil
            })
        }
        
    }
    
    func isRecent(date: Date?) -> Bool {
        // returns true if the difference between now and the input date is less than a constant value
        return true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func observerRefreshComplete(notification: Notification) {
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
    }

}
