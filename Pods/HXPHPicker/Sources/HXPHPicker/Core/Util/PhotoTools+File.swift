//
//  PhotoTools+File.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/1.
//

import UIKit

extension PhotoTools {
    
    /// 获取文件大小
    /// - Parameter path: 文件路径
    /// - Returns: 文件大小
    public class func fileSize(atPath path: String) -> Int {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            do {
                let fileSize = try fileManager.attributesOfItem(atPath: path)[.size]
                if let size = fileSize as? Int {
                    return size
                }
            }catch {}
        }
        return 0
    }
    
    /// 获取文件夹里的所有文件大小
    /// - Parameter path: 文件夹路径
    /// - Returns: 文件夹大小
    public class func folderSize(atPath path: String) -> Int {
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
    public class func getSystemCacheFolderPath() -> String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last!
    }
    
    /// 获取图片缓存文件夹路径
    public class func getImageCacheFolderPath() -> String {
        var cachePath = getSystemCacheFolderPath()
        cachePath.append(contentsOf: "/com.silence.HXPHPicker/imageCache")
        return cachePath
    }
    
    /// 获取视频缓存文件夹路径
    public class func getVideoCacheFolderPath() -> String {
        var cachePath = getSystemCacheFolderPath()
        cachePath.append(contentsOf: "/com.silence.HXPHPicker/videoCache")
        return cachePath
    }
    
    public class func getAudioTmpFolderPath() -> String {
        var tmpPath = NSTemporaryDirectory()
        tmpPath.append(contentsOf: "com.silence.HXPHPicker/audioCache")
        return tmpPath
    }
    
    /// 删除缓存
    public class func removeCache() {
        removeVideoCache()
        removeAudioCache()
    }
    
    /// 删除视频缓存
    @discardableResult
    public class func removeVideoCache() -> Bool {
        return removeFile(filePath: getVideoCacheFolderPath())
    }
    
    /// 删除音频临时缓存
    @discardableResult
    public class func removeAudioCache() -> Bool {
        return removeFile(filePath: getAudioTmpFolderPath())
    }
    
    /// 获取视频缓存文件大小
    @discardableResult
    public class func getVideoCacheFileSize() -> Int {
        return folderSize(atPath: getVideoCacheFolderPath())
    }
    
    /// 获取视频缓存文件地址
    /// - Parameter key: 生成文件的key
    @discardableResult
    public class func getVideoCacheURL(for key: String) -> URL {
        var cachePath = getVideoCacheFolderPath()
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: cachePath) {
            do {
                try fileManager.createDirectory(atPath: cachePath, withIntermediateDirectories: true, attributes: nil)
            } catch {}
        }
        cachePath.append(contentsOf: "/" + key.md5 + ".mp4")
        return URL.init(fileURLWithPath: cachePath)
    }
    
    @discardableResult
    public class func getAudioTmpURL(for key: String) -> URL {
        var cachePath = getAudioTmpFolderPath()
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: cachePath) {
            try? fileManager.createDirectory(atPath: cachePath, withIntermediateDirectories: true, attributes: nil)
        }
        cachePath.append(contentsOf: "/" + key.md5 + ".mp3")
        return URL.init(fileURLWithPath: cachePath)
    }
    
    /// 视频是否有缓存
    /// - Parameter key: 对应视频的key
    @discardableResult
    public class func isCached(forVideo key: String) -> Bool {
        let fileManager = FileManager.default
        let filePath = getVideoCacheURL(for: key).path
        return fileManager.fileExists(atPath: filePath)
    }
    
    @discardableResult
    public class func isCached(forAudio key: String) -> Bool {
        let fileManager = FileManager.default
        let filePath = getAudioTmpURL(for: key).path
        return fileManager.fileExists(atPath: filePath)
    }
    
    /// 获取对应后缀的临时路径
    @discardableResult
    public class func getTmpURL(for suffix: String) -> URL {
        var tmpPath = NSTemporaryDirectory()
        tmpPath.append(contentsOf: String.fileName(suffix: suffix))
        let tmpURL = URL.init(fileURLWithPath: tmpPath)
        return tmpURL
    }
    /// 获取图片临时路径
    @discardableResult
    public class func getImageTmpURL(_ imageContentType: ImageContentType = .jpg) -> URL {
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
    public class func getVideoTmpURL() -> URL {
        return getTmpURL(for: "mp4")
    }
    /// 将UIImage转换成Data
    @discardableResult
    public class func getImageData(for image: UIImage?) -> Data? {
        if let pngData = image?.pngData() {
            return pngData
        }else if let jpegData = image?.jpegData(compressionQuality: 1) {
            return jpegData
        }
        return nil
    }
    
    @discardableResult
    class func write(
        toFile fileURL: URL? = nil,
        image: UIImage?) -> URL? {
        if let imageData = getImageData(for: image) {
            return write(toFile: fileURL, imageData: imageData)
        }
        return nil
    }
    
    @discardableResult
    class func write(
        toFile fileURL: URL? = nil,
        imageData: Data) -> URL? {
        let imageURL = fileURL == nil ? getImageTmpURL(imageData.isGif ? .gif : .jpg) : fileURL!
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
    class func copyFile(at srcURL: URL, to dstURL: URL) -> Bool {
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
    class func removeFile(fileURL: URL) -> Bool {
        removeFile(filePath: fileURL.path)
    }
    
    @discardableResult
    class func removeFile(filePath: String) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: filePath) {
                try FileManager.default.removeItem(atPath: filePath)
            }
            return true
        } catch {
            return false
        }
    }
}
