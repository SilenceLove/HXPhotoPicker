//
//  Picker+PhotoTools.swift
//  HXPhotoPicker
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
                title: .textNotAuthorized.alertTitle.text,
                message: .textNotAuthorized.alertMessage.text,
                leftActionTitle: .textNotAuthorized.alertLeftTitle.text,
                leftHandler: nil,
                rightActionTitle: .textNotAuthorized.alertRightTitle.text
            ) { _ in
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
                albumName = .textManager.picker.albumRecentsTitle.text
            }else if collection.localizedTitle == "Camera Roll" ||
                        collection.localizedTitle == "相机胶卷" {
                albumName = .textManager.picker.albumCameraRollTitle.text
            }else {
                switch collection.assetCollectionSubtype {
                case .smartAlbumUserLibrary:
                    albumName = .textManager.picker.albumCameraRollTitle.text
                case .smartAlbumVideos:
                    albumName = .textManager.picker.albumVideosTitle.text
                case .smartAlbumPanoramas:
                    albumName = .textManager.picker.albumPanoramasTitle.text
                case .smartAlbumFavorites:
                    albumName = .textManager.picker.albumFavoritesTitle.text
                case .smartAlbumTimelapses:
                    albumName = .textManager.picker.albumTimelapsesTitle.text
                case .smartAlbumRecentlyAdded:
                    albumName = .textManager.picker.albumRecentlyAddedTitle.text
                case .smartAlbumBursts:
                    albumName = .textManager.picker.albumBurstsTitle.text
                case .smartAlbumSlomoVideos:
                    albumName = .textManager.picker.albumSlomoVideosTitle.text
                case .smartAlbumSelfPortraits:
                    albumName = .textManager.picker.albumSelfPortraitsTitle.text
                case .smartAlbumScreenshots:
                    albumName = .textManager.picker.albumScreenshotsTitle.text
                case .smartAlbumDepthEffect:
                    albumName = .textManager.picker.albumDepthEffectTitle.text
                case .smartAlbumLivePhotos:
                    albumName = .textManager.picker.albumLivePhotosTitle.text
                case .smartAlbumAnimated:
                    albumName = .textManager.picker.albumAnimatedTitle.text
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
                if let key = videoAsset.videoURL?.absoluteString,
                   isCached(forVideo: key) {
                    url = getVideoCacheURL(for: key)
                }else {
                    url = videoAsset.videoURL
                }
            }
            if let url = url {
                getVideoThumbnailImage(url: url, atTime: 0.1) { (_, coverImage, _) in
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
    ///   - startTime: 需要裁剪的开始时间
    ///   - endTime: 需要裁剪的结束时间
    ///   - exportPreset: 导出的分辨率
    ///   - videoQuality: 导出的质量
    ///   - completion: 导出完成
    @discardableResult
    public static func exportEditVideo(
        for avAsset: AVAsset,
        outputURL: URL? = nil,
        startTime: TimeInterval,
        endTime: TimeInterval,
        exportPreset: ExportPreset = .ratio_960x540,
        videoQuality: Int = 5,
        completion: ((URL?, Error?) -> Void)?
    ) -> AVAssetExportSession? {
        let exportPresets = AVAssetExportSession.exportPresets(compatibleWith: avAsset)
        if exportPresets.contains(exportPreset.name) {
            guard let videoTrack = avAsset.tracks(withMediaType: .video).first else {
                completion?(nil, NSError(domain: "Video track is nil", code: 500, userInfo: nil))
                return nil
            }
            let videoURL = outputURL == nil ? PhotoTools.getVideoTmpURL() : outputURL
            if let exportSession = AVAssetExportSession(
                asset: avAsset,
                presetName: exportPreset.name
            ) {
                let timescale = avAsset.duration.timescale
                let start = CMTime(value: CMTimeValue(startTime * TimeInterval(timescale)), timescale: timescale)
                let timeRang: CMTimeRange
                let videoTotalSeconds = videoTrack.timeRange.duration.seconds
                if startTime + endTime > videoTotalSeconds {
                    timeRang = CMTimeRange(
                        start: start,
                        duration: CMTime(
                            seconds: videoTotalSeconds - startTime,
                            preferredTimescale: timescale
                        )
                    )
                }else {
                    let end = CMTime(value: CMTimeValue(endTime * TimeInterval(timescale)), timescale: timescale)
                    timeRang = CMTimeRange(start: start, end: end)
                }
                let supportedTypeArray = exportSession.supportedFileTypes
                exportSession.outputURL = videoURL
                if supportedTypeArray.contains(AVFileType.mp4) {
                    exportSession.outputFileType = .mp4
                }else if supportedTypeArray.isEmpty {
                    completion?(nil, PhotoError.error(type: .exportFailed, message: "不支持导出该类型视频"))
                    return nil
                }else {
                    exportSession.outputFileType = supportedTypeArray.first
                }
                exportSession.shouldOptimizeForNetworkUse = true
                if timeRang != .zero {
                    exportSession.timeRange = timeRang
                }
                if videoQuality > 0 {
                    let seconds = timeRang != .zero ? timeRang.duration.seconds : videoTotalSeconds
                    var maxSize: Int?
                    if let urlAsset = avAsset as? AVURLAsset {
                        let scale = Double(max(seconds / videoTotalSeconds, 0.4))
                        maxSize = Int(Double(urlAsset.url.fileSize) * scale)
                    }
                    exportSession.fileLengthLimit = exportSessionFileLengthLimit(
                        seconds: seconds,
                        maxSize: maxSize,
                        exportPreset: exportPreset,
                        videoQuality: videoQuality
                    )
                }
                exportSession.exportAsynchronously(completionHandler: {
                    DispatchQueue.main.async {
                        switch exportSession.status {
                        case .completed:
                            completion?(videoURL, nil)
                        case .failed, .cancelled:
                            completion?(nil, exportSession.error)
                        default: break
                        }
                    }
                })
                return exportSession
            }else {
                completion?(nil, PhotoError.error(type: .exportFailed, message: "不支持导出该类型视频"))
            }
        }else {
            completion?(nil, PhotoError.error(type: .exportFailed, message: "设备不支持导出：" + exportPreset.name))
        }
        return nil
    }
    
    // swiftlint:disable superfluous_disable_command
    /// 获取和微信主题一致的配置
    // swiftlint:enable superfluous_disable_command
    // swiftlint:disable function_body_length
    public static func getWXPickerConfig(
        isMoment: Bool = false
    ) -> PickerConfiguration {
        // swiftlint:enable function_body_length
        var config = PickerConfiguration()
        if isMoment {
            config.maximumSelectedCount = 9
            config.maximumSelectedVideoCount = 1
            config.videoSelectionTapAction = .openEditor
            config.allowSelectedTogether = false
            config.maximumSelectedVideoDuration = 60
        }else {
            config.maximumSelectedVideoDuration = 480
            config.maximumSelectedCount = 9
            config.maximumSelectedVideoCount = 0
            config.allowSelectedTogether = true
        }
        let wxColor = "#07C160".color
        config.selectOptions = [.gifPhoto, .livePhoto, .video]
        config.albumShowMode = .popup
        config.appearanceStyle = .normal
        config.navigationViewBackgroundColor = "#2E2F30".color
        config.navigationTitleColor = .white
        config.navigationTintColor = .white
        config.statusBarStyle = .lightContent
        config.navigationBarStyle = .black
        
        config.splitSeparatorLineColor = "#434344".color.withAlphaComponent(0.6)
        
        config.albumList.splitBackgroundColor = "#2E2F30".color
        config.albumList.backgroundColor = "#2E2F30".color
        config.albumList.cellHeight = 60
        config.albumList.cellBackgroundColor = "#2E2F30".color
        config.albumList.cellSelectedColor = UIColor.init(red: 0.125, green: 0.125, blue: 0.125, alpha: 1)
        config.albumList.albumNameColor = .white
        config.albumList.photoCountColor = .white
        config.albumList.separatorLineColor = "#434344".color.withAlphaComponent(0.6)
        config.albumList.tickColor = wxColor
        
        config.albumController.backgroundColor = "#2E2F30".color
        config.albumController.cellBackgroundColor = "#2E2F30".color
        config.albumController.cellSelectedColor = UIColor.init(red: 0.125, green: 0.125, blue: 0.125, alpha: 1)
        config.albumController.albumNameColor = .white
        config.albumController.photoCountColor = .white
        config.albumController.headerTitleColor = .white
        config.albumController.headerButtonTitleColor = wxColor
        config.albumController.mediaTitleColor = wxColor
        config.albumController.mediaCountColor = .white
        config.albumController.separatorLineColor = "#434344".color.withAlphaComponent(0.6)
        config.albumController.imageColor = wxColor
        config.albumController.arrowColor = .white
        
        config.photoList.backgroundColor = "#2E2F30".color
        config.photoList.leftNavigationItems = [PhotoImageCancelItemView.self]
        config.photoList.rightNavigationItems = [PhotoPickerFilterItemView.self]
        
        config.photoList.titleView.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        config.photoList.titleView.arrow.backgroundColor = "#B2B2B2".color
        config.photoList.titleView.arrow.arrowColor = "#2E2F30".color
        
        config.photoList.cell.customSelectableCellClass = PhotoPickerWeChatViewCell.self
        config.photoList.cell.selectBox.selectedBackgroundColor = wxColor
        config.photoList.cell.selectBox.titleColor = .white
        config.photoList.cell.selectBox.style = .tick
        config.photoList.cell.selectBox.size = CGSize(width: 23, height: 23)
        
        config.photoList.cell.kf_indicatorColor = .white
        
        config.photoList.cameraCell.backgroundColor = "#404040".color
        config.photoList.cameraCell.cameraImageName = "hx_picker_photoList_photograph_white"
        
        config.photoList.limitCell.backgroundColor = "#404040".color
        config.photoList.limitCell.lineColor = .white
        config.photoList.limitCell.titleColor = .white
        config.photoList.assetNumber.textColor = "#ffffff".color
        config.photoList.assetNumber.filterTitleColor = "#ffffff".color
        config.photoList.assetNumber.filterContentColor = wxColor
        
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
        config.previewView.livePhotoMark.blurStyle = .dark
        config.previewView.livePhotoMark.textColor = "#ffffff".color
        config.previewView.livePhotoMark.imageColor = "#ffffff".color
        config.previewView.livePhotoMark.mutedImageColor = "#ffffff".color
        config.previewView.HDRMark.blurStyle = .dark
        config.previewView.HDRMark.imageColor = "#ffffff".color
        
        config.previewView.bottomView.barStyle = .black
        config.previewView.bottomView.originalButtonTitleColor = .white
        config.previewView.bottomView.originalSelectBox.backgroundColor = .clear
        config.previewView.bottomView.originalSelectBox.borderColor = .white
        config.previewView.bottomView.originalSelectBox.tickColor = .white
        config.previewView.bottomView.originalSelectBox.selectedBackgroundColor = wxColor
        #if targetEnvironment(macCatalyst)
        config.previewView.bottomView.originalLoadingStyle = UIActivityIndicatorView.Style.medium
        #else
        config.previewView.bottomView.originalLoadingStyle = .white
        #endif
        config.previewView.bottomView.finishButtonTitleColor = .white
        config.previewView.bottomView.finishButtonBackgroundColor = wxColor
        config.previewView.bottomView.finishButtonDisableBackgroundColor = "#666666".color.withAlphaComponent(0.3)
        
        config.previewView.bottomView.previewListTickColor = .white
        config.previewView.bottomView.previewListTickBgColor = wxColor
        config.previewView.bottomView.selectedViewTickColor = wxColor
        config.previewView.disableFinishButtonWhenNotSelected = true
        
        #if HXPICKER_ENABLE_EDITOR
        config.previewView.bottomView.editButtonTitleColor = .white
        config.editor.video.cropTime.maximumTime = 60
        #endif
        
        #if HXPICKER_ENABLE_CAMERA && !targetEnvironment(macCatalyst)
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
        }else {
            var cameraConfig = CameraConfiguration()
            cameraConfig.videoMaximumDuration = 60
            cameraConfig.tintColor = wxColor
            cameraConfig.modalPresentationStyle = .fullScreen
            config.photoList.cameraType = .custom(cameraConfig)
        }
        #endif
        
        config.notAuthorized.closeButtonImageName = "hx_picker_notAuthorized_close_dark"
        config.notAuthorized.closeButtonColor = nil
        config.notAuthorized.closeButtonDarkColor = nil
        config.notAuthorized.backgroundColor = "#2E2F30".color
        config.notAuthorized.titleColor = .white
        config.notAuthorized.subTitleColor = .white
        config.notAuthorized.jumpButtonTitleColor = .white
        config.notAuthorized.jumpButtonBackgroundColor = wxColor
        
        return config
    }
    
    public static var redBookConfig: PickerConfiguration {
        var config = getWXPickerConfig()
        config.modalPresentationStyle = .fullScreen
        config.appearanceStyle = .normal
        config.selectOptions = [.photo, .gifPhoto, .livePhoto, .video]
        config.albumShowMode = .popup
        config.navigationTitleColor = .white
        config.navigationTintColor = .white
        config.statusBarStyle = .lightContent
        config.navigationBarStyle = .black
        config.navigationViewBackgroundColor = .black
        config.maximumSelectedVideoDuration = 0
        config.maximumSelectedCount = 9
        config.maximumSelectedVideoCount = 0
        config.allowSelectedTogether = true
        config.isFetchDeatilsAsset = true
        
        let redColor = "#FE2443".color
        config.albumList.tickColor = redColor
        
        config.albumController.headerButtonTitleColor = redColor
        config.albumController.mediaTitleColor = redColor
        config.albumController.imageColor = redColor
        
        config.photoList.listView = PhotoPickerPageViewController.self
        config.photoList.allowSwipeToSelect = false
        config.photoList.backgroundColor = .black
        config.photoList.leftNavigationItems = [PhotoImageCancelItemView.self]
        config.photoList.rightNavigationItems = []
        config.photoList.sort = .desc
        config.photoList.allowAddCamera = false
        config.photoList.allowAddLimit = false
        
        config.photoList.titleView.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        config.photoList.titleView.arrow.backgroundColor = .clear
        config.photoList.titleView.arrow.arrowColor = .white
        
        config.photoList.cell.customSelectableCellClass = nil
        config.photoList.cell.selectBox.selectedBackgroundColor = redColor
        config.photoList.cell.selectBox.titleColor = .white
        config.photoList.cell.selectBox.style = .number
        
        config.photoList.assetNumber.filterContentColor = redColor
        
        config.photoList.bottomView.finishButtonBackgroundColor = redColor
        config.photoList.bottomView.promptIconColor = redColor
        config.photoList.bottomView.promptArrowColor = redColor
        
        config.photoList.bottomView.originalSelectBox.selectedBackgroundColor = redColor
        
        config.previewView.selectBox.selectedBackgroundColor = redColor
        config.previewView.bottomView.originalSelectBox.selectedBackgroundColor = redColor
        config.previewView.bottomView.finishButtonBackgroundColor = redColor
        config.previewView.bottomView.selectedViewTickColor = redColor
        config.previewView.bottomView.previewListTickColor = .white
        config.previewView.bottomView.previewListTickBgColor = redColor
        
        #if HXPICKER_ENABLE_EDITOR
        config.editor.video.cropTime.maximumTime = 0
        #endif
        
        #if HXPICKER_ENABLE_CAMERA && !targetEnvironment(macCatalyst)
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
        }else {
            var cameraConfig = CameraConfiguration()
            cameraConfig.tintColor = redColor
            cameraConfig.modalPresentationStyle = .fullScreen
            config.photoList.cameraType = .custom(cameraConfig)
        }
        #endif
        
        config.notAuthorized.closeButtonColor = redColor
        config.notAuthorized.jumpButtonBackgroundColor = redColor
        return config
        
    }
}
