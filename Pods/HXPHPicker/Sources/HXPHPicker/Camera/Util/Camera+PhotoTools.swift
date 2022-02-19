//
//  Camera+PhotoTools.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/3.
//

import UIKit
import CoreVideo
import MobileCoreServices

extension PhotoTools {
    
    static func focusAnimation(for view: UIView, at point: CGPoint) {
        view.layer.removeAnimation(forKey: "focusViewAnimation")
        view.center = point
        view.transform = .identity
        
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.duration = 1
        scaleAnimation.values = [0.9, 1.1, 0.95, 1.05, 1, 0.95, 1.0]
        scaleAnimation.isRemovedOnCompletion = false
        
        let opcityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opcityAnimation.duration = 1
        opcityAnimation.values = [0.2, 1.0, 0.5, 1, 0.35, 1, 0.2, 0.5, 0]
        opcityAnimation.timingFunction = .init(name: .linear)
        opcityAnimation.isRemovedOnCompletion = false
    
        let group = CAAnimationGroup()
        group.animations = [scaleAnimation, opcityAnimation]
        group.duration = 1
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards
        
        view.layer.add(group, forKey: "focusViewAnimation")
    }
    
    static func jpegData(
        withPixelBuffer pixelBuffer: CVPixelBuffer,
        attachments: CFDictionary?
    ) -> Data? {
        let ciContext = CIContext()
        let renderedCIImage = CIImage(cvImageBuffer: pixelBuffer)
        guard let renderedCGImage = ciContext.createCGImage(renderedCIImage, from: renderedCIImage.extent) else {
            print("Failed to create CGImage")
            return nil
        }
        
        guard let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else {
            print("Create CFData error!")
            return nil
        }
        
        guard let cgImageDestination = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, nil) else {
            print("Create CGImageDestination error!")
            return nil
        }
        
        CGImageDestinationAddImage(cgImageDestination, renderedCGImage, attachments)
        if CGImageDestinationFinalize(cgImageDestination) {
            return data as Data
        }
        print("Finalizing CGImageDestination error!")
        return nil
    }
}
