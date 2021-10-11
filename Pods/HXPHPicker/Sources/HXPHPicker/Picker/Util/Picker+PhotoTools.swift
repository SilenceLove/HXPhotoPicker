//
//  Picker+PhotoTools.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/7.
//

import UIKit
import Photos

extension PhotoTools {
    
    /// 显示没有权限的弹窗
    /// - Parameters:
    ///   - viewController: 需要弹窗的viewController
    ///   - status: 权限类型
    static func showNotAuthorizedAlert(
        viewController: UIViewController?,
        status: PHAuthorizationStatus
    ) {
        guard let vc = viewController else { return }
        if status == .denied ||
            status == .restricted {
            showAlert(
                viewController: vc,
                title: "无法访问相册中照片".localized,
                message: "当前无照片访问权限，建议前往系统设置，\n允许访问「照片」中的「所有照片」。".localized,
                leftActionTitle: "取消".localized,
                leftHandler: {_ in },
                rightActionTitle: "前往系统设置".localized) { (alertAction) in
                openSettingsURL()
            }
        }
    }
    
    /// 转换相册名称为当前语言
    static func transformAlbumName(
        for collection: PHAssetCollection
    ) -> String? {
        if collection.assetCollectionType == .album {
            return collection.localizedTitle
        }
        var albumName: String?
        let type = PhotoManager.shared.languageType
        if type == .system {
            albumName = collection.localizedTitle
        }else {
            if collection.localizedTitle == "最近项目" ||
                collection.localizedTitle == "最近添加" {
                albumName = "HXAlbumRecents".localized
            }else if collection.localizedTitle == "Camera Roll" ||
                        collection.localizedTitle == "相机胶卷" {
                albumName = "HXAlbumCameraRoll".localized
            }else {
                switch collection.assetCollectionSubtype {
                case .smartAlbumUserLibrary:
                    albumName = "HXAlbumCameraRoll".localized
                case .smartAlbumVideos:
                    albumName = "HXAlbumVideos".localized
                case .smartAlbumPanoramas:
                    albumName = "HXAlbumPanoramas".localized
                case .smartAlbumFavorites:
                    albumName = "HXAlbumFavorites".localized
                case .smartAlbumTimelapses:
                    albumName = "HXAlbumTimelapses".localized
                case .smartAlbumRecentlyAdded:
                    albumName = "HXAlbumRecentlyAdded".localized
                case .smartAlbumBursts:
                    albumName = "HXAlbumBursts".localized
                case .smartAlbumSlomoVideos:
                    albumName = "HXAlbumSlomoVideos".localized
                case .smartAlbumSelfPortraits:
                    albumName = "HXAlbumSelfPortraits".localized
                case .smartAlbumScreenshots:
                    albumName = "HXAlbumScreenshots".localized
                case .smartAlbumDepthEffect:
                    albumName = "HXAlbumDepthEffect".localized
                case .smartAlbumLivePhotos:
                    albumName = "HXAlbumLivePhotos".localized
                case .smartAlbumAnimated:
                    albumName = "HXAlbumAnimated".localized
                default:
                    albumName = collection.localizedTitle
                }
            }
        }
        return albumName
    }
    static func getVideoCoverImage(
        for photoAsset: PhotoAsset,
        completionHandler: @escaping (PhotoAsset, UIImage?) -> Void) {
        if photoAsset.mediaType == .video {
            var url: URL?
            if let videoAsset = photoAsset.localVideoAsset,
               photoAsset.isLocalAsset {
                if let coverImage = videoAsset.image {
                    completionHandler(photoAsset, coverImage)
                    return
                }
                url = videoAsset.videoURL
            }else if let videoAsset = photoAsset.networkVideoAsset,
                     photoAsset.isNetworkAsset {
                if let coverImage = videoAsset.coverImage {
                    completionHandler(photoAsset, coverImage)
                    return
                }
                let key = videoAsset.videoURL.absoluteString
                if isCached(forVideo: key) {
                    url = getVideoCacheURL(for: key)
                }else {
                    url = videoAsset.videoURL
                }
            }
            if let url = url {
                getVideoThumbnailImage(url: url, atTime: 0.1) { (videoURL, coverImage, result) in
                    if photoAsset.isNetworkAsset {
                        photoAsset.networkVideoAsset?.coverImage = coverImage
                    }else {
                        photoAsset.localVideoAsset?.image = coverImage
                    }
                    completionHandler(photoAsset, coverImage)
                }
            }else {
                completionHandler(photoAsset, nil)
            }
        }
    }
    
