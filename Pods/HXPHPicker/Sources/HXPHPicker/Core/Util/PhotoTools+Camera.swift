//
//  PhotoTools+Camera.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/1.
//

#if HXPICKER_ENABLE_PICKER || HXPICKER_ENABLE_CAMERA
import UIKit
import Accelerate
import CoreGraphics
import CoreMedia
import QuartzCore

extension PhotoTools {
    
    static func cameraPreviewImageURL() -> URL {
        var cachePath = getImageCacheFolderPath()
        cachePath.append(contentsOf: "/" + "cameraPreviewImage".md5)
        return URL(fileURLWithPath: cachePath)
    }
    static func isCacheCameraPreviewImage() -> Bool {
        let imageCacheURL = cameraPreviewImageURL()
        return FileManager.default.fileExists(atPath: imageCacheURL.path)
    }
    
    static func saveCameraPreviewImage(_ image: UIImage) {
        if let data = getImageData(for: image),
           !data.isEmpty {
            do {
                let cachePath = getImageCacheFolderPath()
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: cachePath) {
                    try fileManager.createDirectory(
                        atPath: cachePath,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
                let imageCacheURL = cameraPreviewImageURL()
                if fileManager.fileExists(atPath: imageCacheURL.path) {
                    try fileManager.removeItem(at: imageCacheURL)
                }
                try data.write(to: cameraPreviewImageURL())
            } catch {
                print("saveError:\n", error)
            }
        }
    }
    
    static func getCameraPreviewImage() -> UIImage? {
        do {
            let cacheURL = cameraPreviewImageURL()
            if !FileManager.default.fileExists(atPath: cacheURL.path) {
                return nil
            }
            let data = try Data(contentsOf: cacheURL)
            return UIImage(data: data)
        } catch {
            print("getError:\n", error)
        }
        return nil
    }
    
    static func createImage(from sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
          return nil
        }

        // pixel format is Bi-Planar Component Y'CbCr 8-bit 4:2:0, full-range (luma=[0,255] chroma=[1,255]).
        // baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct.
        //
        guard CVPixelBufferGetPixelFormatType(imageBuffer) == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange else {
            return nil
        }

        guard CVPixelBufferLockBaseAddress(imageBuffer, .readOnly) == kCVReturnSuccess else {
            return nil
        }

        defer {
            // be sure to unlock the base address before returning
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        }

        // 1st plane is luminance, 2nd plane is chrominance
        guard CVPixelBufferGetPlaneCount(imageBuffer) == 2 else {
            return nil
        }

        // 1st plane
        guard let lumaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0) else {
            return nil
        }

        let lumaWidth = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
        let lumaHeight = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
        let lumaBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
        var lumaBuffer = vImage_Buffer(
            data: lumaBaseAddress,
            height: vImagePixelCount(lumaHeight),
            width: vImagePixelCount(lumaWidth),
            rowBytes: lumaBytesPerRow
        )

        // 2nd plane
        guard let chromaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1) else {
            return nil
        }

        let chromaWidth = CVPixelBufferGetWidthOfPlane(imageBuffer, 1)
        let chromaHeight = CVPixelBufferGetHeightOfPlane(imageBuffer, 1)
        let chromaBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1)
        var chromaBuffer = vImage_Buffer(
            data: chromaBaseAddress,
            height: vImagePixelCount(chromaHeight),
            width: vImagePixelCount(chromaWidth),
            rowBytes: chromaBytesPerRow
        )

        var argbBuffer = vImage_Buffer()

        defer {
            // we are responsible for freeing the buffer data
            free(argbBuffer.data)
        }

        // initialize the empty buffer
        guard vImageBuffer_Init(
            &argbBuffer,
            lumaBuffer.height,
            lumaBuffer.width,
            32,
            vImage_Flags(kvImageNoFlags)
            ) == kvImageNoError else {
                return nil
        }

        // full range 8-bit, clamped to full range, is necessary for correct color reproduction
        var pixelRange = vImage_YpCbCrPixelRange(
            Yp_bias: 0,
            CbCr_bias: 128,
            YpRangeMax: 255,
            CbCrRangeMax: 255,
            YpMax: 255,
            YpMin: 1,
            CbCrMax: 255,
            CbCrMin: 0
        )

        var conversionInfo = vImage_YpCbCrToARGB()

        // initialize the conversion info
        guard vImageConvert_YpCbCrToARGB_GenerateConversion(
            kvImage_YpCbCrToARGBMatrix_ITU_R_601_4, // Y'CbCr-to-RGB conversion matrix for ITU Recommendation BT.601-4.
            &pixelRange,
            &conversionInfo,
            kvImage420Yp8_CbCr8, // converting from
            kvImageARGB8888, // converting to
            vImage_Flags(kvImageNoFlags)
            ) == kvImageNoError else {
                return nil
        }

        // do the conversion
        guard vImageConvert_420Yp8_CbCr8ToARGB8888(
            &lumaBuffer, // in
            &chromaBuffer, // in
            &argbBuffer, // out
            &conversionInfo,
            nil,
            255,
            vImage_Flags(kvImageNoFlags)
            ) == kvImageNoError else {
                return nil
        }

        // core foundation objects are automatically memory mananged.
        // no need to call CGContextRelease() or CGColorSpaceRelease()
        guard let context = CGContext(
            data: argbBuffer.data,
            width: Int(argbBuffer.width),
            height: Int(argbBuffer.height),
            bitsPerComponent: 8,
            bytesPerRow: argbBuffer.rowBytes,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
            ) else {
                return nil
        }

        guard let cgImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
#endif
