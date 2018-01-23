//
//  InterfaceController.swift
//  accel_HK WatchKit Extension
//
//  Created by gunuk on 2018. 1. 3..
//  Copyright © 2018년 gunuk. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion
import WatchConnectivity
import HealthKit

class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate, WCSessionDelegate {
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            workoutDidStart(date)
        case .ended:
            workoutDidEnd(date)
        default:
            print("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
         print("Workout error")
    }
    
    
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    let motion = CMMotionManager()
    var session: WCSession!
    var accel_X: String = ""
    var accel_Y: String = ""
    var accel_Z: String = ""
    var timer = Timer()
    var flag: Int = 0
    var start: String = ""
    var status: String = ""
    var Index: String = ""
    var count: Int = 0
    var i: Int = 0
    var flag1 : Int = 0
    var Heart : String = "0.0"
    let healthStore = HKHealthStore()
    
    //State of the app - is the workout activated
    var workoutActive = false
    
    // define the activity type and location
    var HKsession : HKWorkoutSession?
    let heartRateUnit = HKUnit(from: "count/min")
    //var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    var currenQuery : HKQuery?
    
    @IBOutlet var Error_Handler: WKInterfaceLabel!
    @IBOutlet var BPM: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        /*if(context == nil){
            print("context error")
        }else{
            status = context as! String
            print("\(status)")
        }*/
        // Configure interface objects here.
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if WCSession.isSupported(){
            self.session = WCSession.default
            self.session.delegate = self
            self.session.activate()
        }
        guard HKHealthStore.isHealthDataAvailable() == true else {
            Error_Handler.setText("not available")
            return
        }
        
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            displayNotAllowed()
            return
        }
        
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success == false {
                self.displayNotAllowed()
            }
        }
        
    }
    
    func displayNotAllowed() {
        Error_Handler.setText("not allowed")
    }
    
    func updateHeartRate(_ samples: [HKSample]?) {

        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        guard let sample = heartRateSamples.first else{return}
        let Hvalue = sample.quantity.doubleValue(for: self.heartRateUnit)
        self.BPM.setText(String(UInt16(Hvalue)))
        self.Heart = String(UInt16(Hvalue))
        
    }
    
    func SensorData(){
        
        if (self.workoutActive) {
            //finish the current workout
            self.workoutActive = false
            if let workout = self.HKsession {
                self.healthStore.end(workout)
            }
        } else {
            //start a new workout
            self.workoutActive = true
            self.startWorkout()
        }
        
        motion.accelerometerUpdateInterval = 0.01
        motion.startAccelerometerUpdates(to: OperationQueue.current!){(accelerometerData:CMAccelerometerData?, NSError) -> Void in
            self.outputAccelerationData(acceleration: accelerometerData!.acceleration)
            
        
            if(NSError != nil){
                self.Error_Handler.setText("\(NSError)")
                print("\(NSError)")
            }
            else{
                
                self.start = "5"
                if WCSession.isSupported(){
                    self.count += 1
                    
                    self.session.sendMessage(["b":"\(self.start)"+"1"+","+"\(self.Heart)"+","+"\(self.accel_X)"+","+"\(self.accel_Y)"+","+"\(self.accel_Z)"], replyHandler: nil, errorHandler: nil)
                    
                    print("\(self.start)"+"\(self.status)"+","+"\(self.Heart)"+","+"\(self.accel_X)"+","+"\(self.accel_Y)"+","+"\(self.accel_Z)"+","+"\(self.count)")
                    
                }
                
                self.Error_Handler.setText("Sensing")
            }
        }
        
        
        
        if flag == 0{
            sensor_Btn.setTitle("Stop")
            flag = 1
            
        }
            
        else{
            
            sensor_Btn.setTitle("Start")
            flag = 0
            start = "4"
            motion.stopAccelerometerUpdates()
            Error_Handler.setText("Stop")
            count = 0
        }
        
    }
    
    @IBOutlet var sensor_Btn: WKInterfaceButton!
    
    @IBAction func sendMessage_ToiPhone() {      //start button
        SensorData()
        
    }
    
    func outputAccelerationData(acceleration: CMAcceleration){
        accel_X = String(acceleration.x)
        accel_Y = String(acceleration.y)
        accel_Z = String(acceleration.z)
        
    }
    
    @IBOutlet var Connect_btn: WKInterfaceButton!
    @IBAction func ConnectButton() {
        if flag1 == 0{
            if WCSession.isSupported(){
                session.sendMessage(["b":"Connect"], replyHandler: nil, errorHandler: nil )
            }
            Error_Handler.setText("Connect")
            Connect_btn.setTitle("Disconnect")
            flag1 = 1
        }
        else{
            motion.stopAccelerometerUpdates()
            if WCSession.isSupported(){
                session.sendMessage(["b":"Disconnect"], replyHandler: nil, errorHandler: nil )
            
            }
            sensor_Btn.setTitle("Start")
            print("disconnect")
            Error_Handler.setText("Disconnect")
            Connect_btn.setTitle("Connect")
            healthStore.stop(self.currenQuery!)
            BPM.setText("---")
            HKsession = nil
            flag1 = 0
            i=0;
        }
    }
    
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
    }
    func workoutDidStart(_ date : Date) {
        if let query = createHeartRateStreamingQuery(date) {
            self.currenQuery = query
            healthStore.execute(query)
        } else {
            Error_Handler.setText("cannot start")
        }
    }
    
    func workoutDidEnd(_ date : Date) {
        healthStore.stop(self.currenQuery!)
        BPM.setText("---")
        HKsession = nil
    }
    
    // MARK: - Actions
    func startWorkout() {
        
        // If we have already started the workout, then do nothing.
        if (HKsession != nil) {
            return
        }
        
        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .crossTraining
        workoutConfiguration.locationType = .indoor
        
        do {
            HKsession = try HKWorkoutSession(configuration: workoutConfiguration)
            HKsession?.delegate = self
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        healthStore.start(self.HKsession!)
    }
    
    func createHeartRateStreamingQuery(_ workoutStartDate: Date) -> HKQuery? {
        
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return nil }
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictEndDate )
        //let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate])
        
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            //guard let newAnchor = newAnchor else {return}
            //self.anchor = newAnchor
            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            //self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
}

