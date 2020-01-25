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
    
    @IBOutlet weak var recordButton: UIButton!
    
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
}
