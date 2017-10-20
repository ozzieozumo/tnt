//
//  tntAthleteSetupChoices.swift
//  tnt
//
//  Created by Luke Everett on 9/24/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

struct AthleteSetupChoice {
    var title: String
    var description: String
    var icon: UIImage?
    var segueId: String?
}

class tntAthleteSetupChoices: UITableViewController {
    
    var setupChoices:[AthleteSetupChoice] = []

    override func viewDidLoad() {
        
        setupChoices = [ AthleteSetupChoice(
                title: "New",
                description: "Setup a new athlete on this device",
                icon: nil,
                segueId: "tntEditAthleteSegue"
                ),
            AthleteSetupChoice(
                title: "Reconnect",
                description: "Reconnect this device to other athletes",
                icon: nil,
                segueId: "tntAthleteSelectSegue"
            )]
        
        super.viewDidLoad()

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
        return setupChoices.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)

        let choice = setupChoices[indexPath.row]
        cell.textLabel?.text = choice.title
        cell.detailTextLabel?.text = choice.description
     
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let segueId = setupChoices[indexPath.row].segueId {
            
            performSegue(withIdentifier: segueId, sender: self)
            
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

}
