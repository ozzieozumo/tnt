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
    
    // outlets
    
    @IBOutlet var emptyTableFooter: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntScoresTableViewController.observerScoresLoaded(notification:)), name: Notification.Name("tntScoresLoaded"), object: nil)

        setupDataSource()
        recalculateData()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // reload all table data when returning from any editing views etc
        
        recalculateData()
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // automatically save the table as a scores object in CoreData
        
        // only if the view is being popped (I think this could also be done in willMoveToParentViewController with a test for nil parent)
        if self.isMovingFromParentViewController {
            
            saveScores()
            
        }
        
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
            
            self.scoresMO = cachedMO
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
        
        emptyTableFooter.isHidden = !scores.isEmpty
        
    }
    
    func recalculateData() {
        
        // Recompute total score for the event header (displayed in section header)
        
        for event in events() {
            
            var headerItem = header(for: event)
            if headerItem == nil {
                // if existing data had no header row, create one now
                headerItem = tntScoreItem(event, 0)
                
                let athleteLevels = athleteMO?.eventLevels as! [String: Int]
                headerItem?.level = athleteLevels[event] ?? 0
                
                scores.append(headerItem!)
            }
            var totalScore: Float = 0.0
            
            for pass in passes(event) {
                
                totalScore += pass.score ?? 0.0
            }
            
            headerItem?.score = totalScore
            
        }
    }
    
    func createEmptyScoreSheet() {
        
        // Creates two blank passes for each standard event: double-mini, trampoline, tumbling
        
        for event in tntScoreItem.eventNames.keys.sorted() {
            
            // create event header (pass 0) and two passes (1 & 2) for each event
            
            for pass in 0...2 {
            
                let newScoreItem = tntScoreItem(event, pass)
                
                // set the level to the athlete's current level for the event
                
                let athleteLevels = athleteMO?.eventLevels as! [String: Int]
                newScoreItem.level = athleteLevels[event] ?? 0
                
                scores.append(newScoreItem)
            }
        }
        emptyTableFooter.isHidden = true
        tableView.reloadData()
    }
    
    func refreshScores() {
        
        // TODO: a) this should be unnecessary if initial athlete synch and background synch operations are working
        //  b) should involve some sort of time check, but for now refresh means overwrite with anything found in the cloud DB
        
        guard athleteId != "" && meetId != "" else {
            print("TNT Scores Table:  athlete ID and meet ID required for refresh")
            return
        }
        
        //delete scores object from Core Data and Cache
        tntLocalDataManager.shared.deleteScores(scoreId)
        
        //background query the cloud DB to load a scores object
        tntSynchManager.shared.loadScores(athleteId: athleteId, meetId: meetId)
        
        // ideally need a completion handler here to cancel activity indicator and then reload the table
        // for now, just wait for notifcation of scoreLoaded
    }
    
    func saveScores() {
        
        var scoresToSave: Scores? = nil
        
        if scoresMO != nil {
            scoresToSave = scoresMO
        } else {
            // need to create an MO first and set key attributes
            
            scoresToSave = Scores(context: tntLocalDataManager.shared.moc!)
            self.scoresMO = scoresToSave
            
            scoresToSave?.athleteId = athleteId
            scoresToSave?.meetId = meetId
            scoresToSave?.scoreId = scoreId
        }
        
        // now convert the table's datasource backinto an array of dictionaries
        
        var scoresDictArray: [[String:Any]] = []
        
        for item in scores {
            scoresDictArray.append(item.toDictionary())
        }
        
        scoresToSave?.scores = scoresDictArray as NSObject
        
        scoresToSave?.saveLocal()
        
        
    }
    
    func events() -> [String] {
    
        return Set(scores.map {$0.event}).sorted()
    }
    
    func passes(_ event: String) -> [tntScoreItem] {
        
        return scores.filter {$0.event == event && $0.pass > 0}
    }
    
    func header(for event: String) -> tntScoreItem? {
        let matchingHeaders = scores.filter {$0.event == event && $0.pass == 0}
        return matchingHeaders.count > 0 ? matchingHeaders[0] : nil
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
        
        headerView.eventHeader = header(for: events()[section])
        headerView.controller = self
        headerView.setupHeader()
    
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

    
    @IBAction func newScoreSheetTapped(_ sender: Any) {
        
        createEmptyScoreSheet()
        
    }
    
    
    @IBAction func refreshScoresTapped(_ sender: Any) {
        
        // Check the cloud DB for a more upto date version of the scores object
        
        refreshScores()
    }
    
    // MARK: Notification Center Observers
    
    func observerScoresLoaded(notification: Notification) {
        
        DispatchQueue.main.async{
            self.setupDataSource()
            self.recalculateData()
            self.tableView.reloadData()
        }
        
    }
    
}
