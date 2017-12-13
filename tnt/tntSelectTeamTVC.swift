//
//  tntSelectTeamTVC.swift
//  tnt
//
//  Created by Luke Everett on 11/30/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntSelectTeamTVC: UITableViewController {

    // team should be set on segue
    var team: Team? = nil
    var athletes: [Athlete] = []
    
    @IBOutlet var addAthletesButton: UIBarButtonItem!
    
    @IBOutlet var teamNameLabel: UILabel!
    @IBOutlet var allTeamsSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        teamNameLabel.text = team?.name ?? "No team selected"
        getAvailableAthletes()
        
        tableView.allowsMultipleSelection = true
        
        addAthletesButton.isEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return athletes.count
    }

    func getAvailableAthletes() {
        
        // retrieve athletes from core data for the current logged in user
        let cognitoId = tntLoginManager.shared.cognitoId
        let ownedAthletes = tntLocalDataManager.shared.athletes.values.filter {$0.cognitoId == cognitoId}
        
        // sort them and store in the table datasource
        self.athletes = ownedAthletes.sorted { $0.lastName ?? "" < $1.lastName ?? ""}
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "joinathlete", for: indexPath)
        
        let athlete = athletes[indexPath.row]
        cell.textLabel?.text = (athlete.lastName ?? "") + ", " + (athlete.firstName ?? "")

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        addAthletesButton.isEnabled = (tableView.indexPathsForSelectedRows ?? []).count > 0
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        addAthletesButton.isEnabled = (tableView.indexPathsForSelectedRows ?? []).count > 0
    }

    func addSelectedAthletes() {
        
        if let rows = tableView.indexPathsForSelectedRows {
            
            guard rows.count <= athletes.count else {
                print("TNT team setup - invalid number of rows adding athletes to team")
                return
            }
            
            let athletesToAdd  = rows.map {athletes[$0.row]}
            
            //TODO - implement adding to all teams based on switch in header
            
            athletesToAdd.forEach { team?.addAthlete(athleteId: $0.id!) }
            team?.saveLocal()
            
            tntTeam.loadTeamById(teamId: (team?.teamId)!) { (dbTeam) in
                dbTeam.mergeDeviceData(team: self.team!)
                dbTeam.saveToCloud()
            }
        } else {
            print("TNT team setup, no athlete rows selected")
        }
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func addAthletesTapped(_ sender: Any) {
    
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let addAction = UIAlertAction(title: "Add", style: .default) { action in
            
            self.addSelectedAthletes()
            self.tableView.reloadData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
            print("TNT Team Setup - add athletes canceled")
        }
        for action in [addAction, cancelAction] {
            actionSheet.addAction(action)
        }
        
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
}
