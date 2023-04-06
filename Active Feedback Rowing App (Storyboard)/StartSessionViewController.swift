//
//  StartSessionViewController.swift
//  Active Feedback Rowing App (Storyboard)
//
//  Created by Rishi Virani on 2/24/23.
//

// Import libraries
import UIKit
import MapKit
import CoreBluetooth
import Firebase

// Assign UUIDs
let arduinoServiceUUID = CBUUID(string: "5CBF9D99-46B2-4255-9F44-73B76D5353B8")
let pressureCharacteristicUUID = CBUUID(string: "FA571202-D0A0-4477-B71B-4A5E70D3477C")
let yAccelCharacteristicUUID = CBUUID(string: "78211F0E-B738-4F17-BBB7-1EB3BAAD02D4")
let xGyroCharacteristicUUID = CBUUID(string: "23B0357D-0FBD-4032-BD07-55445E471E38")

// Assign variable to track how the session number
var sessionNumber: Int?

// Create Firebase database reference
let coreDatabase = Database.database().reference()

class StartSessionViewController: UIViewController, CLLocationManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {
    // MARK: INITIALIZE VIEW
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Determine the session number
        sessionNumber = UserDefaults.standard.integer(forKey: "launchCount")
        UserDefaults.standard.set(sessionNumber!+1, forKey: "launchCount")
        
        // Display the current session number to console
        print("Session Number")
        print(sessionNumber!)
        
        // Set title of current page
        title = "Current Session"
        
        // Configure displays
        PressureDisplay.layer.cornerRadius = 25
        AccelerationDisplay.layer.cornerRadius = 25
        GyroscopeDisplay.layer.cornerRadius = 25
        
        PressureDisplay.layer.masksToBounds = true
        AccelerationDisplay.layer.masksToBounds = true
        GyroscopeDisplay.layer.masksToBounds = true
        
        // Configure mapKit view
        mapKit.layer.cornerRadius = 35
        mapKit.layer.borderWidth = 1
        mapKit.layer.borderColor = UIColor.black.withAlphaComponent(0.05).cgColor
        
        // Configure Location Services
        configureLocationServices()
        
        // Configure BLE Services
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Create labels and buttons for pressure, acceleration, and gyrometer
    @IBOutlet weak var PressureDisplay: UILabel!
    @IBOutlet weak var AccelerationDisplay: UILabel!
    @IBOutlet weak var GyroscopeDisplay: UILabel!
    
    // MARK: BLUETOOTH CONNECTION
    // Assign variables to hold the central manager and peripheral device
    var centralManager: CBCentralManager!
    var arduinoPeripheral: CBPeripheral!
    
    // Attempt to initialize device BLE; handle exception via user prompt
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            // iOS Device BLE is turned on and authorized
            print("BLE is powered on")
            
