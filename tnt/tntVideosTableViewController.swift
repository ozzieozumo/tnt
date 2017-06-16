//
//  tntVideosTableViewController.swift
//  tnt
//
//  Created by Luke Everett on 6/1/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import AWSS3

class tntVideosTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntVideosTableViewController.observerVideoLoaded(notification:)), name: Notification.Name("tntVideoLoaded"), object: nil)
        
        // if there are no videos in coredata, try to load from the cloud database
        
        let videoCount = tntLocalDataManager.shared.videos?.fetchedObjects?.count ?? 0
        
        if videoCount == 0 {
            
            tntSynchManager.shared.loadVideos() // asynch
            
        }
        
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
        return (tntLocalDataManager.shared.videos?.fetchedObjects?.count) ?? 0
    }

 
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "tntvideo", for: indexPath)
        // Set up the cell
        guard let object = tntLocalDataManager.shared.videos?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        //Populate the cell from the object
        
        //let urlLabel = UILabel()
        let cloudURL = object.value(forKey: "cloudURL") as? String
        //urlLabel.text =  cloudURL ?? ""
        cell.textLabel?.text = cloudURL ?? ""
        //urlLabel.backgroundColor = UIColor.orange
        
        //cell.addSubview(urlLabel)
        cell.contentView.backgroundColor = UIColor.cyan
        
        return cell

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // show a video player for the selected cell
        
        let videoMO = tntLocalDataManager.shared.videos?.object(at: indexPath)
        
        let movieKey = videoMO?.value(forKey: "cloudURL") as! String
        
        showPlayer(partialURL: movieKey)
        
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
    
    // MARK: - Notification Observers for asynch loading etc
    
    // MARK: Notification Observers
    
    func observerVideoLoaded(notification: Notification) {
        // This notification received when videos have been loaded from the cloud DB to core data
        
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
        
    }
    
    func showPlayer(partialURL: String) {
        
        // once the video has been uploaded, create and present a player
        
        // We cannot simply request the S3 video by URL since this would not pass any token and access would be denied
        
        // Instead we use the PreSigned URL builder
        
        let preSignedRequest = AWSS3GetPreSignedURLRequest()
        preSignedRequest.bucket = "ozzieozumo.tnt"
        preSignedRequest.key = partialURL
        preSignedRequest.httpMethod = .GET
        preSignedRequest.expires = Date().addingTimeInterval(48*60*60)
        
        let preSigner = AWSS3PreSignedURLBuilder.default()
        
        preSigner.getPreSignedURL(preSignedRequest).continueWith {
            (task) in
            
            if let error = task.error as? NSError {
                print("Error: \(error)")
                return nil
            }
            
            let presignedURL = task.result! as NSURL
            print("Download presignedURL is: \(presignedURL)")
            
            
            // switch to main queue for the UI actions
            
            DispatchQueue.main.async {
                let s3videoURL = presignedURL as URL
                let player = AVPlayer(url: s3videoURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
                
            }
            
            
            return nil
            
        }
        
        
    }



}
