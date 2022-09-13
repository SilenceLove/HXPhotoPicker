//
//  Picker+LivePhotoTools.swift
//  HXPHPicker
//
//  Created by Slience on 2022/1/4.
//

import UIKit
import Photos
import MobileCoreServices

extension PhotoTools {
    
    static func getLivePhotoImageCachePath(for key: String) -> String {
        var cachePath = getLivePhotoImageCacheFolderPath()
        cachePath.append(contentsOf: "/" + key.md5 + ".jpg")
        return cachePath
    }
    
    static func getLivePhotoVideoCachePath(for key: String) -> String {
        var cachePath = getLivePhotoVideoCacheFolderPath()
        cachePath.append(contentsOf: "/" + key.md5 + ".mov")
        return cachePath
    }
    
    static func getLocalURLKey(for url: URL) -> String {
        var key = url.absoluteString
        if url.isFileURL {
            let components = url.pathComponents
            var i = 0
            for (index, path) in components.enumerated()
            where path == "Application" {
                i = index
                break
            }
            var path = ""
            for index in i..<components.count
            where index > i + 1 {
                let str = components[index]
                path += str
            }
            if i > 0 {
                key = path
            }
        }
        return key
    }
    
    static func getLivePhotoJPGURL(
        _ origianURL: URL,
        completion: (URL?) -> Void
    ) {
        let jpgPath = getLivePhotoImageCachePath(for: getLocalURLKey(for: origianURL))
        let jpgURL = URL(fileURLWithPath: jpgPath)
        if FileManager.default.fileExists(atPath: jpgURL.path) {
            completion(jpgURL)
            return
        }
        guard let origianData = try? Data(contentsOf: origianURL),
              let imageSourceRef = CGImageSourceCreateWithData(origianData as CFData, nil),
              let dest = CGImageDestinationCreateWithURL(jpgURL as CFURL, kUTTypeJPEG, 1, nil),
              var metaData = CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, nil) as? [String: Any] else {
            completion(nil)
            return
        }
        let assetIdentifier = PhotoManager.shared.uuid
        var makerNote: [String: Any] = [:]
        makerNote[kFigAppleMakerNote_AssetIdentifier] = assetIdentifier
        metaData[kCGImagePropertyMakerAppleDictionary as String] = makerNote
        CGImageDestinationAddImageFromSource(dest, imageSourceRef, 0, metaData as CFDictionary)
        CGImageDestinationFinalize(dest)
        completion(jpgURL)
    }
    
    static func getLivePhotoVideoMovURL(
        _ originMovURL: URL,
        header: (AVAssetWriter?, AVAssetWriterInput?, AVAssetReader?, AVAssetWriterInput?, AVAssetReader?) -> Void,
        completion: (URL?) -> Void
    ) {
        let movPath = getLivePhotoVideoCachePath(for: getLocalURLKey(for: originMovURL))
        let movURL = URL(fileURLWithPath: movPath)
        if FileManager.default.fileExists(atPath: movURL.path) {
            completion(movURL)
            return
        }
        let asset = AVURLAsset(url: originMovURL)
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let reader = try? AVAssetReader(asset: asset),
              let writer = try? AVAssetWriter(url: movURL, fileType: .mov) else {
            completion(nil)
            return
        }
        let assetIdentifier = PhotoManager.shared.uuid
        let videoOutput = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        )
        
        if reader.canAdd(videoOutput) {
            reader.add(videoOutput)
        }else {
            completion(nil)
            return
        }
        let metadataItem = AVMutableMetadataItem()
        metadataItem.key = kKeyContentIdentifier as NSCopying & NSObjectProtocol
        metadataItem.keySpace = .quickTimeMetadata
        metadataItem.value = assetIdentifier as NSCopying & NSObjectProtocol
        metadataItem.dataType = "com.apple.metadata.datatype.UTF-8"
        writer.metadata = [metadataItem]
        
        let videoCodecType: Any
        if #available(iOS 11.0, *) {
            videoCodecType = AVVideoCodecType.h264
        } else {
            // Fallback on earlier versions
            videoCodecType = AVVideoCodecH264
        }
        let outputSetting: [String: Any] = [
            AVVideoCodecKey: videoCodecType,
            AVVideoWidthKey: videoTrack.naturalSize.width,
            AVVideoHeightKey: videoTrack.naturalSize.height
        ]
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSetting)
        videoInput.expectsMediaDataInRealTime = true
        videoInput.transform = videoTrack.preferredTransform
        if writer.canAdd(videoInput) {
            writer.add(videoInput)
        }else {
            completion(nil)
            return
        }
        var audio_Input: AVAssetWriterInput?
        var audio_Reader: AVAssetReader?
        var audio_Output: AVAssetReaderTrackOutput?
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
            audioInput.expectsMediaDataInRealTime = true
            if writer.canAdd(audioInput) {
                writer.add(audioInput)
            }
            let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
            
            if let audioReader = try? AVAssetReader(asset: asset) {
                if audioReader.canAdd(audioOutput) {
                    audioReader.add(audioOutput)
                }
                audio_Reader = audioReader
            }
            audio_Input = audioInput
            audio_Output = audioOutput
        }
        
        let adapter = metadataSetAdapter
        writer.add(adapter.assetWriterInput)
        writer.startWriting()
        reader.startReading()
        writer.startSession(atSourceTime: .zero)
        
        let dummyTimeRange = CMTimeRange(
            start: .init(value: 0, timescale: 1000),
            duration: .init(value: 200, timescale: 3000)
        )
        let item = AVMutableMetadataItem()
        item.key = kKeyStillImageTime as NSCopying & NSObjectProtocol
        item.keySpace = .quickTimeMetadata
        item.value = 0 as NSCopying & NSObjectProtocol
        item.dataType = "com.apple.metadata.datatype.int8"
        adapter.append(.init(items: [item], timeRange: dummyTimeRange))
        
        let createMovQueue = DispatchQueue(label: "com.silence.createMovQueue", attributes: .init(rawValue: 0))
        
        videoInput.requestMediaDataWhenReady(on: createMovQueue) {
            while videoInput.isReadyForMoreMediaData {
                if reader.status == .reading {
                    if let videoBuffer = videoOutput.copyNextSampleBuffer() {
                        if !videoInput.append(videoBuffer) {
                            reader.cancelReading()
                        }
                    }else {
                        videoInput.markAsFinished()
                        if let audioInput = audio_Input, reader.status == .completed {
                            audio_Reader?.startReading()
                            writer.startSession(atSourceTime: .zero)
                            audioInput.requestMediaDataWhenReady(on: createMovQueue) {
                                while audioInput.isReadyForMoreMediaData {
                                    if let audioBuffer = audio_Output?.copyNextSampleBuffer() {
                                        if !audioInput.append(audioBuffer) {
                                            audio_Reader?.cancelReading()
                                        }
                                    }else {
                                        audioInput.markAsFinished()
                                        
                                        writer.finishWriting {
                                            
                                        }
                                        break
                                    }
                                }
                            }
                        }else {
                            writer.finishWriting {
                                
                            }
                        }
                        break
                    }
                }else {
                    writer.finishWriting {
                        
                    }
                }
            }
        }
        header(writer, videoInput, reader, audio_Input, audio_Reader)
        while writer.status == .writing {
            RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 0.5))
        }
        if writer.status == .cancelled || writer.status == .failed {
            try? FileManager.default.removeItem(at: movURL)
        }
        if writer.error != nil {
            completion(nil)
        }else {
            completion(movURL)
        }
    }
    
    private static var metadataSetAdapter: AVAssetWriterInputMetadataAdaptor {
        let identifier = AVMetadataKeySpace.quickTimeMetadata.rawValue + "/" + kKeyStillImageTime
        let spec = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier: identifier,
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType: "com.apple.metadata.datatype.int8"
        ]
        
        var desc: CMMetadataFormatDescription?
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(
            allocator: kCFAllocatorDefault,
            metadataType: kCMMetadataFormatType_Boxed,
            metadataSpecifications: [spec] as CFArray,
            formatDescriptionOut: &desc
        )
        let input = AVAssetWriterInput(
            mediaType: .metadata,
            outputSettings: nil,
            sourceFormatHint: desc
        )
        return AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
    }
    
    private static var kFigAppleMakerNote_AssetIdentifier: String {
        "17"
    }
    private static var kKeyContentIdentifier: String {
        "com.apple.quicktime.content.identifier"
    }
    private static var kKeyStillImageTime: String {
        "com.apple.quicktime.still-image-time"
    }
}
