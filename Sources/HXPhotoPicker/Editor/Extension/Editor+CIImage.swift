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
            inputImage = brightnessContrastFilter.outputImage ?? inputImage
        }
        
        if editFator.exposure != 0 {
            guard let exposureFilter = CIFilter(name: "CIExposureAdjust") else { return inputImage }
            exposureFilter.setDefaults()
            exposureFilter.setValue(inputImage, forKey: kCIInputImageKey)
            exposureFilter.setValue(editFator.exposure, forKey: kCIInputEVKey)
            inputImage = exposureFilter.outputImage ?? inputImage
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
            inputImage = vignetteFilter.outputImage ?? inputImage
        }
        
        if editFator.sharpen != 0 {
            guard let sharpFilter = CIFilter(name: "CISharpenLuminance") else { return inputImage }
            sharpFilter.setDefaults()
            sharpFilter.setValue(inputImage, forKey: kCIInputImageKey)
            sharpFilter.setValue(editFator.sharpen, forKey: kCIInputSharpnessKey)
            inputImage = sharpFilter.outputImage ?? inputImage
        }
        
//        if editFator.warmth != 0 {
//            guard let temperatureAndTintFilter = CIFilter(name: "CITemperatureAndTint") else { return sharpFilter.outputImage }
//            temperatureAndTintFilter.setValue(sharpFilter.outputImage, forKey: kCIInputImageKey)
//            temperatureAndTintFilter.setValue(CIVector(x: 2000 + 4500 * CGFloat(editFator.warmth), y: 0), forKey: "inputNeutral")
//            return temperatureAndTintFilter.outputImage
//        }else {
            return inputImage
//        }
    }
    
    /// 生成马赛克图片
    func applyMosaic(level: CGFloat) -> CIImage? {
        var screenScale: CGFloat = 0
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
