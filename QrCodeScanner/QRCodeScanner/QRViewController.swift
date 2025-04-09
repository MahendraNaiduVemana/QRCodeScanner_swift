//
//  QRViewController.swift
//  QRCodeScannerProject
//
//  Created by Mahendra Naidu on 28/03/25.

import UIKit
import AVFoundation
import Vision

class QRViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // Properties for capturing QR codes
    var captureSession: AVCaptureSession! // Manages input and output for video capture
    var previewLayer: AVCaptureVideoPreviewLayer! // Displays camera feed
    var qrCodeFrameView: UIView! // Highlights detected QR code
    var errorLabel: UILabel! // Displays error messages to the user
    var qrFrame: CGRect = CGRect() // Frame for QR code scanning area
    var torchOn: Bool = false // Tracks the torch's current state
    
    // Factory method to create an instance of QRViewController
    class func instance() -> QRViewController {
        let vc = UIStoryboard.qrVC.instantiateViewController(withIdentifier: "QRViewController") as? QRViewController
        return vc!
    }
    
    // Callback for handling scanned QR code
    var getQRCode: ((_ code: String?) -> Void)?
    
    // Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        setupNavigationBar() // Sets up navigation bar appearance
        setupCaptureSession() // Initializes camera session for scanning
        setupQRCodeFrameView() // Configures visual frame around the QR code
        setupErrorLabel() // Configures error label for user feedback
        setupTorchButton() // Adds a button to toggle the torch/flashlight
        setupGalleryButton() // Adds a GalleryButton
    }
    
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Dynamically calculates the QR frame based on the screen size
        let width = self.view.bounds.width - 80
        qrFrame = CGRect(
            origin: CGPoint(x: (self.view.bounds.width - width) / 2,
                            y: (self.view.bounds.height - width) / 2),
            size: CGSize(width: width, height: width)
        )
        
        previewLayer.frame = qrFrame // Updates preview layer to match QR frame
        qrCodeFrameView.frame = qrFrame // Adjusts QR code highlight frame
        updateCornerBorders() // Updates border styles
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        DispatchQueue.global(qos: .userInitiated).async {
            if (self.captureSession?.isRunning == false) {
                self.captureSession.startRunning() // Starts the capture session
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global(qos: .userInitiated).async {
            if (self.captureSession?.isRunning == true) {
                self.captureSession.stopRunning() // Stops the capture session
            }
        }
    }
    
    // Updates visual corner borders for the QR scanning area
    func updateCornerBorders() {
        for subview in qrCodeFrameView.subviews {
            subview.removeFromSuperview()
        }
        addCornerBorders()
    }
    
    func setupTorchButton() {
        // Create the torch button
        let torchButton = UIButton(type: .custom)
        torchButton.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
        torchButton.tintColor = .white
        torchButton.backgroundColor = .white.withAlphaComponent(0.2)
        torchButton.layer.masksToBounds = true
        torchButton.layer.cornerRadius = 20
        torchButton.translatesAutoresizingMaskIntoConstraints = false
        torchButton.addTarget(self, action: #selector(toggleTorch), for: .touchUpInside)
        torchButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        torchButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // Create a label for the torch title
        let torchLabel = UILabel()
        torchLabel.text = "Torch"
        torchLabel.textColor = .white
        torchLabel.font = UIFont.systemFont(ofSize: 12)
        torchLabel.textAlignment = .center
        torchLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a stack view to hold the button and label
        let stackView = UIStackView(arrangedSubviews: [torchButton, torchLabel])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the stack view to the view
        view.addSubview(stackView)
        
        // Position the stack view
        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -60) // Adjusted for spacing
        ])
    }
    
    
    @objc func toggleTorch() {
        // Toggles the device's flashlight/torch
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            showError("Torch is not available on this device.")
            return
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = torchOn ? .off : .on // Toggles torch state
            torchOn.toggle() // Updates the torch state variable
            device.unlockForConfiguration()
        } catch {
            showError("Unable to access the torch.")
        }
    }
    
    func setupGalleryButton() {
        // Create the gallery button
        let galleryButton = UIButton(type: .custom)
        galleryButton.setImage(UIImage(systemName: "photo.fill"), for: .normal)
        galleryButton.tintColor = .white
        galleryButton.backgroundColor = .white.withAlphaComponent(0.2)
        galleryButton.layer.masksToBounds = true
        galleryButton.layer.cornerRadius = 20
        galleryButton.translatesAutoresizingMaskIntoConstraints = false
        galleryButton.addTarget(self, action: #selector(openGallery), for: .touchUpInside)
        galleryButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        galleryButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // Create a label for the gallery title
        let galleryLabel = UILabel()
        galleryLabel.text = "Upload QR"
        galleryLabel.textColor = .white
        galleryLabel.font = UIFont.systemFont(ofSize: 12)
        galleryLabel.textAlignment = .center
        galleryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a stack view to hold the button and label
        let stackView = UIStackView(arrangedSubviews: [galleryButton, galleryLabel])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the stack view to the view
        view.addSubview(stackView)
        
        // Position the stack view
        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 60) // Adjusted for spacing
        ])
    }
    
    
    @objc func openGallery() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let selectedImage = info[.originalImage] as? UIImage else {
            showError("Failed to select an image.")
            return
        }
        
        // Process the selected image for QR codes
        processImageForQRCode(selectedImage)
    }
    
    func processImageForQRCode(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            handleProcessingFailure(message: "Invalid image selected.")
            return
        }
        
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleProcessingFailure(message: "Failed to process image: \(error.localizedDescription)")
                return
            }
            
            guard let results = request.results as? [VNBarcodeObservation], let firstResult = results.first else {
                self.handleProcessingFailure(message: "Invalid QR code Try Again!!!")
                return
            }
            
            if let payload = firstResult.payloadStringValue {
                DispatchQueue.main.async {
                    self.found(code: payload)
                }
            } else {
                self.handleProcessingFailure(message: "Unable to read the QR code.")
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.handleProcessingFailure(message: "Error processing the image.")
                }
            }
        }
    }
    
    func handleProcessingFailure(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                self.navigationController?.popViewController(animated: true) // Navigate back to the previous screen
            }
            
            let uploadAgainAction = UIAlertAction(title: "Upload Again", style: .default) { _ in
                self.openGallery() // Reopen the gallery for another upload
            }
            
            alert.addAction(cancelAction)
            alert.addAction(uploadAgainAction)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // Sets up the camera capture session for scanning QR codes
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput) // Adds video input to session
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput) // Adds metadata output for QR codes
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr] // Specifies QR code type
        } else {
            failed()
            return
        }
        
        // Configures the preview layer to display the camera feed
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Starts the session in a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    // Handles capture session failure (e.g., unsupported device)
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported",
                                   message: "Your device does not support scanning a code from an item. Please use a device with a camera.",
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Ok", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    // Called when a QR code is successfully scanned
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        } else {
            showError("Something went wrong")
        }
    }
    
    // Displays error messages in the error label
    func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    // Callback for when a QR code is found
    func found(code: String) {
        self.getQRCode?(code)
        self.navigationController?.popViewController(animated: true)
    }
    
    // Configures the QR code frame view for highlighting detected codes
    func setupQRCodeFrameView() {
        qrCodeFrameView = UIView()
        qrCodeFrameView.backgroundColor = UIColor.clear
        view.addSubview(qrCodeFrameView)
        view.bringSubviewToFront(qrCodeFrameView)
        qrCodeFrameView.frame = qrFrame
        addCornerBorders()
    }
    
    // Configures error label appearance and position
    func setupErrorLabel() {
        errorLabel = UILabel()
        errorLabel.textColor = .red
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.font = UIFont.boldSystemFont(ofSize: 16)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)
        NSLayoutConstraint.activate([
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            errorLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        errorLabel.isHidden = true
    }
    
    // Sets up the custom navigation bar appearance
    func setupNavigationBar() {
        let titleView = UIView()
        titleView.backgroundColor = .clear
        
        let titleLabel = UILabel()
        titleLabel.text = "QRCodeScanner"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: titleView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor)
        ])
        
        self.navigationItem.titleView = titleView
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ]
        
        let backImage = UIImage(systemName: "arrow.left")?.withRenderingMode(.alwaysTemplate)
        let backButton = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(backButtonTapped))
        backButton.tintColor = .white
        self.navigationItem.leftBarButtonItem = backButton
        
        self.navigationController?.navigationBar.barTintColor = UIColor.clear
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // Adds corner borders to the QR code frame
    func addCornerBorders() {
        let cornerLength: CGFloat = 55.0
        let borderWidth: CGFloat = 2.0
        let spacing: CGFloat = -10.0 // Adjust spacing
        
        qrCodeFrameView.subviews.forEach { $0.removeFromSuperview() }
        
        // Top-left corner
        let topLeftVertical = UIView(frame: CGRect(x: spacing, y: spacing, width: borderWidth, height: cornerLength))
        let topLeftHorizontal = UIView(frame: CGRect(x: spacing, y: spacing, width: cornerLength, height: borderWidth))
        topLeftVertical.backgroundColor = .white
        topLeftHorizontal.backgroundColor = .white
        qrCodeFrameView.addSubview(topLeftVertical)
        qrCodeFrameView.addSubview(topLeftHorizontal)
        
        // Top-right corner
        let topRightVertical = UIView(frame: CGRect(x: qrFrame.width - borderWidth - spacing, y: spacing, width: borderWidth, height: cornerLength))
        let topRightHorizontal = UIView(frame: CGRect(x: qrFrame.width - cornerLength - spacing, y: spacing, width: cornerLength, height: borderWidth))
        topRightVertical.backgroundColor = .white
        topRightHorizontal.backgroundColor = .white
        qrCodeFrameView.addSubview(topRightVertical)
        qrCodeFrameView.addSubview(topRightHorizontal)
        
        // Bottom-left corner
        let bottomLeftVertical = UIView(frame: CGRect(x: spacing, y: qrFrame.height - cornerLength - spacing, width: borderWidth, height: cornerLength))
        let bottomLeftHorizontal = UIView(frame: CGRect(x: spacing, y: qrFrame.height - borderWidth - spacing, width: cornerLength, height: borderWidth))
        bottomLeftVertical.backgroundColor = .white
        bottomLeftHorizontal.backgroundColor = .white
        qrCodeFrameView.addSubview(bottomLeftVertical)
        qrCodeFrameView.addSubview(bottomLeftHorizontal)
        
        // Bottom-right corner
        let bottomRightVertical = UIView(frame: CGRect(x: qrFrame.width - borderWidth - spacing, y: qrFrame.height - cornerLength - spacing, width: borderWidth, height: cornerLength))
        let bottomRightHorizontal = UIView(frame: CGRect(x: qrFrame.width - cornerLength - spacing, y: qrFrame.height - borderWidth - spacing, width: cornerLength, height: borderWidth))
        bottomRightVertical.backgroundColor = .white
        bottomRightHorizontal.backgroundColor = .white
        qrCodeFrameView.addSubview(bottomRightVertical)
        qrCodeFrameView.addSubview(bottomRightHorizontal)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}


struct Platform {
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0 // Use this line in Xcode 7 or newer
    }
}


extension UIStoryboard  {
    static var qrVC: UIStoryboard {
        return UIStoryboard.init(name: "QRViewController", bundle: Bundle.main)
    }
}


