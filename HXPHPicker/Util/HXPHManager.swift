//
//  HXPHManager.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/29.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class HXPHCustomLanguage: NSObject {
    /// 语言
    /// 会与 Locale.preferredLanguages 进行匹配，匹配成功的才会使用。请确保正确性
    var language: String = ""
    /// 语言文件路径
    var languagePath: String = ""
}

class HXPHManager: NSObject {
    
    public static let shared = HXPHManager()
    
    /// 自定义语言
    public var customLanguages: [HXPHCustomLanguage] = []
    
    /// 当配置的 languageType 都不匹配时才会判断自定义语言
    /// 固定的自定义语言，不会受系统语言影响
    public var fixedCustomLanguage: HXPHCustomLanguage?
    
    public var languageBundle: Bundle?
    public var languageType: HXPHPicker.LanguageType?
    public var appearanceStyle: HXPHPicker.AppearanceStyle = .varied
    public var isDark: Bool {
        get {
            if appearanceStyle == .normal {
                return false
            }
            if appearanceStyle == .dark {
                return true
            }
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    return true
                }
            }
            return false
        }
    }
    
    var bundle: Bundle?
    
    private var isCustomLanguage: Bool = false
    private lazy var cameraAlbumLocalIdentifier : String? = {
        var identifier = UserDefaults.standard.string(forKey: HXPHPicker.CameraAlbumLocal.identifier.rawValue)
        return identifier
    }()
    
    private lazy var cameraAlbumLocalIdentifierType : HXPHPicker.SelectType? = {
        var identifierType = UserDefaults.standard.integer(forKey: HXPHPicker.CameraAlbumLocal.identifierType.rawValue)
        return HXPHPicker.SelectType(rawValue: identifierType)
    }()
    
    private lazy var cameraAlbumLocalLanguage : String? = {
        var identifierType = UserDefaults.standard.string(forKey: HXPHPicker.CameraAlbumLocal.language.rawValue)
        return identifierType
    }()
    
    /// 获取所有资源集合
    /// - Parameters:
    ///   - showEmptyCollection: 显示空集合
    ///   - completion: 完成回调
    public func fetchAssetCollections(for options: PHFetchOptions, showEmptyCollection: Bool, completion :@escaping ([HXPHAssetCollection])->()) {
        DispatchQueue.global().async {
            var assetCollectionsArray = [HXPHAssetCollection]()
            HXPHAssetManager.enumerateAllAlbums(filterInvalid: true, options: nil) { (collection) in
                let assetCollection = HXPHAssetCollection.init(collection: collection, options: options)
                if showEmptyCollection == false && assetCollection.count == 0 {
                    return
                }
                if HXPHAssetManager.collectionIsCameraRollAlbum(collection: collection) {
                    assetCollectionsArray.insert(assetCollection, at: 0);
                }else {
                    assetCollectionsArray.append(assetCollection)
                }
            }
            DispatchQueue.main.async {
                completion(assetCollectionsArray);
            }
        }
    }
    
    /// 枚举每个相册资源，
    /// - Parameters:
    ///   - showEmptyCollection: 显示空集合
    ///   - usingBlock: HXPHAssetCollection 为nil则代表结束，Bool 是否为相机胶卷
    public func fetchAssetCollections(for options: PHFetchOptions, showEmptyCollection: Bool, usingBlock :@escaping (HXPHAssetCollection?, Bool)->()) {
        HXPHAssetManager.enumerateAllAlbums(filterInvalid: true, options: nil) { (collection) in
            let assetCollection = HXPHAssetCollection.init(collection: collection, options: options)
            if showEmptyCollection == false && assetCollection.count == 0 {
                return
            }
            let isCameraRoll = HXPHAssetManager.collectionIsCameraRollAlbum(collection: collection)
            usingBlock(assetCollection, isCameraRoll);
        }
        usingBlock(nil, false);
    }
    
    /// 获取相机胶卷资源集合
    public func fetchCameraAssetCollection(for type: HXPHPicker.SelectType, options: PHFetchOptions, completion :@escaping (HXPHAssetCollection)->()) {
        DispatchQueue.global().async {
            var useLocalIdentifier = false
            let language = Locale.preferredLanguages.first
            if self.cameraAlbumLocalIdentifier != nil {
                if  (self.cameraAlbumLocalIdentifierType == .any ||
                    type == self.cameraAlbumLocalIdentifierType) &&
                    self.cameraAlbumLocalLanguage == language {
                    useLocalIdentifier = true
                }
            }
            let collection : PHAssetCollection?
            if useLocalIdentifier == true {
                let identifiers : [String] = [self.cameraAlbumLocalIdentifier!]
                collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: identifiers, options: nil).firstObject
            }else {
                collection = HXPHAssetManager.fetchCameraRollAlbum(options: nil)
                UserDefaults.standard.set(collection?.localIdentifier, forKey: HXPHPicker.CameraAlbumLocal.identifier.rawValue)
                UserDefaults.standard.set(type.rawValue, forKey: HXPHPicker.CameraAlbumLocal.identifierType.rawValue)
                UserDefaults.standard.set(language, forKey: HXPHPicker.CameraAlbumLocal.language.rawValue)
            }
            let assetCollection = HXPHAssetCollection.init(collection: collection, options: options)
            assetCollection.isCameraRoll = true
            DispatchQueue.main.async {
                completion(assetCollection)
            }
        }
    }
    
    
    private override init() {
        super.init()
        _ = createBundle()
    }
    func createBundle() -> Bundle? {
        if self.bundle == nil {
            let bundle = Bundle.init(for: HXPHPicker.self)
            var path = bundle.path(forResource: "HXPHPicker", ofType: "bundle")
            if path == nil {
                var associateBundleURL = Bundle.main.url(forResource: "Frameworks", withExtension: nil)
                if associateBundleURL != nil {
                    associateBundleURL = associateBundleURL?.appendingPathComponent("HXPHPicker")
                    associateBundleURL = associateBundleURL?.appendingPathExtension("framework")
                    let associateBunle = Bundle.init(url: associateBundleURL!)
                    path = associateBunle?.path(forResource: "HXPHPicker", ofType: "bundle")
                }
            }
            self.bundle = (path != nil) ? Bundle.init(path: path!) : Bundle.main
        }
        return self.bundle
    }
    public func createLanguageBundle(languageType: HXPHPicker.LanguageType) -> Bundle? {
        if bundle == nil {
            _ = createBundle()
        }
        if self.languageType != languageType || isCustomLanguage {
            languageBundle = nil
        }
        isCustomLanguage = false
        if languageBundle == nil {
            var language = "en"
            switch languageType {
            case .simplifiedChinese:
                language = "zh-Hans"
                break
            case .traditionalChinese:
                language = "zh-Hant"
                break
            case .japanese:
                language = "ja"
                break
            case .korean:
                language = "ko"
                break
            case .english:
                language = "en"
                break
            case .thai:
                language = "th"
                break
            case .indonesia:
                language = "id"
                break
            default:
                if let fixedLanguage = fixedCustomLanguage {
                    isCustomLanguage = true
                    languageBundle = Bundle.init(path: fixedLanguage.languagePath)
                    return languageBundle
                }
                for customLanguage in customLanguages {
                    if Locale.preferredLanguages.contains(customLanguage.language) {
                        isCustomLanguage = true
                        languageBundle = Bundle.init(path: customLanguage.languagePath)
                        return languageBundle
                    }
                }
                for preferredLanguage in Locale.preferredLanguages {
                    if preferredLanguage.hasPrefix("zh") {
                        if preferredLanguage.range(of: "Hans") != nil {
                            language = "zh-Hans"
                        }else {
                            language = "zh-Hant"
                        }
                        break
                    }else if preferredLanguage.hasPrefix("ja") {
                        language = "ja"
                        break
                    }else if preferredLanguage.hasPrefix("ko") {
                        language = "ko"
                        break
                    }else if preferredLanguage.hasPrefix("th") {
                        language = "th"
                        break
                    }else if preferredLanguage.hasPrefix("id") {
                        language = "id"
                        break
                    }
                }
            }
            let path = bundle?.path(forResource: language, ofType: "lproj")
            if path != nil {
                languageBundle = Bundle.init(path: path!)
            }
            self.languageType = languageType
        }
        return languageBundle
    }
    override class func copy() -> Any { return self }
    override class func mutableCopy() -> Any { return self }
}
