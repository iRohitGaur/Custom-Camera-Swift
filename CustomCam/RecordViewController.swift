//
//  RecordViewController.swift
//  CustomCam
//
//  Created by RG on 1/25/20.
//  Copyright © 2020 RG. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Photos

class RecordViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    var timer = Timer()
    var seconds = 0
    var minutes = 0
    var hours = 0
    
    let captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice?
    var videoFileOutput:AVCaptureMovieFileOutput?
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //requestForCameraAndLibraryAccess()
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        startRunningCaptureSession()
        setUserDefaults()
        setTapGesture()
        
        NotificationCenter.default.addObserver(self, selector: #selector(customStop(_:)), name: NSNotification.Name(rawValue: "stop"), object: nil)
     }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIDevice.current.isProximityMonitoringEnabled = true
        //UIDevice.current.proximityState = true
        let outputPath = NSTemporaryDirectory() + "output.mov"
        let outputFileURL = URL(fileURLWithPath: outputPath)
        videoFileOutput?.startRecording(to: outputFileURL, recordingDelegate: self)
        
        timer = Timer.scheduledTimer(timeInterval: 1, target:self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    @objc func handleTap (gesture: UITapGestureRecognizer) {
        UserDefaults.standard.set(nameField.text, forKey: "name")
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        UserDefaults.standard.set(nameField.text, forKey: "name")
        view.endEditing(true)
        return true
    }
    
    @objc func updateCounter() {
        seconds += 1
        if (seconds < 60) {
            timerLabel.text = String(format:"%02d", minutes) + ":" + String(format: "%02d", seconds)
            if (hours > 0) {
                timerLabel.text = String(format:"%02d", hours) + ":" + String(format:"%02d", minutes) + ":" + String(format: "%02d", seconds)
            }
        } else {
            minutes += 1
            seconds = 0
        }
        if (minutes > 59) {
            hours += 1
            minutes = 0
            seconds = 0
            timerLabel.text = String(format:"%02d", hours) + ":" + String(format:"%02d", minutes) + ":" + String(format: "%02d", seconds)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.high
    }
    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        let preferences = UserDefaults.standard
        if (preferences.object(forKey: "frontCam") as! String == "true") {
            currentDevice = frontCamera
        } else {
            currentDevice = backCamera
        }
        
        
    }
    
    func setupInputOutput() {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            captureSession.addInput(captureDeviceInput)
            videoFileOutput = AVCaptureMovieFileOutput()
            captureSession.addOutput(videoFileOutput!)
        } catch {
            print(error)
        }
    }
    
    func setupPreviewLayer() {
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraPreviewLayer?.frame = self.view.frame
        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
    }
    
    func startRunningCaptureSession() {
        captureSession.startRunning()
    }
    
    func setUserDefaults() {
        if (UserDefaults.standard.string(forKey: "name") == nil || UserDefaults.standard.string(forKey: "name") == "") {
            nameField.text = "Mom"
        } else {
            nameField.text = UserDefaults.standard.string(forKey: "name")
        }
    }
    
    func setTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:)))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Action methods
    
    @objc func customStop(_ sender: Any) {
        videoFileOutput?.stopRecording()
    }
    
    @IBAction func capture(sender: UIButton) {
        videoFileOutput?.stopRecording()
    }
    
    
    // MARK: - AVCaptureFileOutputRecordingDelegate methods
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error != nil {
            print(error ?? "default")
            return
        }
        
        //performSegue(withIdentifier: "playVideo", sender: outputFileURL)
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        }) { saved, error in
            print("err: ", error ?? "default message")
            if saved {
                print("saved")
            }
            //exit(0)
            DispatchQueue.main.async {
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playVideo" {
            let videoPlayerViewController = segue.destination as! AVPlayerViewController
            let videoFileURL = sender as! URL
            videoPlayerViewController.player = AVPlayer(url: videoFileURL)
        }
    }
}
