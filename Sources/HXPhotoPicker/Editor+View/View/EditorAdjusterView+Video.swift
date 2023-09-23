//
//  EditorAdjusterView+Video.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/2/25.
//

import UIKit
import AVFoundation

extension EditorAdjusterView {
    
    var isCropedVideo: Bool {
        let cropRatio = getCropOption()
        var drawLayer: CALayer?
        if contentView.drawView.count > 0 {
            drawLayer = contentView.drawView.layer
        }
        var stickersLayer: CALayer?
        if contentView.stickerView.count > 0 {
            stickersLayer = contentView.stickerView.layer
        }
        var canvasImage: UIImage?
        if #available(iOS 13.0, *) {
            canvasImage = contentView.isCanvasEmpty ? nil : contentView.canvasImage
        }
        let cropFactor = CropFactor(
            drawLayer: drawLayer,
            canvasImage: canvasImage,
            mosaicLayer: nil,
            stickersLayer: stickersLayer,
            isCropImage: isCropImage,
            isRound: isCropRund,
            maskImage: maskImage,
            angle: currentAngle,
            mirrorScale: currentMirrorScale,
            centerRatio: cropRatio.centerRatio,
            sizeRatio: cropRatio.sizeRatio,
            waterSizeRatio: .zero,
            waterCenterRatio: .zero
        )
        return cropFactor.allowCroped
    }
    
    func getVideoWaterCropOption() -> (centerRatio: CGPoint, sizeRatio: CGPoint) {
        let viewSize = contentView.size
        let controlFrame = frameView.controlView.frame
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let isUpDirection = currentAngle.truncatingRemainder(dividingBy: 360) == 0
        if !isUpDirection {
            resetVideoRotate(true)
        }
        var rect = frameView.convert(controlFrame, to: contentView)
        rect = CGRect(
            x: rect.minX * scrollView.zoomScale,
            y: rect.minY * scrollView.zoomScale,
            width: rect.width * scrollView.zoomScale,
            height: rect.height * scrollView.zoomScale
        )
        if !isUpDirection {
            resetVideoRotate(false)
        }
        CATransaction.commit()
        let centerRatio = CGPoint(x: rect.midX / viewSize.width, y: rect.midY / viewSize.height)
        let sizeRatio = CGPoint(
            x: rect.width / viewSize.width,
            y: rect.height / viewSize.height
        )
        return (centerRatio: centerRatio, sizeRatio: sizeRatio)
    }
    
    struct LastVideoFator {
        let urlConfig: EditorURLConfig
        let factor: EditorVideoFactor
        let watermarkCount: Int
        let stickerCount: Int
        let cropFactor: EditorAdjusterView.CropFactor
        let filter: VideoCompositionFilter?
        var videoResult: VideoEditedResult
    }
    
    // swiftlint:disable function_body_length
    func cropVideo(
        factor: EditorVideoFactor,
        filter: VideoCompositionFilter? = nil,
        progress: ((CGFloat) -> Void)? = nil,
        completion: @escaping (Result<VideoEditedResult, EditorError>) -> Void
    ) {
        // swiftlint:enable function_body_length
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.cropVideo(
                    factor: factor,
                    progress: progress,
                    completion: completion
                )
            }
            return
        }
        deselectedSticker()
        let editAdjustmentData = getData()
        let cropRatio = getCropOption()
        let waterRatio = getVideoWaterCropOption()
        let cropFactor = CropFactor(
            drawLayer: nil,
            canvasImage: nil,
            mosaicLayer: nil,
            stickersLayer: nil,
            isCropImage: isCropImage,
            isRound: isCropRund,
            maskImage: maskImage,
            angle: currentAngle,
            mirrorScale: currentMirrorScale,
            centerRatio: cropRatio.centerRatio,
            sizeRatio: cropRatio.sizeRatio,
            waterSizeRatio: waterRatio.sizeRatio,
            waterCenterRatio: waterRatio.centerRatio
        )
        let urlConfig: EditorURLConfig
        if let _urlConfig = self.urlConfig {
            urlConfig = _urlConfig
        }else {
            let fileName: String
            if let lastVideoFator = lastVideoFator {
                fileName = lastVideoFator.urlConfig.url.lastPathComponent
            }else {
                fileName = .fileName(suffix: "mp4")
            }
            urlConfig = .init(fileName: fileName, type: .temp)
        }
        var isDrawVideoMark = contentView.drawView.isVideoMark
        var layers: [CALayer] = []
        if contentView.drawView.count > 0 {
            contentView.drawView.isVideoMark = true
            layers.append(contentView.drawView.layer)
        }else {
            if let lastVideoFator = lastVideoFator,
               lastVideoFator.watermarkCount > 0 {
                isDrawVideoMark = false
            }else {
                isDrawVideoMark = true
            }
        }
        var isStickerVideoMark = contentView.stickerView.isVideoMark
        let stickerCount = contentView.stickerView.count
        if stickerCount > 0 {
            contentView.stickerView.isVideoMark = true
        }else {
            if let lastVideoFator = lastVideoFator,
               lastVideoFator.stickerCount > 0 {
                isStickerVideoMark = false
            }else {
                isStickerVideoMark = true
            }
        }
        let isFilter: Bool
        if lastVideoFator?.filter == nil && filter == nil {
            isFilter = false
        }else {
            isFilter = true
        }
        if let lastVideoFator = lastVideoFator,
           lastVideoFator.urlConfig.url.path == urlConfig.url.path,
           lastVideoFator.factor.isEqual(factor),
           lastVideoFator.cropFactor.isEqual(cropFactor),
           isDrawVideoMark,
           isStickerVideoMark,
           !isFilter,
           FileManager.default.fileExists(atPath: urlConfig.url.path) {
            completion(.success(lastVideoFator.videoResult))
            return
        }else {
            if FileManager.default.fileExists(atPath: urlConfig.url.path) {
                do {
                    try FileManager.default.removeItem(at: urlConfig.url)
                } catch {
                    completion(.failure(
                        EditorError.error(
                            type: .removeFile,
                            message: "删除已经存在的文件时发生错误：\(error.localizedDescription)")
                    ))
                    return
                }
            }
        }
        var watermarkImages: [UIImage] = []
        if #available(iOS 13.0, *) {
            if let canvasImage = contentView.isCanvasEmpty ? nil : contentView.canvasImage {
                watermarkImages.append(canvasImage)
            }
        }
        let watermark: EditorVideoTool.Watermark = .init(layers: layers, images: watermarkImages)
        exportVideo(
            outputURL: urlConfig.url,
            factor: factor,
            watermark: watermark,
            stickers: contentView.stickerView.getStickerInfo(),
            cropFactor: cropFactor,
            filter: filter,
            progress: progress
        ) { [weak self] in
            guard let self = self else {
                return
            }
            switch $0 {
            case .success:
                DispatchQueue.global(qos: .userInteractive).async {
                    let fileSize = urlConfig.url.fileSize
                    let videoDuration = PhotoTools.getVideoDuration(videoURL: urlConfig.url)
                    let coverImage = PhotoTools.getVideoThumbnailImage(videoURL: urlConfig.url, atTime: 0.1)
                    let videoTime = PhotoTools.transformVideoDurationToString(duration: videoDuration)
                    DispatchQueue.main.async {
                        let videoResult = VideoEditedResult(
                            urlConfig: urlConfig,
                            coverImage: coverImage,
                            fileSize: fileSize,
                            videoTime: videoTime,
                            videoDuration: videoDuration,
                            data: editAdjustmentData
                        )
                        self.lastVideoFator = .init(
                            urlConfig: urlConfig,
                            factor: factor,
                            watermarkCount: layers.count,
                            stickerCount: stickerCount,
                            cropFactor: cropFactor,
                            filter: filter,
                            videoResult: videoResult
                        )
                        completion(.success(videoResult))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
            self.videoTool = nil
        }
    }
    
    func exportVideo(
        outputURL: URL,
        factor: EditorVideoFactor,
        watermark: EditorVideoTool.Watermark,
        stickers: [EditorStickersView.Info],
        cropFactor: CropFactor,
        filter: VideoCompositionFilter? = nil,
        progress: ((CGFloat) -> Void)? = nil,
        completion: @escaping (Result<URL, EditorError>) -> Void
    ) {
        guard let avAsset = contentView.videoView.avAsset else {
            completion(.failure(EditorError.error(type: .exportFailed, message: "视频资源不存在")))
            return
        }
        videoTool?.cancelExport()
        let videoTool = EditorVideoTool(
            avAsset: avAsset,
            outputURL: outputURL,
            factor: factor,
            watermark: watermark,
            stickers: stickers,
            cropFactor: cropFactor,
            maskType: factor.maskType ?? maskType,
            filter: filter
        )
        videoTool.export(
            progressHandler: progress,
            completionHandler: completion
        )
        self.videoTool = videoTool
    }
    
    func cancelVideoCroped() {
        videoTool?.cancelExport()
        videoTool = nil
    }
}
