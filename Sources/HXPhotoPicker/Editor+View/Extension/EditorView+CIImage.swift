//
//  EditorView+CIImage.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/6/14.
//

import UIKit
import ImageIO
import MobileCoreServices
import UniformTypeIdentifiers

extension CIImage {
    
    var image: UIImage? {
        if let cgImage = cg_Image {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    var cg_Image: CGImage? {
        if let cgImage = cgImage {
            return cgImage
        }
        return CIContext(options: nil).createCGImage(self, from: self.extent)
    }
    
    func sourceOverCompositing(
        _ backgroundImage: CIImage
    ) -> CIImage? {
        let filter = CIFilter(name: "CISourceOverCompositing")
        filter?.setDefaults()
        filter?.setValue(self, forKey: kCIInputImageKey)
        filter?.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
        return filter?.outputImage?.cropped(to: extent)
    }
    
    func filter(name: String, parameters: [String: Any]) -> CIImage? {
        guard let filter = CIFilter(name: name, parameters: parameters) else {
            return nil
        }
        filter.setValue(self, forKey: kCIInputImageKey)
        guard let output = filter.outputImage?.cropped(to: self.extent) else {
            return nil
        }
        return output
    }
    
    func blurredImage(
        _ radius: Float
    ) -> CIImage? {
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(self, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        let context = CIContext()
        guard let result = filter?.value(forKey: kCIOutputImageKey) as? CIImage,
              let cgImage = context.createCGImage(
                result.unpremultiplyingAlpha().settingAlphaOne(in: extent),
                from: extent
              )
        else {
            return nil
        }
        let retVal = CIImage(cgImage: cgImage)
        return retVal
    }
}

extension CGImage {
    func pngData() -> Data? {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, kUTTypePNG, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(dest, self, nil)
        CGImageDestinationFinalize(dest)
        return data as Data
    }
    
    func jpegData(quality: CGFloat) -> Data? {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, nil) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(dest, self, options as CFDictionary)
        CGImageDestinationFinalize(dest)
        return data as Data
    }
    
    func heicData(quality: CGFloat) -> Data? {
        let data = NSMutableData()
        let utType: CFString
        if #available(iOS 14.0, *) {
            utType = UTType.heic.identifier as CFString
        } else {
            utType = "public.heic" as CFString
        }
        guard let dest = CGImageDestinationCreateWithData(data, utType, 1, nil) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(dest, self, options as CFDictionary)
        CGImageDestinationFinalize(dest)
        return data as Data
    }
}
