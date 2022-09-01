//
//  ViewController.swift
//  SimpleHandPose
//
//  Created by Terry Koo on 2022/08/31.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    @IBOutlet weak var resultLabel: UILabel!
    private var cameraView: CameraView { view as! CameraView }
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    
    private var allPoint: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]? {
        didSet {
            cameraView.showPoints(allPoint ?? [:])
        }
    }
    private var model: MyHandPoseClassifier?
    private var result: MyHandPoseClassifierOutput?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareCaptureSession()
        prepareCaptureUI()
        
        handPoseRequest.maximumHandCount = 1
        
        guard let model = HandPosePredictor.HandPoseClassifier() else {
            print("error")
            return
        }
        self.model = model
        self.resultLabel.text = "없음"
    }
    
    private func prepareCaptureSession() {
        let captureSession = AVCaptureSession()
        
        // Select a front facing camera, make an input.
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: .main)
        captureSession.addOutput(output)

        self.captureSession = captureSession
        self.captureSession?.startRunning()
    }
    
    private func prepareCaptureUI() {
        guard let session = captureSession else { return }
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
        
        self.videoPreviewLayer = videoPreviewLayer
    }

}


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        
//        defer {
//            DispatchQueue.main.sync {
//                resultLabel.text = result?.label
//            }
//        }
                
        do {
            try handler.perform([handPoseRequest])
            // Continue only when a hand was detected in the frame.
            // Since we set the maximumHandCount property of the request to 1, there will be at most one observation.
            guard let observation = handPoseRequest.results?.first else {
                return
            }
            
            allPoint = try observation.recognizedPoints(.all)
            result = try model?.prediction(poses: observation.keypointsMultiArray())
            print("[Prediction] \(result?.label ?? "없음")")
            resultLabel.text = result?.label
            
            
        } catch {
            print("에러 \(error)")
        }
    }
}

