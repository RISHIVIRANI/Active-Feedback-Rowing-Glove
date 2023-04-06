//
//  PastSessionsViewController.swift
//  Active Feedback Rowing App (Storyboard)
//
//  Created by Rishi Virani on 2/24/23.
//

import UIKit
import Firebase

var stringSessionArray = [String]()
var selectedSession = Int()

var pressureInfo = Int()
var timingInfo = Int()

class PastSessionsViewController: UIViewController {
    
    // Interface with picker view
    @IBOutlet weak var picker: UIPickerView!
    
    // Interface with pressure and timing information displays
    @IBOutlet weak var pressureDisplay: UITextField!
    @IBOutlet weak var timingDisplay: UITextField!
    
    // MARK: INITIALIZE VIEW
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign title to view controller
        title = "Select a Session"
        
        // Configure picker view
        picker.dataSource = self
        picker.delegate = self
        
        // Make array of all available sessions to see as String
        let sessionArray = 1...numSessions
        stringSessionArray = sessionArray.map {String($0)}
        
    }
    
}

// MARK: INITIALIZE PICKER
extension PastSessionsViewController: UIPickerViewDataSource {
    
    // Only show one column in the picker view
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Set the number of rows equal to the number of possible sessions that are available for viewing
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return numSessions
    }
    
}

extension PastSessionsViewController: UIPickerViewDelegate {
    
    // Present all options to user
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return stringSessionArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        // Determine the selected session
        selectedSession = (Int(stringSessionArray[row]) ?? 1) - 1
        
        // Fetch pressure info
        coreDatabase.child("All_User_Data").child("\(selectedSession)").child("Duration of Erroneous Pressure Application").observe(DataEventType.value, with: { snapshot in
            pressureInfo = snapshot.value as! Int
        })
        
        // Fetch timing info
        coreDatabase.child("All_User_Data").child("\(selectedSession)").child("Duration of Erroneous Timing").observe(DataEventType.value, with: { snapshot in
            timingInfo = snapshot.value as! Int
        })
        
        pressureDisplay.text = pressureInfo.description
        
        timingDisplay.text = timingInfo.description
        
        selectedSession = (Int(stringSessionArray[row]) ?? 1) - 1
    }
    
}