    /// 导出编辑视频
    /// - Parameters:
    ///   - avAsset: 视频对应的 AVAsset 数据
    ///   - outputURL: 指定视频导出的地址，为nil时默认为临时目录
    ///   - timeRang: 需要裁剪的时间区域
    ///   - overlayImage: 贴纸
    ///   - audioURL: 需要添加的音频地址
    ///   - audioVolume: 需要添加的音频音量
    ///   - originalAudioVolume: 视频原始音频音量
    ///   - presentName: 导出的质量
    ///   - completion: 导出完成
    @discardableResult
    public static func exportEditVideo(
        for avAsset: AVAsset,
        outputURL: URL? = nil,
        startTime: TimeInterval,
        endTime: TimeInterval,
        exportPreset: ExportPreset = .ratio_960x540,
        videoQuality: Int = 5,
        completion:
            @escaping (URL?, Error?) -> Void) -> AVAssetExportSession? {
        if AVAssetExportSession.exportPresets(
            compatibleWith: avAsset).contains(exportPreset.name) {
            let videoURL = outputURL == nil ? PhotoTools.getVideoTmpURL() : outputURL
            if let exportSession = AVAssetExportSession(
                asset: avAsset,
                presetName: exportPreset.name) {
                let timescale = avAsset.duration.timescale
                let start = CMTime(value: CMTimeValue(startTime * TimeInterval(timescale)), timescale: timescale)
                let end = CMTime(value: CMTimeValue(endTime * TimeInterval(timescale)), timescale: timescale)
                let timeRang = CMTimeRange(start: start, end: end)
                
                let supportedTypeArray = exportSession.supportedFileTypes
                exportSession.outputURL = videoURL
                if supportedTypeArray.contains(AVFileType.mp4) {
                    exportSession.outputFileType = .mp4
                }else if supportedTypeArray.isEmpty {
                    completion(nil, PhotoError.error(type: .exportFailed, message: "不支持导出该类型视频"))
                    return nil
                }else {
                    exportSession.outputFileType = supportedTypeArray.first
                }
                exportSession.shouldOptimizeForNetworkUse = true
                if timeRang != .zero {
                    exportSession.timeRange = timeRang
                }
                if videoQuality > 0 {
                    exportSession.fileLengthLimit = exportSessionFileLengthLimit(
                        seconds: avAsset.duration.seconds,
                        exportPreset: exportPreset,
                        videoQuality: videoQuality
                    )
                }
                exportSession.exportAsynchronously(completionHandler: {
                    DispatchQueue.main.async {
                        switch exportSession.status {
                        case .completed:
                            completion(videoURL, nil)
                        case .failed, .cancelled:
                            completion(nil, exportSession.error)
                        default: break
                        }
                    }
                })
                return exportSession
            }else {
                completion(nil, PhotoError.error(type: .exportFailed, message: "不支持导出该类型视频"))
                return nil
            }
        }else {
            completion(nil, PhotoError.error(type: .exportFailed, message: "设备不支持导出：" + exportPreset.name))
            return nil
        }
    }
    
