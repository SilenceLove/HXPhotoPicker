//
//  PhotoTools+File.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/1.
//

import UIKit

public extension PhotoTools {
    
    /// 获取文件大小
    /// - Parameter path: 文件路径
    /// - Returns: 文件大小
    static func fileSize(atPath path: String) -> Int {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            let fileSize = try? fileManager.attributesOfItem(atPath: path)[.size]
            if let size = fileSize as? Int {
                return size
            }
        }
        return 0
    }
    
    /// 获取文件夹里的所有文件大小
    /// - Parameter path: 文件夹路径
    /// - Returns: 文件夹大小
    static func folderSize(atPath path: String) -> Int {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) { return 0 }
        let childFiles = fileManager.subpaths(atPath: path)
        var folderSize = 0
        childFiles?.forEach({ (fileName) in
            let fileAbsolutePath = path + "/" + fileName
            folderSize += fileSize(atPath: fileAbsolutePath)
        })
        return folderSize
    }
    
    /// 获取系统缓存文件夹路径
    static func getSystemCacheFolderPath() -> String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last!
    }
    
    /// 获取图片缓存文件夹路径
    static func getImageCacheFolderPath() -> String {
        var cachePath = getSystemCacheFolderPath()
        cachePath.append(contentsOf: "/com.silence.HXPHPicker/imageCache")
        folderExists(atPath: cachePath)
        return cachePath
    }
    
    /// 获取视频缓存文件夹路径
    static func getVideoCacheFolderPath() -> String {
        var cachePath = getSystemCacheFolderPath()
        cachePath.append(contentsOf: "/com.silence.HXPHPicker/videoCache")
        folderExists(atPath: cachePath)
        return cachePath
    }
    
    static func getAudioTmpFolderPath() -> String {
        var tmpPath = NSTemporaryDirectory()
        tmpPath.append(contentsOf: "com.silence.HXPHPicker/audioCache")
        folderExists(atPath: tmpPath)
        return tmpPath
    }
    
    static func getLivePhotoImageCacheFolderPath() -> String {
        var cachePath = getImageCacheFolderPath()
        cachePath.append(contentsOf: "/LivePhoto")
        folderExists(atPath: cachePath)
        return cachePath
    }
    
    static func getLivePhotoVideoCacheFolderPath() -> String {
        var cachePath = getVideoCacheFolderPath()
        cachePath.append(contentsOf: "/LivePhoto")
        folderExists(atPath: cachePath)
        return cachePath
    }
    
    /// 删除缓存
    static func removeCache() {
        removeVideoCache()
        removeImageCache()
        removeAudioCache()
    }
    
    /// 删除视频缓存
    @discardableResult
    static func removeVideoCache() -> Bool {
        return removeFile(filePath: getVideoCacheFolderPath())
    }
    
    /// 删除图片缓存
    @discardableResult
    static func removeImageCache() -> Bool {
        return removeFile(filePath: getImageCacheFolderPath())
    }
    
    /// 删除音频临时缓存
    @discardableResult
    static func removeAudioCache() -> Bool {
        return removeFile(filePath: getAudioTmpFolderPath())
    }
    
    /// 获取视频缓存文件大小
    @discardableResult
    static func getVideoCacheFileSize() -> Int {
        return folderSize(atPath: getVideoCacheFolderPath())
    }
    
    /// 获取视频缓存文件地址
    /// - Parameter key: 生成文件的key
    @discardableResult
    static func getVideoCacheURL(for key: String) -> URL {
        var cachePath = getVideoCacheFolderPath()
        cachePath.append(contentsOf: "/" + key.md5 + ".mp4")
        return URL.init(fileURLWithPath: cachePath)
    }
    
    @discardableResult
    static func getAudioTmpURL(for key: String) -> URL {
        var cachePath = getAudioTmpFolderPath()
        cachePath.append(contentsOf: "/" + key.md5 + ".mp3")
        return URL.init(fileURLWithPath: cachePath)
    }
    
    /// 视频是否有缓存
    /// - Parameter key: 对应视频的key
    @discardableResult
    static func isCached(forVideo key: String) -> Bool {
        let fileManager = FileManager.default
        let filePath = getVideoCacheURL(for: key).path
        return fileManager.fileExists(atPath: filePath)
    }
    
    @discardableResult
    static func isCached(forAudio key: String) -> Bool {
        let fileManager = FileManager.default
        let filePath = getAudioTmpURL(for: key).path
        return fileManager.fileExists(atPath: filePath)
    }
    
    /// 获取对应后缀的临时路径
    @discardableResult
    static func getTmpURL(for suffix: String) -> URL {
        var tmpPath = NSTemporaryDirectory()
        tmpPath.append(contentsOf: String.fileName(suffix: suffix))
        let tmpURL = URL.init(fileURLWithPath: tmpPath)
        return tmpURL
    }
    /// 获取图片临时路径
    @discardableResult
    static func getImageTmpURL(_ imageContentType: ImageContentType = .jpg) -> URL {
        var suffix: String
        switch imageContentType {
        case .jpg:
            suffix = "jpeg"
        case .png:
            suffix = "png"
        case .gif:
            suffix = "gif"
        default:
            suffix = "jpeg"
        }
        return getTmpURL(for: suffix)
    }
    /// 获取视频临时路径
    @discardableResult
    static func getVideoTmpURL() -> URL {
        return getTmpURL(for: "mp4")
    }
    /// 将UIImage转换成Data
    @discardableResult
    static func getImageData(for image: UIImage?) -> Data? {
        if let pngData = image?.pngData() {
            return pngData
        }else if let jpegData = image?.jpegData(compressionQuality: 1) {
            return jpegData
        }
        return nil
    }
    
    @discardableResult
    static func write(
        toFile fileURL: URL? = nil,
        image: UIImage?) -> URL? {
        if let imageData = getImageData(for: image) {
            return write(toFile: fileURL, imageData: imageData)
        }
        return nil
    }
    
    @discardableResult
    static func write(
        toFile fileURL: URL? = nil,
        imageData: Data) -> URL? {
        let imageURL = fileURL == nil ? getImageTmpURL(imageData.isGif ? .gif : .png) : fileURL!
        do {
            if FileManager.default.fileExists(atPath: imageURL.path) {
                try FileManager.default.removeItem(at: imageURL)
            }
            try imageData.write(to: imageURL)
            return imageURL
        } catch {
            return nil
        }
    }
    
    @discardableResult
    static func copyFile(at srcURL: URL, to dstURL: URL) -> Bool {
        if srcURL.path == dstURL.path {
            return true
        }
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    static func removeFile(fileURL: URL) -> Bool {
        removeFile(filePath: fileURL.path)
    }
    
    @discardableResult
    static func removeFile(filePath: String) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: filePath) {
                try FileManager.default.removeItem(atPath: filePath)
            }
            return true
        } catch {
            return false
        }
    }
    
    static func folderExists(atPath path: String) {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }
}
