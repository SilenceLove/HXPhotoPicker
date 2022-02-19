//
//  ImageFilter.swift
//  Example
//
//  Created by Slience on 2022/2/18.
//

import UIKit
import VideoToolbox
import HXPHPicker
import GPUImage

struct FilterTools {
    static func filters() -> [CameraFilter] {
        [
            BeautifyFilter(), InstantFilter(), Apply1977Filter(), ToasterFilter(), TransferFilter()
        ]
    }
}

 class BeautifyFilter: CameraFilter {
     var filterName: String {
         return "美白"
     }
     
     var filter: GPUImageBeautifyFilter?
     
     func prepare(_ size: CGSize) {
         filter = GPUImageBeautifyFilter(degree: 0.6)
     }
     
     func render(_ pixelBuffer: CVPixelBuffer) -> CIImage? {
         var cgImage: CGImage?
         VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
         guard let cgImage = cgImage, let bilateralFilter = filter else {
             return nil
         }
         let picture = GPUImagePicture(cgImage: cgImage)
         picture?.addTarget(bilateralFilter)
         bilateralFilter.useNextFrameForImageCapture()
         picture?.processImage()
         let result = bilateralFilter.newCGImageFromCurrentlyProcessedOutput().takeRetainedValue()
         return .init(cgImage: result)
     }
     
     func reset() {
         filter = nil
     }
}
