//
//  CustomVideoCompositionInstruction.swift
//  HXPHPicker
//
//  Created by Slience on 2022/1/13.
//

import UIKit
import AVKit
import VideoToolbox

class VideoFilterCompositor: NSObject, AVVideoCompositing {

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
    
    private let context = CIContext(options: nil)
    private let renderContextQueue: DispatchQueue = DispatchQueue(label: "com.HXPHPicker.videoeditorrendercontextqueue")
    private let renderingQueue: DispatchQueue = DispatchQueue(label: "com.HXPHPicker.videoeditorrenderingqueue")
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
        renderingQueue.async(execute: { [weak self] in
            guard let self = self else { return }
            if self.shouldCancelAllRequests {
                asyncVideoCompositionRequest.finishCancelledRequest()
            } else {
                autoreleasepool {
                    if let resultPixels = self.newRenderdPixelBuffer(for: asyncVideoCompositionRequest) {
                        asyncVideoCompositionRequest.finish(withComposedVideoFrame: resultPixels)
                    }else {
                        asyncVideoCompositionRequest.finish(
                            with: NSError(domain: "asyncVideoCompositionRequest error",
                                          code: 0, userInfo: nil)
                        )
                    }
                }
            }
        })
    }
    
    func newRenderdPixelBuffer(
        for request: AVAsynchronousVideoCompositionRequest
    ) -> CVPixelBuffer? {
        guard let instruction = request.videoCompositionInstruction as? CustomVideoCompositionInstruction,
              let trackID = instruction.requiredSourceTrackIDs?.first as? CMPersistentTrackID,
              let pixelBuffer = request.sourceFrame(byTrackID: trackID) else {
            return nil
        }
        guard let sourcePixelBuffer = fixOrientation(
                pixelBuffer,
                instruction.videoOrientation,
                instruction.cropSizeData
              ),
              let resultPixelBuffer = applyFillter(
                sourcePixelBuffer,
                instruction.filterInfo,
                instruction.filterValue
              )
        else {
            return renderContext?.newPixelBuffer()
        }
        var watermarkPixelBuffer: CVPixelBuffer?
        if let watermarkTrackID = instruction.watermarkTrackID {
            watermarkPixelBuffer = request.sourceFrame(byTrackID: watermarkTrackID)
        }
        let endPixelBuffer = addWatermark(
            watermarkPixelBuffer,
            resultPixelBuffer
        )
        if let sizeData = instruction.cropSizeData, sizeData.isRoundCrop {
            return roundCrop(endPixelBuffer)
        }
        return endPixelBuffer
    }
    
    func fixOrientation(
        _ pixelBuffer: CVPixelBuffer,
        _ videoOrientation: AVCaptureVideoOrientation,
        _ cropSizeData: VideoEditorCropSizeData?
    ) -> CVPixelBuffer? {
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        var size = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        switch videoOrientation {
        case .portrait:
            ciImage = ciImage.oriented(.right)
            size = .init(width: size.height, height: size.width)
        case .portraitUpsideDown:
            ciImage = ciImage.oriented(.left)
        case .landscapeRight:
            break
        case .landscapeLeft:
            ciImage = ciImage.oriented(.down)
            size = .init(width: size.height, height: size.width)
        @unknown default:
            break
        }
        if let cropSizeData = cropSizeData {
            let x = size.width * cropSizeData.cropRect.minX
            var y = size.height * cropSizeData.cropRect.minY
            let width = size.width * cropSizeData.cropRect.width
            let height = size.height * cropSizeData.cropRect.height
            y = size.height - height - y
            ciImage = ciImage.cropped(
                to: .init(x: x, y: y, width: width, height: height)
            ).transformed(by: .init(translationX: -x, y: -y))
            size = .init(width: width, height: height)
            
            let orientation = PhotoTools.cropOrientation(cropSizeData)
            switch orientation {
            case .upMirrored:
                ciImage = ciImage.oriented(.upMirrored)
            case .left:
                ciImage = ciImage.oriented(.left)
                size = .init(width: size.height, height: size.width)
            case .leftMirrored:
                ciImage = ciImage.oriented(.rightMirrored)
                size = .init(width: size.height, height: size.width)
            case .right:
                ciImage = ciImage.oriented(.right)
                size = .init(width: size.height, height: size.width)
            case .rightMirrored:
                ciImage = ciImage.oriented(.leftMirrored)
                size = .init(width: size.height, height: size.width)
            case .down:
                ciImage = ciImage.oriented(.down)
            case .downMirrored:
                ciImage = ciImage.oriented(.downMirrored)
            default:
                break
            }
        }
        guard let newPixelBuffer = PhotoTools.createPixelBuffer(size) else {
            return nil
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
        guard let watermarkCGImage = watermarkCGImage else {
            return bgPixelBuffer
        }
        var bgCGImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(bgPixelBuffer, options: nil, imageOut: &bgCGImage)
        guard let bgCGImage = bgCGImage else {
            return bgPixelBuffer
        }
        let watermarkCIImage = CIImage(cgImage: watermarkCGImage)
        let bgCIImage = CIImage(cgImage: bgCGImage)
        if let outputImage = watermarkCIImage.sourceOverCompositing(bgCIImage) {
            context.render(outputImage, to: bgPixelBuffer)
        }
        return bgPixelBuffer
    }
    
    func applyFillter(
        _ pixelBuffer: CVPixelBuffer,
        _ info: PhotoEditorFilterInfo?,
        _ value: Float
    ) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let size = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        if let outputImage = info?.videoFilterHandler?(ciImage.clampedToExtent(), value),
           let newPixelBuffer = PhotoTools.createPixelBuffer(size) {
            context.render(outputImage, to: newPixelBuffer)
            return newPixelBuffer
        }
        return pixelBuffer
    }
    
    func roundCrop(
        _ pixelBuffer: CVPixelBuffer
    ) -> CVPixelBuffer {
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let blurredImage = ciImage.clampedToExtent().filter(
            name: "CIGaussianBlur",
            parameters: [kCIInputRadiusKey: 40]
        )
        guard let ci_Image = ciImage.image?.roundCropping()?.ci_Image else {
            return pixelBuffer
        }
        if let blurredImage = blurredImage,
           let result = ci_Image.sourceOverCompositing(blurredImage) {
            ciImage = result
        }
        context.render(ciImage, to: pixelBuffer)
        return pixelBuffer
    }
}

class CustomVideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    var timeRange: CMTimeRange
    
    var enablePostProcessing: Bool
    
    var containsTweening: Bool
    
    var requiredSourceTrackIDs: [NSValue]?
    
    var passthroughTrackID: CMPersistentTrackID
    
    let watermarkTrackID: CMPersistentTrackID?
    let videoOrientation: AVCaptureVideoOrientation
    let cropSizeData: VideoEditorCropSizeData?
    let filterInfo: PhotoEditorFilterInfo?
    let filterValue: Float
    init(
        sourceTrackIDs: [NSValue],
        watermarkTrackID: CMPersistentTrackID?,
        timeRange: CMTimeRange,
        videoOrientation: AVCaptureVideoOrientation,
        cropSizeData: VideoEditorCropSizeData?,
        filterInfo: PhotoEditorFilterInfo? = nil,
        filterValue: Float = 0
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
        self.cropSizeData = cropSizeData
        self.filterInfo = filterInfo
        self.filterValue = filterValue
        super.init()
    }
}
