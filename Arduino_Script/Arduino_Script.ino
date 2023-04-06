// Jay Swaminarayan!

// Import packages
#include <ArduinoBLE.h>
#include <Arduino_LSM6DS3.h>

// Initialize pins
int pressurePin = A7;

// Initialize reference resistor
float referenceResistance = 10000.0;

// Initialize variables to store pressure voltages
float previousPressureVoltage = 0.0;
float currentPressureVoltage = 0.0;

// Initialize variables to store acceleration values and gyroscope values
float xAccel, yAccel, zAccel;
float xGyro, yGyro, zGyro;

// Generate UUIDs for each characteristic
BLEService arduinoService("5CBF9D99-46B2-4255-9F44-73B76D5353B8");
BLEFloatCharacteristic pressureCharacteristic("FA571202-D0A0-4477-B71B-4A5E70D3477C", BLERead | BLENotify);
BLEFloatCharacteristic yAccelCharacteristic("78211F0E-B738-4F17-BBB7-1EB3BAAD02D4", BLERead | BLENotify);
BLEFloatCharacteristic xGyroCharacteristic("23B0357D-0FBD-4032-BD07-55445E471E38", BLERead | BLENotify);

bool connected_message;
bool waiting_message;

void setup() {
  // Begin Serial Communication
  Serial.begin(115200);
  delay(2000);

  // Initiate BLE Service and Characteristics
  if (!BLE.begin()) {
    Serial.println("Did not start BLE");
    while(1);  
  }
  Serial.println("BLE Startup Successful");
  BLE.setLocalName("Active Feedback Rowing Device");
  BLE.setDeviceName("Active Feedback Rowing Device");
  BLE.setAdvertisedService(arduinoService);
  arduinoService.addCharacteristic(pressureCharacteristic);
  arduinoService.addCharacteristic(yAccelCharacteristic);
  arduinoService.addCharacteristic(xGyroCharacteristic);
  BLE.addService(arduinoService);
  BLE.advertise();
  Serial.println("BLE Device waiting for connections...");
  
  // Determine previous pressure voltage
  float unconvertedValues = analogRead(pressurePin);

  previousPressureVoltage = unconvertedValues * (3.3 / 4095.0);

  // Initiate Arduino's native IMU and display sampling rate
  if (!IMU.begin()) {
    Serial.println("Did not start IMU");  
  }
  Serial.println("Native IMU Startup Successful");
  Serial.print("Native IMU Sampling Rate: ");
  Serial.println(IMU.accelerationSampleRate());
  
}

void loop() {
  //------------------------------------------------------------------------------------------------------------------------------
  
  // HANDLE BLE CONNECTION
  BLEDevice central = BLE.central();

  if (!central) {
      connected_message = 0;
      if (!waiting_message) {
        waiting_message = 1;
        Serial.println("Waiting for BLE connection...");
      }
      delay(100);
  } else {
      waiting_message = 0;
      if (!connected_message) {
        connected_message = 1;
        Serial.print("Connected: ");
        Serial.println(central.address());
      }  
  }

  // ------------------------------------------------------------------------------------------------------------------------------
  
  // SET ANALOG READ RESOLUTION
  analogReadResolution(12);

  // ------------------------------------------------------------------------------------------------------------------------------

  // HANDLE PRESSURE MEASUREMENTS
  // Convert ADC to Voltages, compute the time average of pressure voltage for the two latest measurements, and write to the pressure characteristic
  float unconvertedValues = analogRead(pressurePin);
  float currentPressureVoltage = unconvertedValues * (3.3 / 4095.0);
  float averagedPressureVoltage = (previousPressureVoltage + currentPressureVoltage) / 2.0;
  
  pressureCharacteristic.writeValue(averagedPressureVoltage);

  
  
  // NOTE: Critical applied pressure is approximately 90 kPa; this corresponds to an output voltage of 1.6 V (determined via interview)
  // Use output voltage measurements for logic structure evaluation since voltage measurements are more stable than the converted pressure values

  // Set the previous voltage to the current voltage
  previousPressureVoltage = currentPressureVoltage;

  // ------------------------------------------------------------------------------------------------------------------------------

  // HANDLE ACCELERATION MEASUREMENTS
  // Handle exception in case that native IMU is unavailable; if available, read and print
  if (IMU.accelerationAvailable()) {
    IMU.readAcceleration(xAccel, yAccel, zAccel);

    Serial.print(yAccel);
    Serial.print("\t");
  }
  
  if (IMU.gyroscopeAvailable()) {
    IMU.readGyroscope(xGyro, yGyro, zGyro);

    Serial.println(xGyro);
  }

  // Write acceleration and gyroscope measurements to their respective characteristics
  yAccelCharacteristic.writeValue(yAccel);
  xGyroCharacteristic.writeValue(xGyro);

  // NOTE: For the user suggestion, if xAccel AND xGyro are simultaneously too large (at the same time), then tell the user to adjust their row timing

  delay(100);
}