    public static func getVideoDuration(
        for photoAsset: PhotoAsset,
        completionHandler:
            @escaping (PhotoAsset, TimeInterval) -> Void
    ) {
        if photoAsset.mediaType == .video {
            var url: URL?
            if let videoAsset = photoAsset.localVideoAsset,
               photoAsset.isLocalAsset {
                if videoAsset.duration > 0 {
                    completionHandler(photoAsset, videoAsset.duration)
                    return
                }
                url = videoAsset.videoURL
            }else if let videoAsset = photoAsset.networkVideoAsset,
                     photoAsset.mediaSubType.isNetwork {
                if videoAsset.duration > 0 {
                    completionHandler(photoAsset, videoAsset.duration)
                    return
                }
                let key = videoAsset.videoURL.absoluteString
                if isCached(forVideo: key) {
                    url = getVideoCacheURL(for: key)
                }else {
                    url = videoAsset.videoURL
                }
            }
            if let url = url {
                let avAsset = AVURLAsset(url: url)
                avAsset.loadValuesAsynchronously(forKeys: ["duration"]) {
                    let duration = avAsset.duration.seconds
                    if photoAsset.isNetworkAsset {
                        photoAsset.networkVideoAsset?.duration = duration
                    }else {
                        photoAsset.localVideoAsset?.duration = duration
                    }
                    photoAsset.updateVideoDuration(duration)
                    DispatchQueue.main.async {
                        completionHandler(photoAsset, duration)
                    }
                }
            }
        }
    }
    
    /// 将字节转换成字符串
    static func transformBytesToString(bytes: Int) -> String {
        if CGFloat(bytes) >= 0.5 * 1000 * 1000 {
            return String.init(format: "%0.1fM", arguments: [CGFloat(bytes) / 1000 / 1000])
        }else if bytes >= 1000 {
            return String.init(format: "%0.0fK", arguments: [CGFloat(bytes) / 1000])
        }else {
            return String.init(format: "%dB", arguments: [bytes])
        }
    }
    
