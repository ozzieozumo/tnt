//
//  tntAthleteSearchViewController.swift
//  tnt
//
//  Created by Luke Everett on 9/24/17.
//  Copyright © 2017 ozzieozumo. All rights reserved.
//

import UIKit

class tntAthleteSearchViewController: UITableViewController {
    
    var athletesForUser : [tntAthlete] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let userId = tntLoginManager.shared.cognitoId else {
            print("TNT: Search athletes for user but no cognitoID available")
            return
        }
        
        // set some activity indicator or subview

        tntSynchManager.shared.athletesSavedByUser(cognitoId: userId){ (result, error) in
            
            if error != nil {
                // Do something to display an error message
                
            } else {
                self.athletesForUser = result
                DispatchQueue.main.async { self.tableView.reloadData() }
            }
            
        }
        
        // clear some activity indicator or subview
        
        
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
        return athletesForUser.count
    }

   
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "athlete", for: indexPath)
        
        let athlete = athletesForUser[indexPath.row]
        
        cell.textLabel?.text = (athlete.lastName ?? "") + ", " + (athlete.firstName ?? "")
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // set some activity indicator
        if let athleteId = athletesForUser[indexPath.row].athleteId {
            
            tntSynchManager.shared.loadAthleteById(athleteId: athleteId) { (athleteMO) in
            
                // clear some activity indicator
                
                let defaults = UserDefaults.standard
                defaults.set(athleteMO.id, forKey: "tntSelectedAthleteId")
                
                DispatchQueue.main.async{
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.setInitialVC()
                }
                
            }
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

}
