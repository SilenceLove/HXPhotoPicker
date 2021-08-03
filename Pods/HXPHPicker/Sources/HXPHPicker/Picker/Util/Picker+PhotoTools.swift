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
    public class func showNotAuthorizedAlert(viewController : UIViewController? ,
                                             status : PHAuthorizationStatus) {
        guard let vc = viewController else { return }
        if status == .denied ||
            status == .restricted {
            showAlert(viewController: vc, title: "无法访问相册中照片".localized, message: "当前无照片访问权限，建议前往系统设置，\n允许访问「照片」中的「所有照片」。".localized, leftActionTitle: "取消".localized, leftHandler: {_ in }, rightActionTitle: "前往系统设置".localized) { (alertAction) in
                openSettingsURL()
            }
        }
    }
    
    /// 显示没有相机权限弹窗
    public class func showNotCameraAuthorizedAlert(viewController : UIViewController?) {
        guard let vc = viewController else { return }
        showAlert(viewController: vc, title: "无法使用相机功能".localized, message: "请前往系统设置中，允许访问「相机」。".localized, leftActionTitle: "取消".localized, leftHandler: {_ in }, rightActionTitle: "前往系统设置".localized) { (alertAction) in
            openSettingsURL()
        }
    }
    
    /// 转换相册名称为当前语言
    public class func transformAlbumName(for collection: PHAssetCollection) -> String? {
        if collection.assetCollectionType == .album {
            return collection.localizedTitle
        }
        var albumName : String?
        let type = PhotoManager.shared.languageType
        if type == .system {
            albumName = collection.localizedTitle
        }else {
            if collection.localizedTitle == "最近项目" ||
                collection.localizedTitle == "最近添加"  {
                albumName = "HXAlbumRecents".localized
            }else if collection.localizedTitle == "Camera Roll" ||
                        collection.localizedTitle == "相机胶卷" {
                albumName = "HXAlbumCameraRoll".localized
            }else {
                switch collection.assetCollectionSubtype {
                case .smartAlbumUserLibrary:
                    albumName = "HXAlbumCameraRoll".localized
                    break
                case .smartAlbumVideos:
                    albumName = "HXAlbumVideos".localized
                    break
                case .smartAlbumPanoramas:
                    albumName = "HXAlbumPanoramas".localized
                    break
                case .smartAlbumFavorites:
                    albumName = "HXAlbumFavorites".localized
                    break
                case .smartAlbumTimelapses:
                    albumName = "HXAlbumTimelapses".localized
                    break
                case .smartAlbumRecentlyAdded:
                    albumName = "HXAlbumRecentlyAdded".localized
                    break
                case .smartAlbumBursts:
                    albumName = "HXAlbumBursts".localized
                    break
                case .smartAlbumSlomoVideos:
                    albumName = "HXAlbumSlomoVideos".localized
                    break
                case .smartAlbumSelfPortraits:
                    albumName = "HXAlbumSelfPortraits".localized
                    break
                case .smartAlbumScreenshots:
                    albumName = "HXAlbumScreenshots".localized
                    break
                case .smartAlbumDepthEffect:
                    albumName = "HXAlbumDepthEffect".localized
                    break
                case .smartAlbumLivePhotos:
                    albumName = "HXAlbumLivePhotos".localized
                    break
                case .smartAlbumAnimated:
                    albumName = "HXAlbumAnimated".localized
                    break
                default:
                    albumName = collection.localizedTitle
                    break
                }
            }
        }
        return albumName
    }
    public class func getVideoCoverImage(for photoAsset: PhotoAsset, completionHandler: @escaping (PhotoAsset, UIImage) -> Void) {
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
                getVideoThumbnailImage(url: url, atTime: 0.1) { (videoURL, coverImage) in
                    if photoAsset.isNetworkAsset {
                        photoAsset.networkVideoAsset?.coverImage = coverImage
                    }else {
                        photoAsset.localVideoAsset?.image = coverImage
                    }
                    completionHandler(photoAsset, coverImage)
                }
            }
        }
    }
    
    public class func getVideoDuration(for photoAsset: PhotoAsset, completionHandler: @escaping (PhotoAsset, TimeInterval) -> Void) {
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
                let avAsset = AVAsset.init(url: url)
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
    public class func transformBytesToString(bytes: Int) -> String {
        if CGFloat(bytes) >= 0.5 * 1000 * 1000 {
            return String.init(format: "%0.1fM", arguments: [CGFloat(bytes) / 1000 / 1000])
        }else if bytes >= 1000 {
            return String.init(format: "%0.0fK", arguments: [CGFloat(bytes) / 1000])
        }else {
            return String.init(format: "%dB", arguments: [bytes])
        }
    }
    
    /// 获取和微信主题一致的配置
    public class func getWXPickerConfig(isMoment: Bool = false) -> PickerConfiguration {
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
        config.albumList.tickColor = "#07C160".color
        
        config.photoList.backgroundColor = "#2E2F30".color
        config.photoList.cancelPosition = .left
        config.photoList.cancelType = .image
        
        config.photoList.titleView.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        config.photoList.titleView.arrowBackgroundColor = "#B2B2B2".color
        config.photoList.titleView.arrowColor = "#2E2F30".color
        
        config.photoList.cell.targetWidth = 250
        config.photoList.cell.selectBox.selectedBackgroundColor = "#07C160".color
        config.photoList.cell.selectBox.titleColor = .white
        
        config.photoList.cameraCell.cameraImageName = "hx_picker_photoList_photograph_white"
        
        config.photoList.bottomView.barStyle = .black
        config.photoList.bottomView.previewButtonTitleColor = .white
        
        config.photoList.bottomView.originalButtonTitleColor = .white
        config.photoList.bottomView.originalSelectBox.backgroundColor = .clear
        config.photoList.bottomView.originalSelectBox.borderColor = .white
        config.photoList.bottomView.originalSelectBox.tickColor = .white
        config.photoList.bottomView.originalSelectBox.selectedBackgroundColor = "#07C160".color
        config.photoList.bottomView.originalLoadingStyle = .white
        
        config.photoList.bottomView.finishButtonTitleColor = .white
        config.photoList.bottomView.finishButtonBackgroundColor = "#07C160".color
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
        config.previewView.selectBox.selectedBackgroundColor = "#07C160".color
        
        config.previewView.bottomView.barStyle = .black
        
        config.previewView.bottomView.originalButtonTitleColor = .white
        config.previewView.bottomView.originalSelectBox.backgroundColor = .clear
        config.previewView.bottomView.originalSelectBox.borderColor = .white
        config.previewView.bottomView.originalSelectBox.tickColor = .white
        config.previewView.bottomView.originalSelectBox.selectedBackgroundColor = "#07C160".color
        config.previewView.bottomView.originalLoadingStyle = .white
        
        config.previewView.bottomView.finishButtonTitleColor = .white
        config.previewView.bottomView.finishButtonBackgroundColor = "#07C160".color
        config.previewView.bottomView.finishButtonDisableBackgroundColor = "#666666".color.withAlphaComponent(0.3)
        
        config.previewView.bottomView.selectedViewTickColor = "#07C160".color
        
        
        #if HXPICKER_ENABLE_EDITOR
        config.previewView.bottomView.editButtonTitleColor = .white
        config.videoEditor.cropping.maximumVideoCroppingTime = 15
        config.videoEditor.cropView.finishButtonBackgroundColor = "#07C160".color
        config.videoEditor.cropView.finishButtonDarkBackgroundColor = "#07C160".color
        config.videoEditor.toolView.finishButtonBackgroundColor = "#07C160".color
        config.videoEditor.toolView.finishButtonDarkBackgroundColor = "#07C160".color
        config.videoEditor.toolView.toolSelectedColor = "#07C160".color
        config.videoEditor.toolView.musicSelectedColor = "#07C160".color
        config.videoEditor.music.tintColor = "#07C160".color
        
        config.photoEditor.toolView.toolSelectedColor = "#07C160".color
        config.photoEditor.toolView.finishButtonBackgroundColor = "#07C160".color
        config.photoEditor.toolView.finishButtonDarkBackgroundColor = "#07C160".color
        config.photoEditor.cropConfimView.finishButtonBackgroundColor = "#07C160".color
        config.photoEditor.cropConfimView.finishButtonDarkBackgroundColor = "#07C160".color
        config.photoEditor.cropping.aspectRatioSelectedColor = "#07C160".color
        config.photoEditor.filter = .init(infos: defaultFilters(),
                                                selectedColor: "#07C160".color)
        config.photoEditor.text.tintColor =  "#07C160".color
        #endif
        
        config.notAuthorized.closeButtonImageName = "hx_picker_notAuthorized_close_dark"
        config.notAuthorized.backgroundColor = "#2E2F30".color
        config.notAuthorized.titleColor = .white
        config.notAuthorized.subTitleColor = .white
        config.notAuthorized.jumpButtonTitleColor = .white
        config.notAuthorized.jumpButtonBackgroundColor = "#07C160".color
        
        return config
    }
}