    /// 获取和微信主题一致的配置
    // swiftlint:disable function_body_length
    public static func getWXPickerConfig(isMoment: Bool = false) -> PickerConfiguration {
        // swiftlint:enable function_body_length
        let config = PickerConfiguration.init()
        if isMoment {
            config.maximumSelectedCount = 9
            config.maximumSelectedVideoCount = 1
            config.videoSelectionTapAction = .openEditor
            config.allowSelectedTogether = false
            config.maximumSelectedVideoDuration = 15
        }else {
            config.maximumSelectedVideoDuration = 480
            config.maximumSelectedCount = 9
            config.maximumSelectedVideoCount = 0
            config.allowSelectedTogether = true
        }
        let wxColor = "#07C160".color
        config.selectOptions = [.gifPhoto, .video]
        config.albumShowMode = .popup
        config.appearanceStyle = .normal
        config.navigationViewBackgroundColor = "#2E2F30".color
        config.navigationTitleColor = .white
        config.navigationTintColor = .white
        config.statusBarStyle = .lightContent
        config.navigationBarStyle = .black
        
        config.albumList.backgroundColor = "#2E2F30".color
        config.albumList.cellHeight = 60
        config.albumList.cellBackgroundColor = "#2E2F30".color
        config.albumList.cellSelectedColor = UIColor.init(red: 0.125, green: 0.125, blue: 0.125, alpha: 1)
        config.albumList.albumNameColor = .white
        config.albumList.photoCountColor = .white
        config.albumList.separatorLineColor = "#434344".color.withAlphaComponent(0.6)
        config.albumList.tickColor = wxColor
        
        config.photoList.backgroundColor = "#2E2F30".color
        config.photoList.cancelPosition = .left
        config.photoList.cancelType = .image
        
        config.photoList.titleView.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        config.photoList.titleView.arrow.backgroundColor = "#B2B2B2".color
        config.photoList.titleView.arrow.arrowColor = "#2E2F30".color
        
        config.photoList.cell.selectBox.selectedBackgroundColor = wxColor
        config.photoList.cell.selectBox.titleColor = .white
        
        config.photoList.cameraCell.cameraImageName = "hx_picker_photoList_photograph_white"
        
        config.photoList.bottomView.barStyle = .black
        config.photoList.bottomView.previewButtonTitleColor = .white
        
        config.photoList.bottomView.originalButtonTitleColor = .white
        config.photoList.bottomView.originalSelectBox.backgroundColor = .clear
        config.photoList.bottomView.originalSelectBox.borderColor = .white
        config.photoList.bottomView.originalSelectBox.tickColor = .white
        config.photoList.bottomView.originalSelectBox.selectedBackgroundColor = wxColor
        config.photoList.bottomView.originalLoadingStyle = .white
        
        config.photoList.bottomView.finishButtonTitleColor = .white
        config.photoList.bottomView.finishButtonBackgroundColor = wxColor
        config.photoList.bottomView.finishButtonDisableBackgroundColor = "#666666".color.withAlphaComponent(0.3)
        
        config.photoList.bottomView.promptTitleColor = UIColor.white.withAlphaComponent(0.6)
        config.photoList.bottomView.promptIconColor = "#f5a623".color
        config.photoList.bottomView.promptArrowColor = UIColor.white.withAlphaComponent(0.6)
        
        config.photoList.emptyView.titleColor = "#ffffff".color
        config.photoList.emptyView.subTitleColor = .lightGray
        
        config.previewView.cancelType = .image
        config.previewView.cancelPosition = .left
        config.previewView.backgroundColor = .black
        config.previewView.selectBox.tickColor = .white
        config.previewView.selectBox.selectedBackgroundColor = wxColor
        
        config.previewView.bottomView.barStyle = .black
        
        config.previewView.bottomView.originalButtonTitleColor = .white
        config.previewView.bottomView.originalSelectBox.backgroundColor = .clear
        config.previewView.bottomView.originalSelectBox.borderColor = .white
        config.previewView.bottomView.originalSelectBox.tickColor = .white
        config.previewView.bottomView.originalSelectBox.selectedBackgroundColor = wxColor
        config.previewView.bottomView.originalLoadingStyle = .white
        
        config.previewView.bottomView.finishButtonTitleColor = .white
        config.previewView.bottomView.finishButtonBackgroundColor = wxColor
        config.previewView.bottomView.finishButtonDisableBackgroundColor = "#666666".color.withAlphaComponent(0.3)
        
        config.previewView.bottomView.selectedViewTickColor = wxColor
        
        #if HXPICKER_ENABLE_EDITOR
        config.previewView.bottomView.editButtonTitleColor = .white
        
        config.videoEditor.cropping.maximumVideoCroppingTime = 15
        config.videoEditor.cropView.finishButtonBackgroundColor = wxColor
        config.videoEditor.cropView.finishButtonDarkBackgroundColor = wxColor
        config.videoEditor.toolView.finishButtonBackgroundColor = wxColor
        config.videoEditor.toolView.finishButtonDarkBackgroundColor = wxColor
        config.videoEditor.toolView.toolSelectedColor = wxColor
        config.videoEditor.toolView.musicSelectedColor = wxColor
        config.videoEditor.music.tintColor = wxColor
        config.videoEditor.text.tintColor = wxColor
        
        config.photoEditor.toolView.toolSelectedColor = wxColor
        config.photoEditor.toolView.finishButtonBackgroundColor = wxColor
        config.photoEditor.toolView.finishButtonDarkBackgroundColor = wxColor
        config.photoEditor.cropConfimView.finishButtonBackgroundColor = wxColor
        config.photoEditor.cropConfimView.finishButtonDarkBackgroundColor = wxColor
        config.photoEditor.cropping.aspectRatioSelectedColor = wxColor
        config.photoEditor.filter = .init(
            infos: defaultFilters(),
            selectedColor: wxColor
        )
        config.photoEditor.text.tintColor = wxColor
        #endif
        
        #if HXPICKER_ENABLE_CAMERA
        let cameraConfig = CameraConfiguration()
        cameraConfig.videoMaximumDuration = 15
        cameraConfig.tintColor = wxColor
        config.photoList.cameraType = .custom(cameraConfig)
        #endif
        
        config.notAuthorized.closeButtonImageName = "hx_picker_notAuthorized_close_dark"
        config.notAuthorized.backgroundColor = "#2E2F30".color
        config.notAuthorized.titleColor = .white
        config.notAuthorized.subTitleColor = .white
        config.notAuthorized.jumpButtonTitleColor = .white
        config.notAuthorized.jumpButtonBackgroundColor = wxColor
        
        return config
    }
}
