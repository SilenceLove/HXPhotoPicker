//
//  EditorVideoCompositor.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/3/15.
//

import UIKit
import AVFoundation
import VideoToolbox

class EditorVideoCompositor: NSObject, AVVideoCompositing {
    #if targetEnvironment(macCatalyst)
    var sourcePixelBufferAttributes: [String: Any]? = [
        String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA,
        String(kCVPixelBufferMetalCompatibilityKey): true
    ]
    var requiredPixelBufferAttributesForRenderContext: [String: Any] = [
        String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA,
        String(kCVPixelBufferMetalCompatibilityKey): true
    ]
    #else
    var sourcePixelBufferAttributes: [String: Any]? = [
        String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA,
        String(kCVPixelBufferOpenGLESCompatibilityKey): true,
        String(kCVPixelBufferMetalCompatibilityKey): true
    ]
    var requiredPixelBufferAttributesForRenderContext: [String: Any] = [
        String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA,
        String(kCVPixelBufferOpenGLESCompatibilityKey): true,
        String(kCVPixelBufferMetalCompatibilityKey): true
    ]
    #endif
    
    private let context = CIContext(options: nil)
    private let renderContextQueue: DispatchQueue = DispatchQueue(
        label: "com.HXPhotoPicker.videoeditorrendercontextqueue"
    )
    private let renderingQueue: DispatchQueue = DispatchQueue(label: "com.HXPhotoPicker.videoeditorrenderingqueue")
    private var renderContextDidChange = false
    private var shouldCancelAllRequests = false
    private var renderContext: AVVideoCompositionRenderContext?
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContextQueue.sync(execute: { [weak self] in
            guard let self = self else { return }
            self.renderContext = newRenderContext
            self.renderContextDidChange = true
        })
    }

    func cancelAllPendingVideoCompositionRequests() {
        shouldCancelAllRequests = true
        renderingQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.shouldCancelAllRequests = false
        }
    }
    
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        renderingQueue.async { [weak self] in
            guard let self = self else { return }
            if self.shouldCancelAllRequests {
                asyncVideoCompositionRequest.finishCancelledRequest()
            } else {
                autoreleasepool {
                    if let resultPixels = self.newRenderdPixelBuffer(for: asyncVideoCompositionRequest) {
                        asyncVideoCompositionRequest.finish(withComposedVideoFrame: resultPixels)
                    }else {
                        asyncVideoCompositionRequest.finish(
                            with: NSError(
                                domain: "asyncVideoCompositionRequest error",
                                code: 0, userInfo: nil
                            )
                        )
                    }
                }
            }
        }
    }
    
    func newRenderdPixelBuffer(
        for request: AVAsynchronousVideoCompositionRequest
    ) -> CVPixelBuffer? {
        guard let instruction = request.videoCompositionInstruction as? VideoCompositionInstruction,
              let trackID = instruction.requiredSourceTrackIDs?.first as? CMPersistentTrackID else {
            return nil
        }
        guard let pixelBuffer = request.sourceFrame(byTrackID: trackID) else {
            return renderContext?.newPixelBuffer()
        }
        if var sourcePixelBuffer = fixOrientation(
            pixelBuffer,
            instruction.videoOrientation,
            instruction.cropFactor
        ) {
            if let filterPixelBuffer = instruction.filter?(sourcePixelBuffer, request.compositionTime) {
                sourcePixelBuffer = filterPixelBuffer
            }
            var watermarkPixelBuffer: CVPixelBuffer?
            if let watermarkTrackID = instruction.watermarkTrackID {
                watermarkPixelBuffer = request.sourceFrame(byTrackID: watermarkTrackID)
            }
            let endPixelBuffer = addWatermark(
                watermarkPixelBuffer,
                sourcePixelBuffer
            )
            let checkPixelBuffer = checkMask(
                endPixelBuffer,
                cropFactor: instruction.cropFactor,
                maskType: instruction.maskType
            )
            return checkPixelBuffer
        }else {
            if let filterPixelBuffer = instruction.filter?(pixelBuffer, request.compositionTime) {
                return filterPixelBuffer
            }
        }
        return renderContext?.newPixelBuffer()
    }
    
    func fixOrientation(
        _ pixelBuffer: CVPixelBuffer,
        _ videoOrientation: EditorVideoOrientation,
        _ cropFactor: EditorAdjusterView.CropFactor
    ) -> CVPixelBuffer? {
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        var size = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        var isFixOrientation: Bool = false
        switch videoOrientation {
        case .portrait:
            if #available(iOS 11.0, *) {
                ciImage = ciImage.oriented(.right)
            } else {
                ciImage = ciImage.oriented(forExifOrientation: 6)
            }
            size = .init(width: size.height, height: size.width)
            isFixOrientation = true
        case .portraitUpsideDown:
            if #available(iOS 11.0, *) {
                ciImage = ciImage.oriented(.left)
            } else {
                ciImage = ciImage.oriented(forExifOrientation: 8)
            }
            size = .init(width: size.height, height: size.width)
            isFixOrientation = true
        case .landscapeRight:
            break
        case .landscapeLeft:
            if #available(iOS 11.0, *) {
                ciImage = ciImage.oriented(.down)
            } else {
                ciImage = ciImage.oriented(forExifOrientation: 3)
            }
            isFixOrientation = true
        }
        if cropFactor.allowCroped {
            guard let cgImage = context.createCGImage(
                ciImage,
                from: CGRect(x: 0, y: 0, width: size.width, height: size.height)
            ) else {
                return pixelBuffer
            }
//            let maxWidth = max(size.width, size.height)
//            if maxWidth > 1280 * 1.25 {
//                if let newImage = scaleCGImage(cgImage, to: 1280 / maxWidth) {
//                    cgImage = newImage
//                }
//            }
            if let outputImage = croped(cgImage, cropFactor: cropFactor) {
                ciImage = CIImage(cgImage: outputImage)
                size = .init(width: outputImage.width, height: outputImage.height)
            }else {
                return pixelBuffer
            }
        }else if !isFixOrientation {
            return pixelBuffer
        }
        guard let newPixelBuffer = PhotoTools.createPixelBuffer(size) else {
            return pixelBuffer
        }
        context.render(ciImage, to: newPixelBuffer)
        return newPixelBuffer
    }
    
    func addWatermark(
        _ watermarkPixelBuffer: CVPixelBuffer?,
        _ bgPixelBuffer: CVPixelBuffer
    ) -> CVPixelBuffer {
        guard let watermarkPixelBuffer = watermarkPixelBuffer else {
            return bgPixelBuffer
        }
        var watermarkCGImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(watermarkPixelBuffer, options: nil, imageOut: &watermarkCGImage)
        guard var watermarkCGImage = watermarkCGImage else {
            return bgPixelBuffer
        }
        var bgCGImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(bgPixelBuffer, options: nil, imageOut: &bgCGImage)
        guard let bgCGImage = bgCGImage else {
            return bgPixelBuffer
        }
        let watermarkSize = CGSize(width: CGFloat(watermarkCGImage.width), height: CGFloat(watermarkCGImage.height))
        let bgSize = CGSize(width: CGFloat(bgCGImage.width), height: CGFloat(bgCGImage.height))
        if watermarkSize != bgSize {
            guard let cgImage = scaleCGImage(watermarkCGImage, to: bgSize.width / watermarkSize.width) else {
                return bgPixelBuffer
            }
            watermarkCGImage = cgImage
        }
        let watermarkCIImage = CIImage(cgImage: watermarkCGImage)
        let bgCIImage = CIImage(cgImage: bgCGImage)
        
        if let outputImage = watermarkCIImage.sourceOverCompositing(bgCIImage) {
            context.render(outputImage, to: bgPixelBuffer)
        }
        return bgPixelBuffer
    }
    
    func croped(
        _ imageRef: CGImage,
        cropFactor: EditorAdjusterView.CropFactor
    ) -> CGImage? {
        guard let context = initCGContext(imageRef, cropFactor) else {
            return nil
        }
        let width = CGFloat(imageRef.width)
        let height = CGFloat(imageRef.height)
        let rendWidth = width * cropFactor.sizeRatio.x
        let rendHeight = height * cropFactor.sizeRatio.y
        
        let centerX = width * cropFactor.centerRatio.x
        let centerY = height * cropFactor.centerRatio.y
        
        let translationX = -(centerX - width * 0.5)
        let translationY = -(height * 0.5 - centerY)
        
        context.translateBy(x: rendWidth * 0.5, y: rendHeight * 0.5)
        context.scaleBy(x: cropFactor.mirrorScale.x, y: cropFactor.mirrorScale.y)
        context.rotate(by: -cropFactor.angle.radians)
        
        let transform = CGAffineTransform(translationX: translationX, y: translationY)
        context.concatenate(transform)
        let rect = CGRect(origin: .init(x: -width * 0.5, y: -height * 0.5), size: CGSize(width: width, height: height))
        context.draw(imageRef, in: rect)
        return context.makeImage()
    }
    
    func initCGContext(_ imageRef: CGImage, _ cropFactor: EditorAdjusterView.CropFactor) -> CGContext? {
        let width = CGFloat(imageRef.width)
        let height = CGFloat(imageRef.height)
        let rendWidth = width * cropFactor.sizeRatio.x
        let rendHeight = height * cropFactor.sizeRatio.y
        var bitmapRawValue = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapRawValue += CGImageAlphaInfo.noneSkipFirst.rawValue
        let context = CGContext(
            data: nil,
            width: Int(rendWidth),
            height: Int(rendHeight),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapRawValue
        )
        context?.setShouldAntialias(true)
        context?.setAllowsAntialiasing(true)
        context?.interpolationQuality = .high
        return context
    }
    
    func initMaskCGContext(_ imageRef: CGImage, _ cropFactor: EditorAdjusterView.CropFactor) -> CGContext? {
        let rendWidth = CGFloat(imageRef.width)
        let rendHeight = CGFloat(imageRef.height)
        var bitmapRawValue = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapRawValue += CGImageAlphaInfo.premultipliedFirst.rawValue
        let context = CGContext(
            data: nil,
            width: Int(rendWidth),
            height: Int(rendHeight),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapRawValue
        )
        context?.setShouldAntialias(true)
        context?.setAllowsAntialiasing(true)
        context?.interpolationQuality = .high
        return context
    }
    
    func cropMask(
        _ imageRef: CGImage,
        cropFactor: EditorAdjusterView.CropFactor
    ) -> CGImage? {
        guard let maskImage = cropFactor.maskImage?.convertBlackImage()?.cgImage else {
            return nil
        }
        guard let context = initMaskCGContext(imageRef, cropFactor) else {
            return nil
        }
        let rendWidth = CGFloat(imageRef.width)
        let rendHeight = CGFloat(imageRef.height)
        context.translateBy(x: rendWidth * 0.5, y: rendHeight * 0.5)
        context.clip(
            to: .init(x: -rendWidth * 0.5, y: -rendHeight * 0.5, width: rendWidth, height: rendHeight),
            mask: maskImage
        )
        let rect = CGRect(
            origin: .init(x: -rendWidth * 0.5, y: -rendHeight * 0.5),
            size: CGSize(width: rendWidth, height: rendHeight)
        )
        context.draw(imageRef, in: rect)
        return context.makeImage()
    }
    
    var colorImage: CIImage?
    
    func checkMask(
        _ pixelBuffer: CVPixelBuffer,
        cropFactor: EditorAdjusterView.CropFactor,
        maskType: EditorView.MaskType
    ) -> CVPixelBuffer {
        if !cropFactor.isRound && cropFactor.maskImage == nil {
            return pixelBuffer
        }
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        var blurredImage = ciImage.clampedToExtent().filter(
            name: "CIGaussianBlur",
            parameters: [kCIInputRadiusKey: 40]
        )
        switch maskType {
        case .customColor(let color):
            if colorImage == nil {
                let size = CGSize(
                    width: CVPixelBufferGetWidth(pixelBuffer),
                    height: CVPixelBufferGetHeight(pixelBuffer)
                )
                colorImage = UIImage.image(for: color, havingSize: size, scale: 1)?.ci_Image
            }
            if let colorImage = colorImage {
                blurredImage = colorImage.sourceOverCompositing(ciImage)
            }
        default:
            break
        }
        if cropFactor.isRound {
            guard let ci_Image = ciImage.image?.roundCropping()?.ci_Image else {
                return pixelBuffer
            }
            if let blurredImage = blurredImage,
               let result = ci_Image.sourceOverCompositing(blurredImage) {
                ciImage = result
            }else {
                return pixelBuffer
            }
        }else {
            let size = CGSize(
                width: CVPixelBufferGetWidth(pixelBuffer),
                height: CVPixelBufferGetHeight(pixelBuffer)
            )
            let cgImage = context.createCGImage(
                ciImage,
                from: CGRect(x: 0, y: 0, width: size.width, height: size.height)
            )
            if let cgImage = cgImage,
               let blurredImage = blurredImage,
               let outputImage = cropMask(cgImage, cropFactor: cropFactor),
               let result = CIImage(cgImage: outputImage).sourceOverCompositing(blurredImage) {
                ciImage = result
            }else {
                return pixelBuffer
            }
        }
        context.render(ciImage, to: pixelBuffer)
        return pixelBuffer
    }
    
    func scaleCGImage(_ cgImage: CGImage, to scale: CGFloat) -> CGImage? {
        let width = cgImage.width
        let height = cgImage.height
        let newWidth = Int(CGFloat(width) * scale)
        let newHeight = Int(CGFloat(height) * scale)
        let bitsPerComponent = cgImage.bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow
        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = cgImage.bitmapInfo
        let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
        context?.scaleBy(x: scale, y: scale)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context?.makeImage()
    }
}

