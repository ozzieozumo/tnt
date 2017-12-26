//
//  AppDelegate.swift
//  tnt
//
//  Created by Luke Everett on 3/30/17.
//  Copyright © 2017 ozziozumo. All rights reserved.
//

import UIKit
import CoreData

import AWSCore
import AWSCognito
import AWSCognitoIdentityProvider
import FBSDKCoreKit
import FBSDKLoginKit



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var signInViewController: tntUserPoolLoginViewController?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        print("TNT Team Tracker")
        
        // Connect the FaceBook app delegate to this application
        _ = FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Try to login using saved Facebook token and Cognito.  This will also init the AWS Cognito configuration
        
        tntLoginManager.shared.attemptSilentLogin()
        
        // Init the local data manager, loading available athletes from core data
        
        tntLocalDataManager.shared.loadLocalData()
        
        // Start background tasks to synch any standard data available to all user (e.g. meets)
        
        tntSynchManager.shared.loadStandardData()
        
        // Choose the starting VC based on login status, saved athletes etc
        
        setInitialVC()
        
        return true
        
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        // Allow Facebook login to return to this app
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
   

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // start (or restart) the cloudRetry task
        
        DispatchQueue.global().async {
            
            tntSynchManager.shared.startRetryTask()
            
        }
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "tnt")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: Initial VC selection
    
    func setInitialVC() {
        
        var startingVCs : [UIViewController] = []
        var debugVCs:  [UIViewController] = []
        
        guard let navController = self.window?.rootViewController as! UINavigationController? else {
            print("TNT setInitialVC: no navigation controller defined")
            return
        }
        
        #if DEBUG
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let debugUtilVC = storyboard.instantiateViewController(withIdentifier: "tntOptionsMenu")
            debugVCs.append(debugUtilVC)
            
        #endif
        
        
        if !tntLoginManager.shared.loggedIn {
            
            // not logged in, so open the login page
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "tntLoginMethods")
            startingVCs.append(loginVC)
        } else {
            // if running in debug mode, add the utilities page to the VCs
            
            let defaults = UserDefaults.standard
            let savedAthleteId = defaults.string(forKey: "tntSelectedAthleteId") ?? ""
            
            if tntLocalDataManager.shared.athletes[savedAthleteId] != nil {
                
                // athlete saved in user defaults and exists in core data -> display home VC
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let homeVC = storyboard.instantiateViewController(withIdentifier: "tntHomeVC")
                startingVCs.append(homeVC)
                
            } else {
                
                // otherwise, display athlete setup VC
                let storyboard = UIStoryboard(name: "AthleteSetup", bundle: nil)
                let setupVC = storyboard.instantiateViewController(withIdentifier: "tntAthleteSetup")
                startingVCs.append(setupVC)
                
            }
        }
       
        // dismiss any modally presented controllers, e.g. arising from user pool login process
        navController.dismiss(animated: false)
        navController.setViewControllers(debugVCs + startingVCs, animated: false)
    }

}

// MARK:- AWSCognitoIdentityInteractiveAuthenticationDelegate protocol delegate

extension AppDelegate: AWSCognitoIdentityInteractiveAuthenticationDelegate {
    
    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        
        guard let navController = self.window?.rootViewController as! UINavigationController? else {
            // the TNT should always have a navigation controller as the rootVC
            print("TNT startPasswordAuthentication: no navigation controller, returning unloaded controller")
            return tntUserPoolLoginViewController() // forced to return something
        }
        
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        signInViewController = (storyboard.instantiateViewController(withIdentifier: "tntUserPoolLogin") as! tntUserPoolLoginViewController)
        
        if let visibleVC = navController.visibleViewController {
            // present the login modally over the visible view
            
            visibleVC.present(self.signInViewController!, animated: false)
            // This will work unless the visible view is already presenting something modally - then you get a warning.
            // Also if there are multiple nav controllers chained together, the visibleViewController method doesn't walk through the chain
            // it would need to be called recursively to do that
            // easier to just make sure that 
        } else {
            print("TNT App Delegate - could not find a visible VC to present sign in VC")
        }
       
        return self.signInViewController!
    }
}


