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

public final class PhotoManager: NSObject {
    
    public static let shared = PhotoManager()
    
    /// 自定义语言
    public var customLanguages: [CustomLanguage] = []
    
    /// 当配置的 languageType 都不匹配时才会判断自定义语言
    /// 固定的自定义语言，不会受系统语言影响
    public var fixedCustomLanguage: CustomLanguage?
    
    /// 当前是否处于暗黑模式
    public class var isDark: Bool {
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
    
    /// 当前语言文件，每次创建PhotoPickerController判断是否需要重新创建
    var languageBundle: Bundle?
    /// 当前语言类型，每次创建PhotoPickerController时赋值
    var languageType: LanguageType?
    /// 当前外观样式，每次创建PhotoPickerController时赋值
    var appearanceStyle: AppearanceStyle = .varied
    
    /// 自带的bundle文件
    var bundle: Bundle?
    /// 是否使用了自定义的语言
    var isCustomLanguage: Bool = false
    /// 加载指示器类型
    var indicatorType: BaseConfiguration.IndicatorType = .circle
    
    #if HXPICKER_ENABLE_PICKER
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
    lazy var downloadSession: URLSession = {
        let session = URLSession.init(configuration: .default, delegate: self, delegateQueue: nil)
        return session
    }()
    var downloadTasks: [String: URLSessionDownloadTask] = [:]
    var downloadCompletions: [String: (URL?, Error?, Any?) -> Void] = [:]
    var downloadProgresss: [String: (Double, URLSessionDownloadTask) -> Void] = [:]
    var downloadFileURLs: [String: URL] = [:]
    var downloadExts: [String: Any] = [:]
    #endif
    
    #if HXPICKER_ENABLE_EDITOR
    lazy var audioSession: AVAudioSession = {
        let session = AVAudioSession.sharedInstance()
        return session
    }()
    var audioPlayer: AVAudioPlayer?
    var audioPlayFinish: (() -> Void)?
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
    
    static let mainBundle = Bundle(for: HXPHPicker.self)
    let uuid: String = UUID().uuidString
    
    private override init() {
        super.init()
        createBundle()
    }
    
    @discardableResult
    func createBundle() -> Bundle? {
        if self.bundle == nil {
            #if HXPICKER_ENABLE_SPM
            if let path = Bundle.module.path(forResource: "HXPHPicker", ofType: "bundle") {
                self.bundle = Bundle.init(path: path)
            }else {
                self.bundle = Bundle.main
            }
            #else
            let bundle = PhotoManager.mainBundle
            var path = bundle.path(forResource: "HXPHPicker", ofType: "bundle")
            if path == nil {
                let associateBundleURL = Bundle.main.url(forResource: "Frameworks", withExtension: nil)
                if let url = associateBundleURL?
                    .appendingPathComponent("HXPHPicker")
                    .appendingPathExtension("framework") {
                    let associateBunle = Bundle(url: url)
                    path = associateBunle?.path(forResource: "HXPHPicker", ofType: "bundle")
                }
//                if associateBundleURL != nil {
//                    associateBundleURL = associateBundleURL?.appendingPathComponent("HXPHPicker")
//                    associateBundleURL = associateBundleURL?.appendingPathExtension("framework")
//                    let associateBunle = Bundle.init(url: associateBundleURL!)
//                    path = associateBunle?.path(forResource: "HXPHPicker", ofType: "bundle")
//                }
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
extension PhotoManager {
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
//        if !needReload && !forceReload {
//            return
//        }
//        NotificationCenter.default.post(
//            name: .ThumbnailLoadModeDidChange,
//            object: nil,
//            userInfo: ["needReload": forceReload ? true : needReload]
//        )
    }
}
#endif
