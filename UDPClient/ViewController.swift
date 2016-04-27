//
//  ViewController.swift
//  UDPClient
//
//  Created by Hongyi Guo on 03/25/2016.
//  Copyright (c) 2016 Hongyi Guo. All rights reserved.
//

import UIKit
import CocoaAsyncSocket
import MapKit
import CoreLocation

class ViewController: UIViewController, GCDAsyncUdpSocketDelegate, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var hostTextField: UITextField!
    @IBOutlet weak var localPortTextField: UITextField!
    @IBOutlet weak var remotePortTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var answerTextView: UITextView!
    
    /*                      Map Variables                        */
    
    @IBOutlet weak var Map_show: MKMapView!
    var locationManager = CLLocationManager()
    
    var latitude:CLLocationDegrees = 32.984865
    var longitude:CLLocationDegrees = -96.748277
    
    var latDelta:CLLocationDegrees = 0.01 //zoom
    var lonDelta:CLLocationDegrees = 0.01
    
    var annotation = MKPointAnnotation()
    

    
    
    
    

    
    
    
    
    
    /************************************************************/
    
    
    
    
    
    @IBOutlet weak var localIP: UILabel!
    
    var _socket: GCDAsyncUdpSocket?
    
    var socket: GCDAsyncUdpSocket? {
        get {
            if _socket == nil {
                guard let port = UInt16(localPortTextField.text ?? "0") where port > 0 else {
                    log(">>> Unable to init socket: local port unspecified.")
                    return nil
                }
                let sock = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
                do {
                    try sock.bindToPort(port)
                    try sock.beginReceiving()
                } catch let err as NSError {
                    log(">>> Error while initializing socket: \(err.localizedDescription)")
                    sock.close()
                    return nil
                }
                _socket = sock
            }
            return _socket
        }
        set {
            _socket?.close()
            _socket = newValue
        }
    }

    override func viewDidLoad() {
        /*                Get Local IP             */
        let ipUtil = IPAddress()
        self.localIP.text = ipUtil.getIPAddress(true)
        
        /******************************************/
        //saveDefaults()
        
        super.viewDidLoad()
        
        /*                For Map                 */
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        
        Map_show.setRegion(region, animated: false)
        
        annotation.coordinate = location
        
        annotation.title = "Car Location"
        
        Map_show.addAnnotation(annotation)
        
        /*    long press action      */
        
        let uilpgr = UILongPressGestureRecognizer(target:self,action:"action:")
        
        uilpgr.minimumPressDuration = 1.5
        
        Map_show.addGestureRecognizer(uilpgr)
        
        /******************************************/
        
        loadDefaults()
    }
    
    func locationManager(manager:CLLocationManager!,didUpdateLocations locations:[CLLocation]){
        //print(locations)
        
        var userLocation:CLLocation = locations[0]
        
        var latitude = userLocation.coordinate.latitude
        
        var longitude = userLocation.coordinate.longitude
        
        var latDelta:CLLocationDegrees = 0.01 //zoom
        var lonDelta:CLLocationDegrees = 0.01
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        
        self.Map_show.setRegion(region, animated: false)   //if true,map will automatic move when location updated
        
    }
    
    
    func action(gestureRecognizer: UIGestureRecognizer){
        //print("Gesture Recognized")
        let touchPoint = gestureRecognizer.locationInView(self.Map_show)
        
        let newCoordinate:CLLocationCoordinate2D = Map_show.convertPoint(touchPoint, toCoordinateFromView: self.Map_show)
        
        var annotation = MKPointAnnotation()
        
        annotation.coordinate = newCoordinate
        
        annotation.title = "Place to Move"
        
        Map_show.addAnnotation(annotation)
        
    }
    
    
    deinit {
        socket = nil
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func log(text: String) {
        answerTextView.text = text + "\n" + answerTextView.text
    }


    
    
    @IBAction func sendPacket(sender: AnyObject) {
        //testing
        //loadDefaults()
        print("================")
        print("local port:")
        print(self.localPortTextField.text)
        print("remote IP:")
        print(self.hostTextField.text)
        print("remote port:")
        print(self.remotePortTextField.text)
        print("----------------")
        
        guard let str = messageTextField.text where !str.isEmpty else {
            log(">>> Cannot send packet: please enter data to send")
            return
        }
        guard let host = hostTextField.text where !host.isEmpty else {
            log(">>> Cannot send packet: GPS Car IP not specified")
            return
        }
        guard let port = UInt16(remotePortTextField.text ?? "0") where port > 0 else {
            log(">>> Cannot send packet: no GPS Car port specified")
            return
        }
        
        guard socket != nil else {
            return
        }
        socket?.sendData(str.dataUsingEncoding(NSUTF8StringEncoding), toHost: host, port: port, withTimeout: 2, tag: 0)
        log("Data sent: \(str)")
        self.view.endEditing(true)
        saveDefaults()
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
        guard let stringData = String(data: data, encoding: NSUTF8StringEncoding) else {
            log(">>> Data received, but cannot be converted to String")
            return
        }
        log("Data received: \(stringData)")
        /*                  Received Data Operate here                 */
        //var latitude:Float =
        //var longitude:Float =
        
        /***************************************************************/
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func loadDefaults() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let host = userDefaults.stringForKey("host") {
            hostTextField.text = host
        }
        if let localPort = userDefaults.stringForKey("localPort") {
            localPortTextField.text = localPort
        }
        if let remotePort = userDefaults.stringForKey("remotePort") {
            remotePortTextField.text = remotePort
        }
        if let message = userDefaults.stringForKey("message") {
            messageTextField.text = message
        }
    }
    
    private func saveDefaults() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(hostTextField.text, forKey: "host")
        userDefaults.setObject(localPortTextField.text, forKey: "localPort")
        userDefaults.setObject(remotePortTextField.text, forKey: "remotePort")
        userDefaults.setObject(messageTextField.text, forKey: "message")
        userDefaults.synchronize()
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        sendPacket(textField)
        return true
    }

}

