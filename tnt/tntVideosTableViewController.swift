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
import Photos
import AWSS3

class tntVideosTableViewController: UITableViewController, tntVideoUploadPickerDelegate, tntRelatedCellDelegate {
    
    // This view displays videos, and allows upload of new videos, related to a particular athlete & meet 
    
    var athleteMO : Athlete?
    var meetMO : Meet?
    var scoresMO : Scores?
    var videos : [(expanded: Bool, info: [String:Any])] = []
    

    @IBOutlet weak var athleteName: UILabel!
    @IBOutlet weak var meetInfo: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntVideosTableViewController.observerScoresLoaded(notification:)), name: Notification.Name("tntScoresLoaded"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntVideosTableViewController.observerScoresNotFound(notification:)), name: Notification.Name("tntScoresNotFound"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntVideosTableViewController.observerRelatedVideoLoaded(notification:)), name: Notification.Name("tntScoresNewVideo"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(tntVideosTableViewController.observerThumbnailLoaded(notification:)), name: Notification.Name("tntVideoThumbnailLoaded"), object: nil)
        
        // if there are no videos in coredata, try to load from the cloud database
        
        getScores()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
    
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        showContextInfo()
        
        
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
        return self.videos.count
    }

 
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "tntvideo", for: indexPath) as! tntRelatedVideosTableCell
        // Set up the cell
        let info = self.videos[indexPath.row].info
            
        cell.tableUpdatesDelegate = self
        
        cell.setVideo(videoId: info["videoId"] as! String)
        cell.showVideoDetails(relatedVideoDict: info)
        cell.expandedView.isHidden = !(self.videos[indexPath.row].expanded)

        return cell

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // show a video player for the selected cell
        
        guard let videoId = self.videos[indexPath.row].info["videoId"] as? String else {
            print("TNT videos VC : videoId is nil for selected row")
            return
        }
        
        if let video = tntLocalDataManager.shared.getVideoById(videoId: videoId) {
            
            showPlayer(partialURL: video.cloudURL!)
        }
        
    }
  

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            
            let videoIdToDelete = videos[indexPath.row].info["videoId"] as! String?
            
            
            // delete related video for this scores obect .. using LocalDataManager or Scores
            // note that the actual video and thumb files will not be removed from S3 
            
            if let videoId = videoIdToDelete, let scores = scoresMO {
                scores.deleteVideo(relatedVideoId: videoId)
            }
            
            videos.remove(at: indexPath.row)
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
    
    // MARK: - Notification Observers for asynch loading etc
    
    // MARK: Notification Observers
    
    func observerRelatedVideoLoaded(notification: Notification) {
        // This notification received when a new video has been added as a related video of a scores object
        
        // reload the video into coredata
        
        guard let scores = self.scoresMO else {
            print("TNT : video loaded but scoresMO not set")
            return
        }
        
        if let notifiedScoreId = notification.userInfo?["scoreId"] as? String {
            
            if notifiedScoreId != scores.scoreId {
                return   // ignore any random notifications that arrive with the wrong scoreId
            }
            
        } else {
            print("TNT: scoreID expected but not received on notification for new related video")
            return
        }
        
        getScores()
        
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
        
    }
    
    func observerScoresLoaded(notification: Notification) {
        // This notification received when a new or updated scores object has been loaded to core data
        // This includes updated related video information
        
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
        
    }
    
    func observerThumbnailLoaded(notification: Notification) {
        // This notification received when a new or updated scores object has been loaded to core data
        // This includes updated related video information
        
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
        
    }

    
    func observerScoresNotFound(notification: Notification) {
        // This notification received when a request to load scores from Dynamo finds no score entity for the given id
        
        // Create a scores entity for this Id.  Save it to coredata and cloud. 
        
        guard let athleteId = athleteMO?.id, let meetId = meetMO?.id else {
            return
        }
        
        if let scoreId = notification.userInfo?["scoreId"] as? String {
            
            if scoreId == athleteId + ":" + meetId {
                let scoresMO = Scores(context: tntLocalDataManager.shared.moc!)
                scoresMO.athleteId = athleteId
                scoresMO.meetId = meetId
                scoresMO.scoreId = scoreId
                
                scoresMO.saveLocal()
                self.scoresMO = scoresMO
                tntSynchManager.shared.saveScores(scoreId)
                
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
            }
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
    
    func showContextInfo() {
        
        self.athleteName.text = (self.athleteMO?.lastName ?? "") + "," + (self.athleteMO?.firstName ?? "")
        
        self.meetInfo.text = self.meetMO?.title ?? ""
        
        
    }
    
    func getScores() {
        
        guard let athleteId = athleteMO?.id, let meetId = meetMO?.id else {
            print("TNT : athlete and meet must be set for videos view controller")
            return
        }
        
        let scoreId = athleteId + ":" + meetId
        
        // first try to fetch from coredata to populate the cache, since scores are not loaded until needed
        
        tntLocalDataManager.shared.fetchScores(scoreId)
        
        if let scores = tntLocalDataManager.shared.scores[scoreId] {
            
            self.scoresMO = scores
            let videoInfo = scores.videos! as! [[String:Any]]
            
            self.videos = videoInfo.flatMap { return (expanded: false, info: $0)}
            return
            
        } else {
            
            // request loading from cloud DB (and await notification)
            
            tntSynchManager.shared.loadScores(athleteId: athleteId, meetId: meetId)

            return
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destVC = segue.destination as? tntVideoUploadViewController {
            
            destVC.uploadDelegate = self
        }
        
    }
    
    
    @IBAction func didToggleExpand(_ sender: Any) {
        
    }
    
    func didChooseUploadVideo(sender: UIViewController, localMediaURL: URL?, photosAsset: PHAsset) {
        
        guard let url = localMediaURL else {
            return
        }
        
        // pop the VC of the video picker
        
        self.navigationController?.popViewController(animated: true)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // TODO (fancy) : show a progress indicator in a new table row or in the header
        
        // upload the file to S3 and create the video object
        
        tntSynchManager.shared.s3VideoUpload(url: url, asset: photosAsset, scores: scoresMO!)
    
    }
    
    func didToggleExpansion(for cell: tntRelatedVideosTableCell) {
        
        if let indexPath = tableView.indexPath(for: cell) {
            
            videos[indexPath.row].expanded = !videos[indexPath.row].expanded
            tableView.reloadRows(at: [indexPath], with: .fade)
            
        }
    }

}

protocol tntVideoUploadPickerDelegate : class {
    
    func didChooseUploadVideo(sender: UIViewController, localMediaURL: URL?, photosAsset: PHAsset)
    
}

protocol tntRelatedCellDelegate : class {
    func didToggleExpansion(for: tntRelatedVideosTableCell)
}



