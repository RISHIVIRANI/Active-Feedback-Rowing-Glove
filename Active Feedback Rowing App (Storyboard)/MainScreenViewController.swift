//
//  MainScreenViewController.swift
//  Active Feedback Rowing App (Storyboard)
//
//  Created by Rishi Virani on 2/24/23.
//

import UIKit
import Firebase

// Variable to keep track of the number of sessions in Firebase
var numSessions = Int()

// Array to hold the numbers that correspond to each session; this will go in the UITable
var arrayForTable: [Int] = []

class MainScreenViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "CarbonRowing"
        
        // Count the number of documents in Firebase
        coreDatabase.child("All_User_Data").observe(DataEventType.value, with: { snapshot in
            let count = snapshot.childrenCount
            
            numSessions = Int(count)
        })
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
