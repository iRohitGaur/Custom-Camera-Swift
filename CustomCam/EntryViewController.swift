//
//  EntryViewController.swift
//  CustomCam
//
//  Created by RG on 1/25/20.
//  Copyright © 2020 RG. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class EntryViewController: UIViewController {

    var flag1 = 1
    var flag2 = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        requestForCameraAndLibraryAccess()
        //UIDevice.current.isProximityMonitoringEnabled = false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    @IBAction func callButton(_ sender: Any) {
        let preferences = UserDefaults.standard
        preferences.set("false", forKey: "frontCam")
        goToNextScreen()
    }
    
    @IBAction func callFrontCam(_ sender: Any) {
        let preferences = UserDefaults.standard
        preferences.set("true", forKey: "frontCam")
        goToNextScreen()
    }
    
    func goToNextScreen() {
        if (flag1 == 0 && flag2 == 0) {
            self.performSegue(withIdentifier: "callScreen", sender: nil)
        } else {
            alertUser(withMessage: "Please Grant Access of Camera and Photo Library in order to proceed further. Go to Settings > rPhone.")
        }
    }
    
    func requestForCameraAndLibraryAccess() {
        //Camera
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                //access granted
                self.flag1 = 0
            } else {
                self.flag1 = 1
            }
        }
        
        //Photos
        PHPhotoLibrary.requestAuthorization({status in
            if status == .authorized{
                self.flag2 = 0
            } else {
                self.flag2 = 1
            }
        })
    }

    func alertUser(withMessage: String) {
        let alertController = UIAlertController(title: "Grant Access!", message: withMessage, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
