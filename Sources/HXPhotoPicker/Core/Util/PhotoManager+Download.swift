//
//  PhotoManager+Download.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/6/3.
//

import UIKit
import CoreServices
import UniformTypeIdentifiers

#if HXPICKER_ENABLE_PICKER || HXPICKER_ENABLE_EDITOR
extension PhotoManager: URLSessionDownloadDelegate {
    
    @discardableResult
    public func downloadTask(
        with url: URL,
        toFile fileURL: URL? = nil,
        ext: Any? = nil,
        progress: ((Double, URLSessionDownloadTask) -> Void)? = nil,
        completionHandler: @escaping (URL?, Error?, Any?) -> Void
    ) -> URLSessionDownloadTask {
        let key = url.absoluteString
        let urlType = getURLType(for: url)
        if urlType == .video && PhotoTools.isCached(forVideo: key) {
            let videoURL = PhotoTools.getVideoCacheURL(for: key)
            if let fileURL = fileURL,
               videoURL.absoluteString != fileURL.absoluteString {
                PhotoTools.copyFile(at: videoURL, to: fileURL)
                completionHandler(fileURL, nil, ext)
            }else {
                completionHandler(videoURL, nil, ext)
            }
            return URLSessionDownloadTask()
        }else if urlType == .auido && PhotoTools.isCached(forAudio: key) {
            let audioURL = PhotoTools.getAudioTmpURL(for: key)
            if let fileURL = fileURL,
               audioURL.absoluteString != fileURL.absoluteString {
                PhotoTools.copyFile(at: audioURL, to: fileURL)
                completionHandler(fileURL, nil, ext)
            }else {
                completionHandler(audioURL, nil, ext)
            }
            return URLSessionDownloadTask()
        }
        if let fileURL = fileURL {
            downloadFileURLs[key] = fileURL
        }
        if let ext = ext {
            downloadExts[key] = ext
        }
        if let progress = progress {
            downloadProgresss[key] = progress
        }
        downloadCompletions[key] = completionHandler
        if let task = downloadTasks[key] {
            if task.state == .suspended {
                task.resume()
                return task
            }
            if task.state == .running {
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
        downloadExts.removeValue(forKey: key)
        downloadCompletions.removeValue(forKey: key)
        downloadProgresss.removeValue(forKey: key)
    }
    
    public func removeTask(_ url: URL) {
        let key = url.absoluteString
        let task = downloadTasks[key]
        task?.cancel()
        downloadExts.removeValue(forKey: key)
        downloadFileURLs.removeValue(forKey: key)
        downloadCompletions.removeValue(forKey: key)
        downloadProgresss.removeValue(forKey: key)
        downloadTasks.removeValue(forKey: key)
    }
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let responseURL = downloadTask.currentRequest!.url!
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        let progressHandler = downloadProgresss[responseURL.absoluteString]
        DispatchQueue.main.async {
            progressHandler?(progress, downloadTask)
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let responseURL: URL
        if let url = downloadTask.originalRequest?.url {
            responseURL = url
        }else if let url = downloadTask.currentRequest?.url {
            responseURL = url
        }else {
            return
        }
        let key = responseURL.absoluteString
        let completionHandler = downloadCompletions[key]
        let ext = downloadExts[key]
        if let httpResponse = downloadTask.response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            PhotoTools.removeFile(fileURL: location)
            DispatchQueue.main.async {
                completionHandler?(nil, nil, ext)
            }
            removeTask(responseURL)
            return
        }
        if let url = downloadFileURLs[key] {
            if let _ = PhotoTools.removeFile(fileURL: url) {
                DispatchQueue.main.async {
                    completionHandler?(nil, nil, ext)
                }
                removeTask(responseURL)
                return
            }
            do {
                try FileManager.default.moveItem(at: location, to: url)
            } catch {
                DispatchQueue.main.async {
                    completionHandler?(nil, nil, ext)
                }
                removeTask(responseURL)
                return
            }
            DispatchQueue.main.async {
                completionHandler?(url, nil, ext)
            }
        }else {
            let url: URL
            switch location.fileType {
            case .video:
                let videoURL = PhotoTools.getVideoCacheURL(for: key)
                if let _ = PhotoTools.removeFile(fileURL: videoURL) {
                    DispatchQueue.main.async {
                        completionHandler?(nil, nil, ext)
                    }
                    removeTask(responseURL)
                    return
                }
                do {
                    try FileManager.default.moveItem(at: location, to: videoURL)
                    url = videoURL
                } catch {
                    DispatchQueue.main.async {
                        completionHandler?(nil, nil, ext)
                    }
                    removeTask(responseURL)
                    return
                }
            case .auido:
                let audioURL = PhotoTools.getAudioTmpURL(for: key)
                if let _ = PhotoTools.removeFile(fileURL: audioURL) {
                    DispatchQueue.main.async {
                        completionHandler?(nil, nil, ext)
                    }
                    removeTask(responseURL)
                    return
                }
                do {
                    try FileManager.default.moveItem(at: location, to: audioURL)
                    url = audioURL
                } catch {
                    DispatchQueue.main.async {
                        completionHandler?(nil, nil, ext)
                    }
                    removeTask(responseURL)
                    return
                }
            default:
                url = location
            }
            DispatchQueue.main.async {
                completionHandler?(url, nil, ext)
            }
        }
        removeTask(responseURL)
    }
    
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        let responseURL: URL
        if let url = task.originalRequest?.url {
            responseURL = url
        }else if let url = task.currentRequest?.url {
            responseURL = url
        }else {
            return
        }
        let key = responseURL.absoluteString
        let ext = downloadExts[key]
        if let error = error {
            let completionHandler = downloadCompletions[key]
            DispatchQueue.main.async {
                completionHandler?(nil, error, ext)
            }
        }
        removeTask(responseURL)
    }
    
    func getURLType(for url: URL) -> FileType {
        if #available(iOS 14.0, *) {
            if let utType = UTType(
                tag: url.pathExtension,
                tagClass: .filenameExtension,
                conformingTo: nil
            ) {
                switch utType {
                case .video,
                     .mpeg2Video,
                     .appleProtectedMPEG4Video,
                     .mpeg4Movie,
                     .quickTimeMovie,
                     .movie:
                    return .video
                case .audio,
                     .mp3:
                    return .auido
                case .livePhoto,
                     .image,
                     .rawImage,
                     .diskImage,
                     .gif,
                     .png,
                     .jpeg:
                    return .image
                default:
                    break
                }
            }
        } else {
            let utType = UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassFilenameExtension,
                url.pathExtension as CFString,
                nil
            )
            if let utType = utType {
                switch utType.takeRetainedValue() {
                case kUTTypeMovie,
                     kUTTypeVideo,
                     kUTTypeQuickTimeMovie,
                     kUTTypeMPEG,
                     kUTTypeMPEG4:
                    return .video
                case kUTTypeMP3,
                     kUTTypeAudio:
                    return .auido
                case kUTTypeImage,
                     kUTTypeRawImage,
                     kUTTypeDiskImage,
                     kUTTypeLivePhoto,
                     kUTTypeGIF,
                     kUTTypePNG,
                     kUTTypeJPEG,
                     kUTTypeJPEG2000:
                    return .image
                default:
                    break
                }
            }
        }
        return .unknown
    }
}
#endif
