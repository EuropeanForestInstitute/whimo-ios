//
//  BarcodeScannerViewController.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 07.05.2025.
//
//  Copyright (c) 2025 EFI https://efi.int/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit
import AVFoundation
import var Utility.log

// MARK: - BarcodeScannerViewController
public final class BarcodeScannerViewController: UIViewController {
    // MARK: - Dependencies
    var dataOutputDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?

    // MARK: - Private Properties
    private let captureSession: AVCaptureSession = .init()
    private let dataOutputQueue: DispatchQueue = .init(label: "com.CommonUI.BarcodeScannerViewController.dataOutputQueue")
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()

        setupCaptureSession()
        setupVideoLayer()
        startCaptureSession()
    }
}

// MARK: - Private Methods
private extension BarcodeScannerViewController {
    func setupCaptureSession() {
        // Get the back-facing camera for capturing videos
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            log.error("Failed to get the camera device.")
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            videoInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            log.error("An error occured on creating video input: \(error)")
            return
        }

        // Set the input device on the capture session.
        captureSession.addInput(videoInput)

        let captureVideoOutput: AVCaptureVideoDataOutput = .init()
        if captureSession.canAddOutput(captureVideoOutput) {
            captureVideoOutput.setSampleBufferDelegate(dataOutputDelegate, queue: dataOutputQueue)
            captureSession.addOutput(captureVideoOutput)
        }
    }

    /// Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
    func setupVideoLayer() {
        videoPreviewLayer = .init(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!) // swiftlint:disable:this force_unwrapping
    }

    /// Start video capture.
    func startCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
}
