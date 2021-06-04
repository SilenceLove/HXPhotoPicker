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

public class PhotoManager: NSObject {
    
    public static let shared = PhotoManager()
    
    /// 自定义语言
    public var customLanguages: [CustomLanguage] = []
    
    /// 当配置的 languageType 都不匹配时才会判断自定义语言
    /// 固定的自定义语言，不会受系统语言影响
    public var fixedCustomLanguage: CustomLanguage?
    
    /// 当前是否处于暗黑模式
    public class var isDark: Bool {
        get {
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
    
    private lazy var downloadSession: URLSession = {
        let session = URLSession.init(configuration: .default, delegate: self, delegateQueue: nil)
        
        return session
    }()
    
    var downloadTasks: [String : URLSessionDownloadTask] = [:]
    
    var downloadCompletions: [String : (URL?, Error?) -> Void] = [:]
    
    var downloadProgresss: [String : (Double, URLSessionDownloadTask) -> Void] = [:]
    
    @discardableResult
    public func downloadTask(with url: URL,
                      progress: @escaping (Double, URLSessionDownloadTask) -> Void,
                      completionHandler: @escaping (URL?, Error?) -> Void) -> URLSessionDownloadTask {
        let key = url.absoluteString
        downloadProgresss[key] = progress
        downloadCompletions[key] = completionHandler
        if let task = downloadTasks[key] {
            if task.state == .suspended {
                task.resume()
                return task
            }
        } 
        let task = downloadSession.downloadTask(with: url)
        downloadTasks[key] = task
        task.resume()
        return task
    }
    
    public func suspendTask(_ url: URL) {
        let key = url.absoluteString
        let task = downloadTasks[key]
        if task?.state.rawValue == 1 {
            return
        }
        task?.suspend()
        downloadCompletions.removeValue(forKey: key)
        downloadProgresss.removeValue(forKey: key)
    }
    
    public func removeTask(_ url: URL) {
        let key = url.absoluteString
        let task = downloadTasks[key]
        task?.cancel()
        downloadCompletions.removeValue(forKey: key)
        downloadProgresss.removeValue(forKey: key)
        downloadTasks.removeValue(forKey: key)
    }
    
    private override init() {
        super.init()
        self.createBundle()
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
            #endif
        }
        return self.bundle
    }
}
