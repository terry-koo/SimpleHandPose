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
//            cameraView.showPoints(allPoint ?? [:])
        }
    }
    private var model: MyHandPoseClassifier?
    private var result: MyHandPoseClassifierOutput?
    
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        prepareCaptureSession()
//        prepareCaptureUI()
        
        handPoseRequest.maximumHandCount = 1
        
        guard let model = HandPosePredictor.HandPoseClassifier() else {
            print("error")
            return
        }
        self.model = model
        self.resultLabel.text = " 없음 "
        
        do {
            if cameraFeedSession == nil {
                cameraView.previewLayer.videoGravity = .resizeAspectFill
                try setupAVSession()
                cameraView.previewLayer.session = cameraFeedSession
            }
            cameraFeedSession?.startRunning()
        } catch {
            print(error)
        }
        
    }
    
    // MARK: - setupAVSession
    func setupAVSession() throws {
        // Select a front facing camera, make an input.
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        // Add a video input.
        guard session.canAddInput(deviceInput) else {
            return
        }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            // Add a video data output.
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
        }
        session.commitConfiguration()
        cameraFeedSession = session
    }

    // TODO: - 삭제 예정
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
    
    // TODO: - 삭제 예정
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
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .right, options: [:])
        
        defer {
            DispatchQueue.main.sync {
                resultLabel.text = " " + (result?.label ?? "없음") + " "
            }
        }
                
        do {
            try handler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else {
                result?.label = " 없음 "
//                cameraView.showPoints([:])
                print("observatoin return nil")
                return
            }
            
            allPoint = try observation.recognizedPoints(.all)
            result = try model?.prediction(poses: observation.keypointsMultiArray())
            print("[Prediction] \(result?.label ?? "없음")")
        } catch {
            print("에러 \(error)")
        }
    }
}

