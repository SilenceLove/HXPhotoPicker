//
//  AssetManager+AVAssetExportSession.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/6/9.
//

import UIKit
import Photos

public extension AssetManager {
    
    static func exportVideoURL(
        forVideo asset: PHAsset,
        toFile fileURL: URL,
        exportParameter: VideoExportParameter,
        exportSession: ((AVAssetExportSession) -> Void)? = nil,
        completionHandler: ((Result<URL, AssetManager.AVAssetError>) -> Void)?
    ) {
        requestAVAsset(
            for: asset
        ) { (result) in
            switch result {
            case .success(let avResult):
                let avAsset = avResult.avAsset
                avAsset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                    if avAsset.statusOfValue(forKey: "tracks", error: nil) != .loaded {
                        DispatchQueue.main.async {
                            completionHandler?(.failure(.init(info: nil, error: .exportFailed(nil))))
                        }
                        return
                    }
                    let session = self.exportVideoURL(
                        forVideo: avResult.avAsset,
                        toFile: fileURL,
                        exportParameter: exportParameter
                    ) { videoURL, error in
                        if let videoURL = videoURL {
                            completionHandler?(.success(videoURL))
                        }else {
                            completionHandler?(.failure(.init(info: avResult.info, error: .exportFailed(error))))
                        }
                    }
                    if let session = session {
                        DispatchQueue.main.async {
                            exportSession?(session)
                        }
                    }
                }
            case .failure(let error):
                completionHandler?(.failure(error))
            }
        }
    }
    
    @discardableResult
    static func exportVideoURL(
        forVideo avAsset: AVAsset,
        toFile fileURL: URL,
        exportParameter: VideoExportParameter,
        completionHandler: ((URL?, Error?) -> Void)?
    ) -> AVAssetExportSession? {
        var presetName = exportParameter.preset.name
        let presets = AVAssetExportSession.exportPresets(compatibleWith: avAsset)
        if !presets.contains(presetName) {
            if presets.contains(AVAssetExportPresetHighestQuality) {
                presetName = AVAssetExportPresetHighestQuality
            }else if presets.contains(AVAssetExportPreset1280x720) {
                presetName = AVAssetExportPreset1280x720
            }else {
                presetName = AVAssetExportPresetMediumQuality
            }
        }
        guard let exportSession = AVAssetExportSession(
            asset: avAsset,
            presetName: presetName
        ) else {
            completionHandler?(nil, AssetError.exportFailed(nil))
            return nil
        }
        exportSession.outputURL = fileURL
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.outputFileType = .mp4
        if exportParameter.quality > 0 {
            var maxSize: Int?
            if let urlAsset = avAsset as? AVURLAsset {
                maxSize = urlAsset.url.fileSize
            }
            exportSession.fileLengthLimit = PhotoTools.exportSessionFileLengthLimit(
                seconds: avAsset.duration.seconds,
                maxSize: maxSize,
                exportPreset: exportParameter.preset,
                videoQuality: exportParameter.quality
            )
        }
        exportSession.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    completionHandler?(fileURL, nil)
                case .failed, .cancelled:
                    completionHandler?(nil, exportSession.error)
                default: break
                }
            }
        })
        return exportSession
    }
    
    typealias ExportSessionResultHandler = (Result<ExportSessionResult, ExportSessionError>) -> Void
    
    struct ExportSessionResult {
        public let session: AVAssetExportSession
        public let info: [AnyHashable: Any]?
    }
    
    struct ExportSessionError: Error {
        public let info: [AnyHashable: Any]?
        public let error: AssetError
    }
    
    @discardableResult
    static func requestExportSession(
        for asset: PHAsset,
        exportPreset: String,
        iCloudHandler: ((PHImageRequestID) -> Void)? = nil,
        progressHandler: PHAssetImageProgressHandler? = nil,
        resultHandler: @escaping ExportSessionResultHandler
    ) -> PHImageRequestID {
        requestExportSession(for: asset, exportPreset: exportPreset, isNetworkAccessAllowed: false) {
            switch $0 {
            case .success(let result):
                resultHandler(.success(result))
            case .failure(let error):
                switch error.error {
                case .needSyncICloud:
                    let iCloudRequestID = self.requestExportSession(
                        for: asset,
                        exportPreset: exportPreset,
                        isNetworkAccessAllowed: true,
                        progressHandler: progressHandler,
                        resultHandler: resultHandler
                    )
                    iCloudHandler?(iCloudRequestID)
                default:
                    resultHandler(.failure(error))
                }
            }
        }
    }
    
    @discardableResult
    static func requestExportSession(
        for asset: PHAsset,
        exportPreset: String,
        isNetworkAccessAllowed: Bool,
        progressHandler: PHAssetVideoProgressHandler? = nil,
        resultHandler: @escaping ExportSessionResultHandler
    ) -> PHImageRequestID {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.deliveryMode = .highQualityFormat
        options.progressHandler = progressHandler
        return requestExportSession(for: asset, options: options, exportPreset: exportPreset, resultHandler: resultHandler)
    }
    
    @discardableResult
    static func requestExportSession(
        for asset: PHAsset,
        options: PHVideoRequestOptions,
        exportPreset: String,
        resultHandler: @escaping ExportSessionResultHandler
    ) -> PHImageRequestID {
        PHImageManager.default().requestExportSession(
            forVideo: asset,
            options: options,
            exportPreset: exportPreset
        ) { session, info in
            DispatchQueue.main.async {
                if let session, self.assetDownloadFinined(for: info) {
                    resultHandler(
                        .success(
                            .init(session: session, info: info)
                        )
                    )
                }else {
                    if self.assetIsInCloud(for: info) {
                        resultHandler(
                            .failure(
                                .init(
                                    info: info,
                                    error: .needSyncICloud
                                )
                            )
                        )
                        return
                    }
                    resultHandler(
                        .failure(
                            .init(
                                info: info,
                                error: .requestFailed(info)
                            )
                        )
                    )
                }
            }
        }
    }
     
}
