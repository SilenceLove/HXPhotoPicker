//
//  Editor+CIImage.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/1/12.
//

import UIKit

extension CIImage {
    
    func blurredImageWithClippedEdges(
        _ inputRadius: Float
    ) -> CIImage? {

        guard let currentFilter = CIFilter(name: "CIGaussianBlur") else {
            return nil
        }
        let beginImage = self
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter.setValue(inputRadius, forKey: "inputRadius")
        guard let output = currentFilter.outputImage else {
            return nil
        }
        let context = CIContext()
        let newExtent = beginImage.extent.insetBy(dx: -output.extent.origin.x * 0.5, dy: -output.extent.origin.y * 0.5)
        guard let final = context.createCGImage(output, from: newExtent) else {
            return nil
        }
        return CIImage(cgImage: final)

    } 
    
    func apply(_ editFator: EditorFilterEditFator) -> CIImage? {
        var inputImage = self
        if editFator.brightness != 0 || editFator.contrast != 1 || editFator.saturation != 1 {
            let brightnessContrastFilter = CIFilter(name: "CIColorControls")!
            brightnessContrastFilter.setValue(inputImage, forKey: kCIInputImageKey)
            if editFator.brightness != 0 {
                brightnessContrastFilter.setValue(editFator.brightness, forKey: kCIInputBrightnessKey)
            }
            if editFator.contrast != 1 {
                brightnessContrastFilter.setValue(editFator.contrast, forKey: kCIInputContrastKey)
            }
            if editFator.saturation != 1 {
                brightnessContrastFilter.setValue(editFator.saturation, forKey: kCIInputSaturationKey)
            }
            if let image = brightnessContrastFilter.outputImage {
                inputImage = image
            }
        }
        
        if editFator.exposure != 0 {
            guard let exposureFilter = CIFilter(name: "CIExposureAdjust") else { return inputImage }
            exposureFilter.setDefaults()
            exposureFilter.setValue(inputImage, forKey: kCIInputImageKey)
            exposureFilter.setValue(editFator.exposure, forKey: kCIInputEVKey)
            if let image = exposureFilter.outputImage {
                inputImage = image
            }
        }
        
        if editFator.highlights != 0 || editFator.shadows != 0 {
            guard let filter = CIFilter(name: "CIHighlightShadowAdjust") else { return inputImage }
            filter.setDefaults()
            filter.setValue(inputImage, forKey: kCIInputImageKey)
            if editFator.highlights != 0 {
                filter.setValue(1 - editFator.highlights, forKey: "inputHighlightAmount")
            }
            if editFator.shadows != 0 {
                filter.setValue(editFator.shadows, forKey: "inputShadowAmount")
            }
            if let image = filter.outputImage {
                inputImage = image
            }
        }
        
        if editFator.vignette != 0 {
            guard let vignetteFilter = CIFilter(name: "CIVignette") else { return inputImage }
            vignetteFilter.setValue(inputImage, forKey: kCIInputImageKey)
            vignetteFilter.setValue(
                min(
                    max(extent.width / extent.height, extent.height / extent.width), 1
                ),
                forKey: kCIInputRadiusKey
            )
            vignetteFilter.setValue(editFator.vignette, forKey: kCIInputIntensityKey)
            if let image = vignetteFilter.outputImage {
                inputImage = image
            }
        }
        
        if editFator.sharpen != 0 {
            guard let sharpFilter = CIFilter(name: "CISharpenLuminance") else { return inputImage }
            sharpFilter.setDefaults()
            sharpFilter.setValue(inputImage, forKey: kCIInputImageKey)
            sharpFilter.setValue(editFator.sharpen, forKey: kCIInputSharpnessKey)
            if let image = sharpFilter.outputImage {
                inputImage = image
            }
        }
        
        if editFator.warmth != 0 {
            guard let temperatureAndTintFilter = CIFilter(name: "CITemperatureAndTint") else {
                return inputImage
            }
            temperatureAndTintFilter.setValue(inputImage, forKey: kCIInputImageKey)
            temperatureAndTintFilter.setValue(CIVector(x: 6500 + 3000 * CGFloat(editFator.warmth), y: 0), forKey: "inputNeutral")
            temperatureAndTintFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
            if let image = temperatureAndTintFilter.outputImage {
                inputImage = image
            }
        }
        return inputImage
    }
    
    /// 生成马赛克图片
    func applyMosaic(level: CGFloat) -> CIImage? {
        var screenScale: CGFloat = 1
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                screenScale = level / max(UIScreen._width, UIScreen._height)
            }
        }else {
            screenScale = level / max(UIScreen._width, UIScreen._height)
        }
        let scale = extent.width * screenScale
        return applyingFilter("CIPixellate", parameters: [kCIInputScaleKey: scale])
    }
}
