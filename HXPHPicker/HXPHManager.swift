//
//  HXPHManager.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2019/6/29.
//  Copyright © 2019年 洪欣. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class HXPHManager: NSObject {
    
    static let shared = HXPHManager()
    
    var bundle: Bundle?
    var languageBundle: Bundle?
    var languageType: HXPHLanguageType?
    
    private lazy var cameraAlbumLocalIdentifier : String? = {
        var identifier = UserDefaults.standard.string(forKey: "hxcameraAlbumLocalIdentifier")
        return identifier
    }()
    
    private lazy var cameraAlbumLocalIdentifierType : HXPHSelectType? = {
        var identifierType = UserDefaults.standard.integer(forKey: "hxcameraAlbumLocalIdentifierType")
        return HXPHSelectType(rawValue: identifierType)
    }()
    
    /// 获取所有资源集合
    /// - Parameters:
    ///   - showEmptyCollection: 显示空集合
    ///   - usingBlock: 枚举每一个集合
    func fetchAssetCollections(for options: PHFetchOptions, showEmptyCollection: Bool, usingBlock :@escaping ([HXPHAssetCollection])->()) {
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
                usingBlock(assetCollectionsArray);
            }
        }
    }
    
    /// 获取相机胶卷资源集合
    func fetchCameraAssetCollection(for type: HXPHSelectType, options: PHFetchOptions, completion :@escaping (HXPHAssetCollection)->()) {
        DispatchQueue.global().async {
            var useLocalIdentifier = false
            if self.cameraAlbumLocalIdentifier != nil {
                if  self.cameraAlbumLocalIdentifierType == HXPHSelectType.any ||
                    type == self.cameraAlbumLocalIdentifierType  {
                    useLocalIdentifier = true
                }
            }
            let collection : PHAssetCollection?
            if useLocalIdentifier == true {
                let identifiers : [String] = [self.cameraAlbumLocalIdentifier!]
                collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: identifiers, options: nil).firstObject
            }else {
                collection = HXPHAssetManager.fetchCameraRollAlbum(options: nil)
                UserDefaults.standard.set(collection?.localIdentifier, forKey: "hxcameraAlbumLocalIdentifier")
                UserDefaults.standard.set(type.rawValue, forKey: "hxcameraAlbumLocalIdentifierType")
            }
            let assetCollection = HXPHAssetCollection.init(collection: collection, options: options)
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
    func createLanguageBundle(languageType: HXPHLanguageType) -> Bundle? {
        if bundle == nil {
            _ = createBundle()
        }
        if self.languageType != languageType {
            languageBundle = nil
        }
        if languageBundle == nil {
            var language = Locale.preferredLanguages.first
            switch languageType {
            case HXPHLanguageType.simplifiedChinese:
                language = "zh-Hans"
                break
            case HXPHLanguageType.traditionalChinese:
                language = "zh-Hant"
                break
            case HXPHLanguageType.japanese:
                language = "ja"
                break
            case HXPHLanguageType.korean:
                language = "ko"
                break
            case HXPHLanguageType.english:
                language = "en"
                break
            default:
                if language != nil {
                    if language!.hasPrefix("zh") {
                        if language!.range(of: "Hans") != nil {
                            language = "zh-Hans"
                        }else {
                            language = "zh-Hant"
                        }
                    }else if language!.hasPrefix("ja") {
                        language = "ja"
                    }else if language!.hasPrefix("ko") {
                        language = "ko"
                    }else {
                        language = "en"
                    }
                }else {
                    language = "en"
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

class HXPHPicker: NSObject { }
