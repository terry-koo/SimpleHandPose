//
//  CameraView.swift
//  SimpleHandPose
//
//  Created by Terry Koo on 2022/08/31.
//

import UIKit
import AVFoundation
import Vision

class CameraView: UIView {
    private var overlayLayer: CAShapeLayer = CAShapeLayer()
    private var pointsPath: UIBezierPath = UIBezierPath()
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    // vanila CALayer 그대로 사용하지않고 custom화된 layer를 사용
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame:  frame)
        setupOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOverlay()
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if layer == previewLayer {
            overlayLayer.frame = layer.bounds
        }
    }
    
    private func setupOverlay() {
        previewLayer.addSublayer(overlayLayer)
    }
    
    // TODO: - points를 보여주는 메서드 구현
    func showPoints(_ points: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]) {
        // 기존의 점을 지워줌
        pointsPath.removeAllPoints()
        
        // point마다 원 그려주기
        for point in Array(points.values) {
            let cgPoint: CGPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: point.previewPoint)
            pointsPath.move(to: cgPoint)
            pointsPath.addArc(withCenter: cgPoint, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        
        // point 색상 지정
        overlayLayer.fillColor = UIColor.white.cgColor
        CATransaction.begin()
        CATransaction.setDisableActions(false)
        overlayLayer.path = pointsPath.cgPath
        CATransaction.commit()
    }
}

extension VNRecognizedPoint {
    var previewPoint: CGPoint {
        return CGPoint(x: self.location.x, y: 1 - self.location.y)
    }
}

