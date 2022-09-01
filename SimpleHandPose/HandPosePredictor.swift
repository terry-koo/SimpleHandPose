//
//  HandPosePredictor.swift
//  SimpleHandPose
//
//  Created by Terry Koo on 2022/09/01.
//

import Vision
import UIKit

class HandPosePredictor {
    static func HandPoseClassifier() -> MyHandPoseClassifier? {
        // Use a default model configuration.
        let defaultConfig = MLModelConfiguration()


        // Create an instance of the image classifier's wrapper class.
        let handPoseClassifierWrapper = try? MyHandPoseClassifier(configuration: defaultConfig)

        guard let handPoseClassifier = handPoseClassifierWrapper else {
            fatalError("App failed to create an image classifier model instance.")
        }

        // Get the underlying model instance.
        let handPoseClassifierModel = handPoseClassifier.model
        
        return handPoseClassifierWrapper
    }
}

