//
//  CommonUtility.swift
//  QRCodeScannerProject
//
//  Created by Mahendra Naidu  on 08/04/25.

import UIKit
import AVFoundation
open class CommonUtility: NSObject {
    
    /// Checks camera permission and handles various cases: granted, denied, or not determined.
    /// - Parameter viewController: The view controller to present alerts if needed.
    /// - Parameter completion: Callback with the result of the permission check.
    class func checkCameraPermission(on viewController: UIViewController, completion: @escaping (_ permission: Bool) -> Void) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
        case .authorized:
            // Permission granted, proceed with camera usage
            completion(true)
            
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        completion(true)
                    } else {
                        // Permission denied, show alert
                        showCameraAccessDeniedAlert(on: viewController)
                        completion(false)
                    }
                }
            }
            
        case .denied, .restricted:
            // Permission denied or restricted, show alert
            showCameraAccessDeniedAlert(on: viewController)
            completion(false)
            
        @unknown default:
            // Handle unexpected cases
            completion(false)
        }
    }
    
    /// Shows an alert when camera access is denied, allowing the user to navigate to settings.
    /// - Parameter viewController: The view controller to present the alert.
    private class func showCameraAccessDeniedAlert(on viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Camera Access Denied",
            message: "Please allow camera access in Settings to use this feature.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        })
        
        DispatchQueue.main.async {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
}



