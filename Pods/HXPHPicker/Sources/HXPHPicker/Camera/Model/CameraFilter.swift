//
//  CameraFilter.swift
//  HXPHPicker
//
//  Created by Slience on 2022/2/15.
//

import UIKit
import Accelerate
import VideoToolbox

public protocol CameraFilter {
    
    /// 滤镜名称
    var filterName: String { get }
    
    /// 准备滤镜
    func prepare(_ size: CGSize)
    
    /// 添加滤镜
    func render(_ pixelBuffer: CVPixelBuffer) -> CIImage?
    func render(
        _ pixelBuffer: CVPixelBuffer,
        _ pixelBufferPool: CVPixelBufferPool,
        _ context: CIContext
    ) -> CVPixelBuffer?
    
    /// 重置
    func reset()
}

public extension CameraFilter {
    func prepare(_ size: CGSize) { }
    func render(_ pixelBuffer: CVPixelBuffer) -> CIImage? { nil }
    func render(
        _ pixelBuffer: CVPixelBuffer,
        _ pixelBufferPool: CVPixelBufferPool,
        _ context: CIContext
    ) -> CVPixelBuffer? { nil }
    func reset() { }
}

public class ToasterFilter: CameraFilter {
    public var filterName: String {
        "怀旧".localized
    }
    var filter: CIFilter?
    public func prepare(_ size: CGSize) {
        let width = size.width
        let height = size.height
        let centerWidth = width / 2.0
        let centerHeight = height / 2.0
        let radius0 = min(width / 4.0, height / 4.0)
        let radius1 = min(width / 1.5, height / 1.5)
        
        let color0 = PhotoTools.getColor(red: 128, green: 78, blue: 15, alpha: 255)
        let color1 = PhotoTools.getColor(red: 79, green: 0, blue: 79, alpha: 255)
        let filter = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": CIVector(x: centerWidth, y: centerHeight),
            "inputRadius0": radius0,
            "inputRadius1": radius1,
            "inputColor0": color0,
            "inputColor1": color1
            ])
        self.filter = filter
    }
    
    public func render(_ pixelBuffer: CVPixelBuffer) -> CIImage? {
        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        guard let toasterImage = filter?
                .outputImage?
                .cropped(to: sourceImage.extent)
        else {
            return nil
        }
        let filteredImage = sourceImage
            .applyingFilter(
                "CIColorControls",
                parameters: [
                    "inputSaturation": 1.0,
                    "inputBrightness": 0.01,
                    "inputContrast": 1.1
                ]
            )
            .applyingFilter(
                "CIScreenBlendMode",
                parameters: [
                    "inputBackgroundImage": toasterImage
                ]
            )
        return filteredImage
    }
    
    public func reset() {
        filter = nil
    }
    
    public init() { }
}

public class InstantFilter: CameraFilter {
    public var filterName: String {
        "梦幻".localized
    }
    var filter: CIFilter?
    public func prepare(_ size: CGSize) {
        let filter = CIFilter(name: "CIPhotoEffectInstant", parameters: [:])
        self.filter = filter
    }
    
    public func render(_ pixelBuffer: CVPixelBuffer) -> CIImage? {
        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        filter?.setValue(sourceImage, forKey: kCIInputImageKey)
        return filter?.outputImage?.cropped(to: sourceImage.extent)
    }
    
    public func reset() {
        filter = nil
    }
    
    public init() { }
}

public class Apply1977Filter: CameraFilter {
    public var filterName: String {
        "1977".localized
    }
    
    public func render(_ pixelBuffer: CVPixelBuffer) -> CIImage? {
        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        let filterImage = PhotoTools.getColorImage(
            red: 243, green: 106, blue: 188, alpha: Int(255 * 0.1),
            rect: sourceImage.extent
        )
        let backgroundImage = sourceImage
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.3,
                "inputBrightness": 0.1,
                "inputContrast": 1.05
                ])
            .applyingFilter("CIHueAdjust", parameters: [
                "inputAngle": 0.3
                ])
        return filterImage
            .applyingFilter("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage
                ])
            .applyingFilter("CIToneCurve", parameters: [
                "inputPoint0": CIVector(x: 0, y: 0),
                "inputPoint1": CIVector(x: 0.25, y: 0.20),
                "inputPoint2": CIVector(x: 0.5, y: 0.5),
                "inputPoint3": CIVector(x: 0.75, y: 0.80),
                "inputPoint4": CIVector(x: 1, y: 1)
                ])
    }
    
    public init() { }
}

public class TransferFilter: CameraFilter {
    public var filterName: String {
        "岁月".localized
    }
    var filter: CIFilter?
    public func prepare(_ size: CGSize) {
        let filter = CIFilter(name: "CIPhotoEffectTransfer", parameters: [:])
        self.filter = filter
    }
    
    public func render(_ pixelBuffer: CVPixelBuffer) -> CIImage? {
        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        filter?.setValue(sourceImage, forKey: kCIInputImageKey)
        return filter?.outputImage?.cropped(to: sourceImage.extent)
    }
    
    public func reset() {
        filter = nil
    }
    
    public init() { }
}
