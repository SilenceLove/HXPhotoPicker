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
        let exportSession = AVAssetExportSession(
            asset: avAsset,
            presetName: presetName
        )
        exportSession?.outputURL = fileURL
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.outputFileType = .mp4
        if exportParameter.quality > 0 {
            var maxSize: Int?
            if let urlAsset = avAsset as? AVURLAsset {
                maxSize = urlAsset.url.fileSize
            }
            exportSession?.fileLengthLimit = PhotoTools.exportSessionFileLengthLimit(
                seconds: avAsset.duration.seconds,
                maxSize: maxSize,
                exportPreset: exportParameter.preset,
                videoQuality: exportParameter.quality
            )
        }
        exportSession?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                switch exportSession?.status {
                case .completed:
                    completionHandler?(fileURL, nil)
                case .failed, .cancelled:
                    completionHandler?(nil, exportSession?.error)
                default: break
                }
            }
        })
        if exportSession == nil {
            completionHandler?(nil, exportSession?.error)
        }
        return exportSession
    }
}
