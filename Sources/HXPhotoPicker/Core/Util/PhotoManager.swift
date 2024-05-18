//
//  PhotoManager.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/29.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
#if canImport(Kingfisher)
import Kingfisher
#endif

public final class PhotoManager: NSObject {
    
    public static let shared = PhotoManager()
    
    /// 自定义语言
    public var customLanguages: [CustomLanguage] = []
    
    /// 当前是否处于暗黑模式
    public static var isDark: Bool {
        if shared.appearanceStyle == .normal {
            return false
        }
        if shared.appearanceStyle == .dark {
            return true
        }
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                return true
            }
        }
        return false
    }
    public static var HUDView: PhotoHUDProtocol.Type = ProgressHUD.self
    
    public var isDebugLogsEnabled: Bool = false
    
    /// 当前语言文件，每次创建PhotoPickerController判断是否需要重新创建
    var languageBundle: Bundle?
    /// 当前语言类型，每次创建PhotoPickerController时赋值
    var languageType: LanguageType?
    /// 当前外观样式，每次创建PhotoPickerController时赋值
    var appearanceStyle: AppearanceStyle = .varied
    
    /// 自带的bundle文件
    var bundle: Bundle?
    /// 加载指示器类型
    var indicatorType: IndicatorType = .system
    
    #if HXPICKER_ENABLE_PICKER
    
    #if canImport(Kingfisher)
    public var imageDownloader: Kingfisher.ImageDownloader?
    #endif
    
    /// 加载网络视频方式
    public var loadNetworkVideoMode: PhotoAsset.LoadNetworkVideoMode = .download
    
    var isCacheCameraAlbum: Bool = false {
        didSet {
            if isCacheCameraAlbum == oldValue {
                return
            }
            registerPhotoChangeObserver()
        }
    }
    var didRegisterObserver: Bool = false
    var firstLoadAssets: Bool = true
    var cameraAlbumResult: PHFetchResult<PHAsset>?
    var cameraAlbumResultOptions: PickerAssetOptions?
    var thumbnailLoadMode: ThumbnailLoadMode = .complete
    #endif
    
    #if HXPICKER_ENABLE_PICKER || HXPICKER_ENABLE_EDITOR
    var downloadSession: URLSession!
    var downloadTasks: [String: URLSessionDownloadTask] = [:]
    var downloadCompletions: [String: (URL?, Error?, Any?) -> Void] = [:]
    var downloadProgresss: [String: (Double, URLSessionDownloadTask) -> Void] = [:]
    var downloadFileURLs: [String: URL] = [:]
    var downloadExts: [String: Any] = [:]
    #endif
    
    #if HXPICKER_ENABLE_PICKER || HXPICKER_ENABLE_CAMERA
    var cameraPreviewImage: UIImage? = PhotoTools.getCameraPreviewImage()
    var sampleBuffer: CMSampleBuffer?
    func saveCameraPreview() {
        if let image = cameraPreviewImage {
            DispatchQueue.global().async {
                PhotoTools.saveCameraPreviewImage(image)
            }
        }
    }
    #endif
    
    #if HXPICKER_ENABLE_CAMERA && !targetEnvironment(macCatalyst)
    var cameraType: CameraController.CameraType = .normal
    #endif
    
    let uuid: String = UUID().uuidString
    
    private override init() {
        super.init()
        
        #if HXPICKER_ENABLE_PICKER || HXPICKER_ENABLE_EDITOR
        downloadSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        #endif
        createBundle()
    }
    
    @discardableResult
    func createBundle() -> Bundle? {
        if self.bundle == nil {
            #if HXPICKER_ENABLE_SPM
            if let path = Bundle.module.path(forResource: "HXPhotoPicker", ofType: "bundle") {
                self.bundle = Bundle(path: path)
            }else {
                self.bundle = Bundle.main
            }
            #else
            let bundle = Bundle(for: HXPhotoPicker.self)
            var path = bundle.path(forResource: "HXPhotoPicker", ofType: "bundle")
            if path == nil {
                let associateBundleURL = Bundle.main.url(forResource: "Frameworks", withExtension: nil)
                if let url = associateBundleURL?
                    .appendingPathComponent("HXPhotoPicker")
                    .appendingPathExtension("framework") {
                    let associateBunle = Bundle(url: url)
                    path = associateBunle?.path(forResource: "HXPhotoPicker", ofType: "bundle")
                }
            }
            if let path = path {
                self.bundle = Bundle(path: path)
            }else {
                self.bundle = Bundle.main
            }
            #endif
        }
        return self.bundle
    }
}

#if HXPICKER_ENABLE_PICKER
extension NSNotification.Name {
    static let ThumbnailLoadModeDidChange: NSNotification.Name = .init("ThumbnailLoadModeDidChange")
}
public extension PhotoManager {
    enum ThumbnailLoadMode {
        case simplify
        case complete
    }
    func thumbnailLoadModeDidChange(
        _ mode: ThumbnailLoadMode
    ) {
        if thumbnailLoadMode == mode {
            return
        }
        thumbnailLoadMode = mode
    }
}
#endif