            // Scan for the arduino
            central.scanForPeripherals(withServices: [arduinoServiceUUID])
        }
        else {
            // iOS Device BLE is turned off and/or is not authorized
            print("BLE is powered off")
            let BLEOffAlert = UIAlertController(title: "\"Active Feedback Rowing\" Would Like to Use Bluetooth", message: "To allow \"Active Feedback Rowing\" to find and connect to the Active Feedback Device, please authorize Bluetooth permissions in your Privacy Settings", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default) { (action) in print(action) }
            BLEOffAlert.addAction(okayAction)
            present(BLEOffAlert, animated: true, completion: nil)
        }
    }
    
    // Search for peripheral and update state of arduinoPeripheral; then connect to the peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Print found peripheral to console
        print(peripheral)
        
        // Assign arduinoPeripheral to the found Arduino
        arduinoPeripheral = peripheral
        arduinoPeripheral.delegate = self
        
        // Stop scanning for peripherals
        centralManager.stopScan()
        
        // Connect to found peripheral
        centralManager.connect(arduinoPeripheral)
    }
    
    // If successful connection is established to Arduino, inform user
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Indicate connection status to console and user
        print("Successfully Connected to Arduino!")
        let deviceConnectedAlert = UIAlertController(title: "Successfully Connected to Active Feedback Device!", message: "", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default) { (action) in print(action) }
        deviceConnectedAlert.addAction(okayAction)
        present(deviceConnectedAlert, animated: true, completion: nil)
        
        // Discover services
        arduinoPeripheral.discoverServices(nil)
    }
    
    // Discover peripheral services; print peripheral service to console (not for user, just developer)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // Set variables to hold pressure, x acceleration, and x gyrometer values
    private var pressureCharacteristic: CBCharacteristic!
    private var yAccelCharacteristic: CBCharacteristic!
    private var xGyroCharacteristic: CBCharacteristic!
    
    // Discover the peripheral's characteristics; display peripheral's characteristic uuid to console (not for user, just developer)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        print("Found \(characteristics.count) characteristics!")
        
        // Assign pressureCharacteristic, xAccelCharacteristic, and xGyroCharacteristic
        for characteristic in characteristics {
            if characteristic.uuid.isEqual(pressureCharacteristicUUID) {
                pressureCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: pressureCharacteristic!)
                peripheral.readValue(for: characteristic)
                
                print("Pressure Characteristic UUID: \(pressureCharacteristic.uuid)")
            }
            
            if characteristic.uuid.isEqual(yAccelCharacteristicUUID) {
                yAccelCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: yAccelCharacteristic!)
                peripheral.readValue(for: characteristic)
                
                print("Y Acceleration Characteristic UUID: \(yAccelCharacteristic.uuid)")
            }
            
            if characteristic.uuid.isEqual(xGyroCharacteristicUUID) {
                xGyroCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: xGyroCharacteristic!)
                peripheral.readValue(for: characteristic)
                
                print("X Gyroscope Characteristic UUID: \(xGyroCharacteristic.uuid)")
            }
        }
    }
    
    // MARK: READ AND PUSH DATA
    // Assign variables to hold received values
    var receivedPressure: Float?
    var receivedAcceleration: Float?
    var receivedGyroscope: Float?
    // Assign arrays to hold received values
    var pressureArray = [Float]()
    var accelerationArray = [Float]()
    var gyroscopeArray = [Float]()
    var erroneousPressureDuration = 0
    var erroneousTimingDuration = 0
    // Convert bytes into float
    func floatValue(data: Data) -> Float {
        let floatNb:Float = data.withUnsafeBytes { $0.load(as: Float.self) }
        return floatNb
    }
    // Read in each characteristic and convert into float; Once read in, display it to user and store to cloud database
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // For each characteristic, check which it corresponds to (pressure, accel, or gyro); then, read the value and convert it into a float; then present it to the user
        if characteristic == pressureCharacteristic {
            // Deserialize and read in pressure value
            guard let characteristicData = characteristic.value else { return }
            receivedPressure = abs(floatValue(data: characteristicData))
            
            // Display pressure to user
            var appliedPressure = 5.1581 * exp(1.7726 * (receivedPressure ?? 0.0))
            appliedPressure = round((appliedPressure) * 100) / 100.0
            PressureDisplay.text = appliedPressure.description
            
            // Append pressure to array
            pressureArray.append(receivedPressure ?? 0.0)
        }
        if characteristic == yAccelCharacteristic {
            // Deserialize and read in acceleration value
            guard let characteristicData = characteristic.value else { return }
            receivedAcceleration = abs(floatValue(data: characteristicData))
            receivedAcceleration = round((receivedAcceleration ?? 0.0) * 100) / 100.0
            
            // Display acceleration to user
            AccelerationDisplay.text = receivedAcceleration?.description
            
            // Append acceleration to array
            accelerationArray.append(receivedAcceleration ?? 0.0)
        }
        if characteristic == xGyroCharacteristic {
            // Deserialize and read in gyroscope value
            guard let characteristicData = characteristic.value else { return }
            receivedGyroscope = abs(floatValue(data: characteristicData))
            receivedGyroscope = round((receivedGyroscope ?? 0.0) * 100) / 100.0
            
            // Display gyroscope to user
            GyroscopeDisplay.text = receivedGyroscope?.description
            
            // Append gyroscope to array
            gyroscopeArray.append(receivedGyroscope ?? 0.0)
        }
        
        
        // Process received data and set UILabel Color according to technique based on final data analysis result
        if receivedPressure! > 1.6 {
            // Make background red
            PressureDisplay.backgroundColor = UIColor.systemRed.withAlphaComponent(0.4)
            
            // Increment numPressureErrors
            erroneousPressureDuration = erroneousPressureDuration + 1
        } else {
            // Make background green
            PressureDisplay.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.4)
        }
        
        if receivedAcceleration ?? 0.0 < 0.6 && receivedGyroscope ?? 0.0 > 150.0 {
            // Make background red
            AccelerationDisplay.backgroundColor = UIColor.systemRed.withAlphaComponent(0.4)
            GyroscopeDisplay.backgroundColor = UIColor.systemRed.withAlphaComponent(0.4)
            
            // Incremend numTimingErrors
            erroneousTimingDuration = erroneousTimingDuration + 1
        } else {
            AccelerationDisplay.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.4)
            GyroscopeDisplay.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.4)
        }
        
        // Push arrays to Firebase (realtime database)
        pushData(pressure: pressureArray, acceleration: accelerationArray, gyroscope: gyroscopeArray, pressureErrorDuration: erroneousPressureDuration, timingErrorDuration: erroneousTimingDuration)
    }
    
    @objc func pushData(pressure: Array<Float>, acceleration: Array<Float>, gyroscope: Array<Float>, pressureErrorDuration: Int, timingErrorDuration: Int) {
        // Create data structure to store pressure array, acceleration array, gyroscope array
        let dataStructure: [String: Any] = [
            "Pressure Values": pressure as NSObject,
            "Acceleration Values": acceleration as NSObject,
            "Gyroscope Values": gyroscope as NSObject,
            "Duration of Erroneous Pressure Application": pressureErrorDuration as NSInteger,
            "Duration of Erroneous Timing": timingErrorDuration as NSInteger
        ]
        
        // Push to dataStructure to Firebase
        coreDatabase.child("All_User_Data").child("\(sessionNumber ?? 0)").setValue(dataStructure)
    }
    
    
    
    
    // MARK: LOCATION TRACKING
    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    
    // Video for Map Kit tutorial: https://www.youtube.com/watch?v=SayMogu530A --> USE THIS WHEN INSERTING IN THE FINAL COMMENTS FOR THE CODE
    @IBOutlet weak var mapKit: MKMapView!
    
    // Initialize CL Location Manager; handle exception if user denies location services
    private func configureLocationServices() {
        locationManager.delegate = self
        
        let status = CLLocationManager.authorizationStatus()
        
        if status == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else if status == .authorizedAlways || status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: locationManager)
        }
    }
    
    // Show user location; use best accuracy for Location Manager
    private func beginLocationUpdates(locationManager: CLLocationManager) {
        mapKit.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    // Zoom to user location
    private func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D) {
        let zoomRegion = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
        
        mapKit.setRegion(zoomRegion, animated: true)
        
        mapKit.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true)
    }
    
    // Update user location and re-zoom to keep tracking user
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.first else { return }
        
        if currentCoordinate == nil {
            zoomToLatestLocation(with: latestLocation.coordinate)
        }
        
        currentCoordinate = latestLocation.coordinate
    }
    
    // If user authorizes location services, begin location services
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: manager)
        }
    }
    
    // Every time this button is pressed, the map will center on the user's location
    @IBAction func centerLocation(_ sender: Any) {
        // Force map to track user location; allow user to see large map overview
        mapKit.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true)
    }
    
}
