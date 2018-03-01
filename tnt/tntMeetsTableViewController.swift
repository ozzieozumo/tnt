//
//  tntMeetsTableViewController.swift
//  tnt
//
//  Created by Luke Everett on 7/20/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import UIKit

class tntMeetsTableViewController: UITableViewController {

   
    var selectedMeetId : String? = nil
    var meets: [Meet] = []
    
    @IBOutlet weak var nextMeetSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        meets = tntLocalDataManager.shared.availableMeets()
        
        let defaults = UserDefaults.standard
        
        let dateSelect = defaults.bool(forKey: "nextMeetSelectByDate")
        
        if dateSelect {
            nextMeetSwitch.setOn(true, animated: false)
            self.selectedMeetId = Meet.nextMeet(startDate: Date())?.id
            
        } else {
            nextMeetSwitch.setOn(false, animated: false)
            self.selectedMeetId = Meet.lastSelected()?.id
            
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
        return meets.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        

        let cell = tableView.dequeueReusableCell(withIdentifier: "tntmeet", for: indexPath)
   
        if indexPath.row <= meets.count {
            let meet = meets[indexPath.row]
            //Populate the cell from the object
            
            cell.textLabel?.text = meet.title
            return cell

        } else {
            fatalError("Attempt to configure cell without a managed object")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // show selected row as selected
        
        let meet = meets[indexPath.row]
        
        if meet.id == self.selectedMeetId {
                cell.setSelected(true, animated: true)
            } else {
                cell.setSelected(false, animated: true)
            }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let meet = meets[indexPath.row]
            
        Meet.setLastSelected(meetId: meet.id)
        navigationController?.popViewController(animated: true)
        
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if nextMeetSwitch.isOn {
            return nil
        } else {
            return indexPath
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
    
    
    @IBAction func nextMeetSwitchChanged(_ sender: Any) {
        
        // save the selection to user defaults
        
        let defaults = UserDefaults.standard
        defaults.set(nextMeetSwitch.isOn, forKey: "nextMeetSelectByDate")
        defaults.synchronize()
        
        if nextMeetSwitch.isOn {
            
            self.selectedMeetId = Meet.nextMeet(startDate: Date())?.id
            
            tableView.reloadData()
        }
        
        
    }

}
