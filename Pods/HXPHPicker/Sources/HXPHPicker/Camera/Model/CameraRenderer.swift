//
//  CameraRenderer.swift
//  HXPHPicker
//
//  Created by Slience on 2022/2/15.
//

import UIKit
import AVKit

class CameraRenderer {
    var isPrepared = false
    private var ciContext: CIContext?
    private var outputColorSpace: CGColorSpace?
    private var outputPixelBufferPool: CVPixelBufferPool?
    private(set) var outputFormatDescription: CMFormatDescription?
    private(set) var inputFormatDescription: CMFormatDescription?
    
    private let filters: [CameraFilter]
    var filterIndex: Int {
        willSet {
            currentFilter.reset()
        }
        didSet {
            if filterIndex > filters.count - 1 {
                filterIndex = 0
            }else if filterIndex < 0 {
                filterIndex = filters.count - 1
            }
            if isPrepared {
                currentFilter.prepare(imageSize)
            }
        }
    }
    var currentFilter: CameraFilter {
        filters[filterIndex]
    }
    var currentFilterName: String {
        currentFilter.filterName
    }
    init(_ filters: [CameraFilter], _ index: Int) {
        self.filters = filters
        filterIndex = index
    }
    var imageSize: CGSize = .zero
    func prepare(
        with formatDescription: CMFormatDescription,
        outputRetainedBufferCountHint: Int,
        imageSize: CGSize
    ) {
        reset()
        if filterIndex == 0 {
            return
        }
        (
            outputPixelBufferPool,
            outputColorSpace,
            outputFormatDescription
        ) = allocateOutputBufferPool(
            with: formatDescription,
            outputRetainedBufferCountHint: outputRetainedBufferCountHint
        )
        if outputPixelBufferPool == nil {
            return
        }
        inputFormatDescription = formatDescription
        ciContext = CIContext()
        self.imageSize = imageSize
        currentFilter.prepare(imageSize)
        isPrepared = true
    }
    
    func reset() {
        ciContext = nil
        outputColorSpace = nil
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        currentFilter.reset()
        isPrepared = false
    }
    
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        if filterIndex == 0 || !isPrepared {
            return nil
        }
        guard let outputPixelBufferPool = outputPixelBufferPool,
              let ciContext = ciContext else { return nil }
        if let filteredImage = currentFilter.render(pixelBuffer) {
            var pbuf: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool, &pbuf)
            guard let outputPixelBuffer = pbuf else {
                print("Allocation failure")
                return nil
            }
            
            ciContext.render(
                filteredImage,
                to: outputPixelBuffer,
                bounds: filteredImage.extent,
                colorSpace: outputColorSpace
            )
            return outputPixelBuffer
        }
        return currentFilter.render(pixelBuffer, outputPixelBufferPool, ciContext)
    }
    
    func allocateOutputBufferPool(
        with inputFormatDescription: CMFormatDescription,
        outputRetainedBufferCountHint: Int
    ) ->(
        outputBufferPool: CVPixelBufferPool?,
        outputColorSpace: CGColorSpace?,
        outputFormatDescription: CMFormatDescription?
    ) {
        let inputMediaSubType = CMFormatDescriptionGetMediaSubType(inputFormatDescription)
        if inputMediaSubType != kCVPixelFormatType_32BGRA {
            return (nil, nil, nil)
        }
        
        let inputDimensions = CMVideoFormatDescriptionGetDimensions(inputFormatDescription)
        var pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: UInt(inputMediaSubType),
            kCVPixelBufferWidthKey as String: Int(inputDimensions.width),
            kCVPixelBufferHeightKey as String: Int(inputDimensions.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        // Get pixel buffer attributes and color space from the input format description.
        var cgColorSpace = CGColorSpaceCreateDeviceRGB()
        if let inputFormatDescriptionExtension = CMFormatDescriptionGetExtensions(
            inputFormatDescription
        ) as Dictionary? {
            let colorPrimaries = inputFormatDescriptionExtension[kCVImageBufferColorPrimariesKey]
            
            if let colorPrimaries = colorPrimaries {
                var colorSpaceProperties: [String: AnyObject] = [
                    kCVImageBufferColorPrimariesKey as String: colorPrimaries
                ]
                
                if let yCbCrMatrix = inputFormatDescriptionExtension[kCVImageBufferYCbCrMatrixKey] {
                    colorSpaceProperties[kCVImageBufferYCbCrMatrixKey as String] = yCbCrMatrix
                }
                
                if let transferFunction = inputFormatDescriptionExtension[kCVImageBufferTransferFunctionKey] {
                    colorSpaceProperties[kCVImageBufferTransferFunctionKey as String] = transferFunction
                }
                
                pixelBufferAttributes[kCVBufferPropagatedAttachmentsKey as String] = colorSpaceProperties
            }
            
            if let cvColorspace = inputFormatDescriptionExtension[kCVImageBufferCGColorSpaceKey] {
                cgColorSpace = cvColorspace as! CGColorSpace
            } else if (colorPrimaries as? String) == (kCVImageBufferColorPrimaries_P3_D65 as String) {
                cgColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
            }
        }
        
        // Create a pixel buffer pool with the same pixel attributes as the input format description.
        let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: outputRetainedBufferCountHint]
        var cvPixelBufferPool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(
            kCFAllocatorDefault,
            poolAttributes as NSDictionary?,
            pixelBufferAttributes as NSDictionary?,
            &cvPixelBufferPool
        )
        guard let pixelBufferPool = cvPixelBufferPool else {
            return (nil, nil, nil)
        }
        
        preallocateBuffers(pool: pixelBufferPool, allocationThreshold: outputRetainedBufferCountHint)
        
        // Get the output format description.
        var pixelBuffer: CVPixelBuffer?
        var outputFormatDescription: CMFormatDescription?
        let auxAttributes = [
            kCVPixelBufferPoolAllocationThresholdKey as String: outputRetainedBufferCountHint
        ] as NSDictionary
        CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(
            kCFAllocatorDefault,
            pixelBufferPool,
            auxAttributes,
            &pixelBuffer
        )
        if let pixelBuffer = pixelBuffer {
            CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescriptionOut: &outputFormatDescription
            )
        }
        pixelBuffer = nil
        
        return (pixelBufferPool, cgColorSpace, outputFormatDescription)
    }

    /// - Tag: AllocateRenderBuffers
    private func preallocateBuffers(pool: CVPixelBufferPool, allocationThreshold: Int) {
        var pixelBuffers = [CVPixelBuffer]()
        var error: CVReturn = kCVReturnSuccess
        let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: allocationThreshold] as NSDictionary
        var pixelBuffer: CVPixelBuffer?
        while error == kCVReturnSuccess {
            error = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(
                kCFAllocatorDefault,
                pool,
                auxAttributes,
                &pixelBuffer
            )
            if let pixelBuffer = pixelBuffer {
                pixelBuffers.append(pixelBuffer)
            }
            pixelBuffer = nil
        }
        pixelBuffers.removeAll()
    }
    
    deinit {
        currentFilter.reset()
    }
}

class OriginalFilter: CameraFilter {
    var filterName: String {
        "原片".localized
    }
}
