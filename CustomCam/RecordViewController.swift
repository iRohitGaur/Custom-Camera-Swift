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

class RecordViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate  {
    
    @IBOutlet weak var recordButton: UIButton!
    
    let captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice?
    var videoFileOutput:AVCaptureMovieFileOutput?
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
    var cameraParentView = UIView()
    
    private var panGesture: UIPanGestureRecognizer?
    private var pinchGesture: UIPinchGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //requestForCameraAndLibraryAccess()
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        startRunningCaptureSession()
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        view.isUserInteractionEnabled = true
        panGesture?.delegate = self
        view.addGestureRecognizer(panGesture!)
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinchGesture?.delegate = self
        view.addGestureRecognizer(pinchGesture!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(customStop(_:)), name: NSNotification.Name(rawValue: "stop"), object: nil)
     }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        cameraParentView.frame = CGRectFromString("{{50,50},{200,260}}")
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraPreviewLayer?.frame = cameraParentView.frame
        self.view.layer.insertSublayer(cameraPreviewLayer!, above: self.view.layer)
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
            print("err: ", error!)
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        }) { saved, error in
            if error != nil {
                print("err: ", error!)
                return
            }
            if saved {
                print("saved")
            }
            DispatchQueue.main.async {
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    // MARK: - Gesture Methods
    @objc func handlePan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: cameraParentView)
        cameraParentView.center = CGPoint(x: cameraParentView.center.x + translation.x, y: cameraParentView.center.y + translation.y)
        cameraPreviewLayer?.frame = cameraParentView.frame
        sender.setTranslation(CGPoint.zero, in: cameraParentView)
    }
    
    @objc func handlePinch(sender: UIPinchGestureRecognizer) {
        cameraParentView.transform = cameraParentView.transform.scaledBy(x: sender.scale, y: sender.scale)
        cameraPreviewLayer?.frame = cameraParentView.frame
        sender.scale = 1
    }
    
    //MARK:- UIGestureRecognizerDelegate Methods
    @objc func gestureRecognizer(_: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
        return true
    }
}
