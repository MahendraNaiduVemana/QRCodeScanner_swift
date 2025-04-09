//
//  ViewController.swift
//  QrCodeScanner
//
//  Created by Mahendra Naidu  on 08/04/25.
//

import UIKit
import SafariServices

// This ViewController class handles the main functionality of the app, including navigation and QR code scanning.
class ViewController: UIViewController, SFSafariViewControllerDelegate {
    // Outlet for the button that triggers QR code scanning.
    @IBOutlet var clickBtn: UIButton!
    
    // Called after the view has been loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()
        // Ensure the navigation bar is visible.
        self.navigationController?.isNavigationBarHidden = false
    }
    
    // Action triggered when the button is clicked.
    @IBAction func clickBtnAction(_ sender: Any) {
        // Check if the app is running on a real device (not a simulator).
        if !Platform.isSimulator {
            // Check for camera permissions before proceeding.
            CommonUtility.checkCameraPermission(on: self) { permissionGranted in
                if permissionGranted {
                    // If permission is granted, instantiate the QRViewController for scanning.
                    let vc = QRViewController.instance()
                    
                    // Closure to handle the scanned QR code.
                    vc.getQRCode = { code in
                        // Check if the scanned code is a valid URL.
                        if let url = URL(string: code ?? ""), UIApplication.shared.canOpenURL(url) {
                            // If valid, open the URL in SafariViewController.
                            let safariVC = SFSafariViewController(url: url)
                            safariVC.delegate = self // Set the delegate to handle Safari actions.
                            self.present(safariVC, animated: true, completion: nil)
                        } else {
                            // Log an error if the QR code does not contain a valid URL.
                            print("The QR code does not contain a valid URL.")
                        }
                    }
                    // Push the QRViewController onto the navigation stack.
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    // Log an error if camera permission is denied or restricted.
                    print("Camera permission denied or restricted.")
                }
            }
        } else {
            print("QR code scanning is not supported on simulator devices.")
        }
    }
}
