//
//  tntAthleteSelectViewController.swift
//  tnt
//
//  Created by Luke Everett on 9/24/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//
//  This VC allows the user to choose from Athletes saved in Core Data if any such athletes exist. 
//  The footer section includes a link to the Athlete Search VC which will permit searching the Dynamo DB for athletes. 


import UIKit

class tntAthleteSelectViewController: UITableViewController {
    
    var athletes : [(key: String, value: Athlete)] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // convert the dictionary of athletes into an array sorted by last name for display in the table
        
        for k in tntLocalDataManager.shared.athletes.keys {
            print("TNT athlete select found athlete with key \(k as String)")
        }
        
        athletes = tntLocalDataManager.shared.athletes.sorted{
                (first: (key: String, value: Athlete), second: (key: String, value: Athlete)) -> Bool in
                return (first.value.lastName ?? "") < (second.value.lastName ?? "")
        }
        
        displayHeader()
        displayFooter()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "athlete", for: indexPath)

        let athlete = athletes[indexPath.row].value
        
        cell.textLabel?.text = (athlete.lastName ?? "") + ", " + (athlete.firstName ?? "")
        
        return cell
    }


   
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
    }

   
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            
            let athleteToDelete = athletes[indexPath.row].value
            
            athletes.remove(at: indexPath.row)
            tntLocalDataManager.shared.deleteAthlete(athlete: athleteToDelete)
            
            // note that the athlete is NOT deleted from the cloud DB
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

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
    @IBAction func searchButton(_ sender: Any) {
        
        performSegue(withIdentifier: "tntSearchAthleteSegue", sender: self)
    }
    
    func displayHeader() {
        
        if athletes.count == 0 {
            self.tableView.tableHeaderView?.isHidden = true
        }
    }
    
    func displayFooter() {
        // maybe vary the message if no athletes found locally
        
    }

}
