//
//  tntScoresTableViewController.swift
//  tnt
//
//  Created by Luke Everett on 10/31/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntScoresTableViewController: UITableViewController {
    
    // Set by calling view controller
    var meetId: String = ""
    var athleteId: String = ""
    var scoreId: String {
        return athleteId + ":" + meetId
    }
    
    // Managed Objects
    var athleteMO: Athlete? = nil
    var meetMO: Meet? = nil
    var scoresMO: Scores? = nil
    
    // datasouce for the table, i.e. the array of scores dictionaries (one for each event & pass)
    
    var scores: [tntScoreItem] = []
    
    // data sent to edit score VC
    
    var selectedPass: tntScoreItem? = nil
    var selectedHeader: tntScoreItem? = nil  // the event header, or pass 0
    
    // data sent to edit header VC
    
    var editHeader: tntScoreItem? = nil
    

    override func viewDidLoad() {
        super.viewDidLoad()

        setupDataSource()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // reload all table data when returning from any editing views etc
        
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func setupDataSource() {
    
        guard athleteId != "" && meetId != "" else {
            print("TNT Scores Table View Controller: athlete and meet must be set by caller. Using empty datasource.")
            return
        }
        
        athleteMO = tntLocalDataManager.shared.athletes[athleteId]
        meetMO = tntLocalDataManager.shared.meets[meetId]
        
        guard athleteMO != nil && meetMO != nil else {
            print("TNT Scores Table View Controller: there was a problem retrieving athlete or meet from core data.")
            return
        }
        
        tntLocalDataManager.shared.fetchScores(scoreId)
        
        if let cachedMO = tntLocalDataManager.shared.scores[scoreId] {
            
            scoresMO = cachedMO
            // get the scores dictionary
            
            let scoresDictArray = cachedMO.scores as? [[String:Any]] ?? []
            
            for s in scoresDictArray {
                scores.append(tntScoreItem(s))
            }
            
            // sort the array
            
        } else {
            
            // no scores yet in core data for this athlete meet, create a new scores MO
            // TODO
            
            
        }
    
    }
    
    func events() -> [String] {
    
        return Set(scores.map {$0.event}).sorted()
    }
    
    func passes(_ event: String) -> [tntScoreItem] {
        
        return scores.filter {$0.event == event && $0.pass > 0}
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return events().count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return (scores.filter {$0.event == events()[section] && $0.pass > 0}).count
    }

 
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tntScoreItem", for: indexPath) as! tntScoresTableViewCell

        let scoredPass = passes(events()[indexPath.section])[indexPath.row]
        cell.scoreItem = scoredPass
        
        cell.setupCell()

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let codedEvent = events()[section]
        
        return tntScoreItem.eventNames[codedEvent] ?? "Something New"
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        // Need to calculate or set height of view here or in xib using constraints
        let headerView = Bundle.main.loadNibNamed("tntScoresTableHeaderView", owner: self, options: nil)![0] as! tntScoresTableHeaderView
        
        headerView.eventHeader = passes(events()[section])[0]
        headerView.controller = self
        headerView.setupHeader()
        headerView.totalScoreLabel.text = "59.50"
    
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        // TODO: figure out how to do automatic height calculation for table section headers (systemLaoutSizeFitting etc and layout passes)
        return 40.0
    }

    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPass = passes(events()[indexPath.section])[indexPath.row]
        selectedHeader = passes(events()[indexPath.section])[0]
        performSegue(withIdentifier: "tntEditScoreItem", sender: tableView)
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


    // MARK: - Navigation

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let destVC = segue.destination as? tntEditScoreItemVC {
            destVC.scoreItem = self.selectedPass
            destVC.eventHeader = self.selectedHeader
        }
        
        if let destVC = segue.destination as? tntEditEventHeaderVC {
            destVC.eventHeader = self.editHeader
            // TODO: pass in athlete info too, for current level checking
        }
    }

    

}
