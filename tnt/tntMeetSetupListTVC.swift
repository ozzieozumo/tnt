//
//  tntMeetSetupListTVC.swift
//  tnt
//
//  Created by Luke Everett on 12/26/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntMeetSetupListTVC: UITableViewController {

    var teamMeets: [Meet] = []
    var privateMeets: [Meet] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension

        getTeamMeets()
        getPrivateMeets()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        getTeamMeets()
        getPrivateMeets()
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func meetForIndexPath(_ indexPath: IndexPath)  -> Meet? {
        
        if indexPath.section == 0 {
            return  teamMeets[indexPath.row]
        } else {
           return privateMeets[indexPath.row]
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return section == 0 ? teamMeets.count : privateMeets.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "meetCell", for: indexPath) as! tntMeetSetupListCell

        cell.meet = meetForIndexPath(indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return teamMeets.count > 0 ? "Team (Shared) Meets" : nil
        case 1:
            return privateMeets.count > 0 ? "Private Meets" : nil
        default:
            return nil
        }
    }
    
    func getTeamMeets() {
        
        // retrieves any shared/team meets from core data
        // also scans cloud DB for any newly shared meets
        
        self.teamMeets = tntLocalDataManager.shared.meets.values.filter {$0.sharedStatus == true }
        self.teamMeets.sort { ($0.startDate! as Date)  < ($1.startDate! as Date) }
        DispatchQueue.main.async { self.tableView.reloadData() }
        
    }
    
    func getPrivateMeets() {
       // private meets are only available on the current device
       // retrieve the private meets from coredata
       
        Meet.fetchAllPrivateMeets {
            self.privateMeets = tntLocalDataManager.shared.meets.values.filter {$0.sharedStatus == false }
            self.privateMeets.sort { ($0.startDate! as Date)  < ($1.startDate! as Date) }
            DispatchQueue.main.async { self.tableView.reloadData() }
        }
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var selectedMeet: Meet?
        
        switch indexPath.section {
        case 0:
            // shared or team meet
            selectedMeet = teamMeets[indexPath.row]
        case 1:
            // private meet
            selectedMeet = privateMeets[indexPath.row]
        default:
            selectedMeet = nil
        }
        guard let meetToEdit = selectedMeet else {
            print("TNT Meet Setup - Invalid selection from table")
            return
        }
        let storyBoard = UIStoryboard(name: "MeetSetup", bundle: nil)
        let editMeetVC = storyBoard.instantiateViewController(withIdentifier: "tntEditMeetVC") as! tntEditMeetVC
        
        editMeetVC.meet = meetToEdit
        
        self.navigationController?.pushViewController(editMeetVC, animated: true)
    }

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
 
    @IBAction func addMeetTapped(_ sender: Any) {
        
        performSegue(withIdentifier: "tntEditMeet", sender: sender)
        
        
    }
}