public typealias VideoCompositionFilter = (CVPixelBuffer, CMTime) -> CVPixelBuffer?

class VideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    var timeRange: CMTimeRange
    
    var enablePostProcessing: Bool
    
    var containsTweening: Bool
    
    var requiredSourceTrackIDs: [NSValue]?
    
    var passthroughTrackID: CMPersistentTrackID
    
    let watermarkTrackID: CMPersistentTrackID?
    let videoOrientation: EditorVideoOrientation
    let watermark: EditorVideoTool.Watermark
    let cropFactor: EditorAdjusterView.CropFactor
    let maskType: EditorView.MaskType
    let filter: VideoCompositionFilter?
    init(
        sourceTrackIDs: [NSValue],
        watermarkTrackID: CMPersistentTrackID?,
        timeRange: CMTimeRange,
        videoOrientation: EditorVideoOrientation,
        watermark: EditorVideoTool.Watermark,
        cropFactor: EditorAdjusterView.CropFactor,
        maskType: EditorView.MaskType,
        filter: VideoCompositionFilter? = nil
    ) {
        requiredSourceTrackIDs = sourceTrackIDs
        if let watermarkTrackID = watermarkTrackID {
            requiredSourceTrackIDs?.append(watermarkTrackID as NSValue)
        }
        passthroughTrackID = kCMPersistentTrackID_Invalid
        self.watermarkTrackID = watermarkTrackID
        self.timeRange = timeRange
        containsTweening = true
        enablePostProcessing = false
        self.videoOrientation = videoOrientation
        self.watermark = watermark
        self.cropFactor = cropFactor
        self.maskType = maskType
        self.filter = filter
        super.init()
    }
}
