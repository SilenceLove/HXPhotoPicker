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
    
    private let context = CIContext()
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
        guard let instruction = request.videoCompositionInstruction as? CustomVideoCompositionInstruction
               else {
            return nil
        }
        if !instruction.hasSticker {
            guard let trackID = instruction.requiredSourceTrackIDs?.first as? CMPersistentTrackID,
                  let sourcePixelBuffer = request.sourceFrame(byTrackID: trackID) else {
                      return renderContext?.newPixelBuffer()
            }
            guard let resultPixelBuffer = instruction.applyFillter(sourcePixelBuffer) else {
                return sourcePixelBuffer
            }
            return resultPixelBuffer
        }
        let sourceTrackID = instruction.requiredSourceTrackIDs?[1] as? CMPersistentTrackID
        guard let trackID = sourceTrackID,
              let sourcePixelBuffer = request.sourceFrame(byTrackID: trackID) else {
                  return renderContext?.newPixelBuffer()
        }
        guard let resultPixelBuffer = instruction.applyFillter(sourcePixelBuffer) else {
            let watermarkTrackID = instruction.requiredSourceTrackIDs?.first as? CMPersistentTrackID
            if let trackID = watermarkTrackID,
               let watermarkPixelBuffer = request.sourceFrame(byTrackID: trackID) {
                return addWatermark(watermarkPixelBuffer, sourcePixelBuffer)
            }
            return sourcePixelBuffer
        }
        let watermarkTrackID = instruction.requiredSourceTrackIDs?.first as? CMPersistentTrackID
        if let trackID = watermarkTrackID,
           let watermarkPixelBuffer = request.sourceFrame(byTrackID: trackID) {
            return addWatermark(watermarkPixelBuffer, resultPixelBuffer)
        }
        return resultPixelBuffer
    }
    
    func addWatermark(
        _ watermarkPixelBuffer: CVPixelBuffer,
        _ bgPixelBuffer: CVPixelBuffer
    ) -> CVPixelBuffer {
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
        let ciFilter = CIFilter(name: "CISourceOverCompositing")
        ciFilter?.setDefaults()
        ciFilter?.setValue(watermarkCIImage, forKey: kCIInputImageKey)
        ciFilter?.setValue(bgCIImage, forKey: kCIInputBackgroundImageKey)
        if let outputImage = ciFilter?.outputImage {
            context.render(outputImage, to: bgPixelBuffer)
        }
        return bgPixelBuffer
    }
}

class CustomVideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    var timeRange: CMTimeRange
    
    var enablePostProcessing: Bool
    
    var containsTweening: Bool
    
    var requiredSourceTrackIDs: [NSValue]?
    
    var passthroughTrackID: CMPersistentTrackID
    
    let filterInfo: PhotoEditorFilterInfo?
    let filterValue: Float
    let hasSticker: Bool
    init(
        sourceTrackIDs: [NSValue],
        timeRange: CMTimeRange,
        hasSticker: Bool,
        filterInfo: PhotoEditorFilterInfo? = nil,
        filterValue: Float = 0
    ) {
        requiredSourceTrackIDs = sourceTrackIDs
        self.timeRange = timeRange
        passthroughTrackID = kCMPersistentTrackID_Invalid
        containsTweening = true
        enablePostProcessing = false
        self.hasSticker = hasSticker
        self.filterInfo = filterInfo
        self.filterValue = filterValue
        super.init()
    }
    
    private let context = CIContext()
    func applyFillter(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let size = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        if let outputImage = filterInfo?.videoFilterHandler?(ciImage, filterValue),
           let newPixelBuffer = createPixelBuffer(size) {
            context.render(outputImage, to: newPixelBuffer)
            return newPixelBuffer
        }
        return pixelBuffer
    }
    
    func createPixelBuffer(_ size: CGSize) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let pixelBufferAttributes = [kCVPixelBufferIOSurfacePropertiesKey: [:]]
        CVPixelBufferCreate(
            nil,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32BGRA,
            pixelBufferAttributes as CFDictionary,
            &pixelBuffer
        )
        return pixelBuffer
    }
}
