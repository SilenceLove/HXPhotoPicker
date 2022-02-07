//
//  Editor+CIImage.swift
//  HXPHPicker
//
//  Created by Slience on 2022/1/12.
//

import UIKit

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

        // UIKit and UIImageView .contentMode doesn't play well with
        // CIImage only, so we need to back the return UIImage with a CGImage
        let context = CIContext()

        // cropping rect because blur changed size of image

        // to clear the blurred edges, use a fromRect that is
        // the original image extent insetBy (negative) 1/2 of new extent origins
        let newExtent = beginImage.extent.insetBy(dx: -output.extent.origin.x * 0.5, dy: -output.extent.origin.y * 0.5)
        guard let final = context.createCGImage(output, from: newExtent) else {
            return nil
        }
        return CIImage(cgImage: final)

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
}
