//
//  ViewController.swift
//  accel_HK
//
//  Created by gunuk on 2018. 1. 3..
//  Copyright © 2018년 gunuk. All rights reserved.
//

import UIKit
import SwiftSocket
import CoreMotion
import WatchConnectivity
import HealthKit

class ViewController: UIViewController, WCSessionDelegate {
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print ("error in sessionDidBecomeInactive")
    }
    public func sessionDidDeactivate(_ session: WCSession) {
        print ("error in SesssionDidDeactivate")
    }
    public func session(_ session: WCSession, activationDidCompleteWith    activationState: WCSessionActivationState, error: Error?) {
        print ("error in activationDidCompleteWith error")
    }
    
    @IBOutlet weak var gyro_x: UILabel!
    @IBOutlet weak var gyro_y: UILabel!
    @IBOutlet weak var gyro_z: UILabel!
    @IBOutlet weak var accel_x: UILabel!
    @IBOutlet weak var accel_y: UILabel!
    @IBOutlet weak var accel_z: UILabel!
    @IBOutlet weak var connect_btn: UIButton!
    @IBOutlet weak var btn_start: UIButton!
    
    var motion = CMMotionManager()
    let host = "127.0.0.1"
    let port = 25555
    var client: TCPClient?
    var num:Int = 1
    var flag : Int = 0  //connect 버튼 flag
    var flag1 : Int = 0 //start 버튼 flag
    var timer = Timer()
    var session: WCSession!
    var data: String = ""   // watch에서 받은 데이터 문자열 전체
    var data1: String = ""  // watch에서 받은 데이터 문자열 정리
    var signal: String = ""  // start signal 확인
    var Index: String = ""  // Index 구별
    var Index3: String = "" // Index 구별
    var count : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        client = TCPClient(address: "127.0.0.1", port: 25555)
    }

    private func sendRequest(string: String, using client: TCPClient) -> String? {
        appendToTextField(string: "Sending data ...")
        
        switch client.send(string: string) {
        case .success:
            appendToTextField(string: "Success")
            return nil
        case .failure(let error):
            appendToTextField(string: String(describing: error))
            return nil
        }
    }
    
    private func appendToTextField(string: String) {
        print(string)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print(String(count) + "Memeory Warning")
    }
    override func viewDidAppear(_ animated: Bool) {
        
        motion.accelerometerUpdateInterval = 0.01
        motion.gyroUpdateInterval = 0.01
        motion.startAccelerometerUpdates(to: OperationQueue.current!){(accelerometerData: CMAccelerometerData?, NSError) -> Void in
            self.outputAccelerationData(acceleration: accelerometerData!.acceleration)
            if(NSError != nil){
                print("\(NSError)")
            }
            
        }
        motion.startGyroUpdates(to: OperationQueue.current!,withHandler: { (gyroData:CMGyroData?, NSError) -> Void in
            self.outputGyroData(rotation: gyroData!.rotationRate)
            if(NSError != nil){
                print("\(NSError)")
            }
        })
        
        if WCSession.isSupported(){
            self.session = WCSession.default
            self.session.delegate = self
            self.session.activate()
        }
    }
    func outputAccelerationData(acceleration: CMAcceleration){
        accel_x.text = "\(acceleration.x)"
        accel_y.text = "\(acceleration.y)"
        accel_z.text = "\(acceleration.z)"
    }
    func outputGyroData(rotation:CMRotationRate){
        gyro_x.text = "\(rotation.x)"
        gyro_y.text = "\(rotation.y)"
        gyro_z.text = "\(rotation.z)"
    }
    
    //watch에서 아이폰으로 받은 데이터
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        data = (message["b"]! as? String)!  //51,o or connect
        data1 = "\(data.substring(from: data.index(data.startIndex, offsetBy: 1)))" //1,o
        signal = "\(data.substring(to: data.index(after: data.startIndex)))" //5
        
        Index = "\(data1.substring(to: data1.index(after: data1.startIndex)))" //1
        Index3 = "\(data.substring(from: data.index(data.startIndex, offsetBy: 3)))"    // o
        
        if data == "Connect"{
            flag = 0
            server_connect()
            
        }
            
        else if data == "Disconnect"{
            flag = 1
            sendRequest(string: String(count)+"\n", using: client!)
            server_connect()
        }
        
        if signal == "5"{
            
            sendRequest(string: Index+","+Index3+","+gyro_x.text!+","+gyro_y.text!+","+gyro_z.text!+","+accel_x.text!+","+accel_y.text!+","+accel_z.text!+"\n", using: client!)
            print(Index3)
            count += 1
        }
    }
  
    func server_connect(){
        
        if flag == 0{
            print("flag")
            guard let client = client else {return}
            
            switch client.connect(timeout:1000){
            case .success:
                appendToTextField(string: "Connected to host \(client.address)")
                
            case .failure(let error):
                appendToTextField(string: String(describing: error))
            }
            flag = 2
            
        }
        else if flag == 1{
            client?.close()
            flag = 0
        }
        
        return
    }

}

