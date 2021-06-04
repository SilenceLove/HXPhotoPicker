//
//  PhotoManager+Download.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/3.
//

import UIKit

extension PhotoManager: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let responseURL = downloadTask.currentRequest!.url!
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        let progressHandler = downloadProgresss[responseURL.absoluteString]
        DispatchQueue.main.async {
            progressHandler?(progress, downloadTask)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let responseURL = downloadTask.currentRequest!.url!
        let completionHandler = downloadCompletions[responseURL.absoluteString]
        if let httpResponse = downloadTask.response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            PhotoTools.removeFile(fileURL: location)
            DispatchQueue.main.async {
                completionHandler?(nil, nil)
            }
            return
        }
        let videoURL = PhotoTools.getVideoCacheURL(for: responseURL.absoluteString)
        do {
            PhotoTools.removeFile(fileURL: videoURL)
            try FileManager.default.moveItem(at: location, to: videoURL)
            DispatchQueue.main.async {
                completionHandler?(videoURL, nil)
            }
            return
        } catch { }
        self.removeTask(responseURL)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let responseURL = task.currentRequest!.url!
        if let error = error {
            let completionHandler = downloadCompletions[responseURL.absoluteString]
            DispatchQueue.main.async {
                completionHandler?(nil, error)
            }
        }
        self.removeTask(responseURL)
    }
}
