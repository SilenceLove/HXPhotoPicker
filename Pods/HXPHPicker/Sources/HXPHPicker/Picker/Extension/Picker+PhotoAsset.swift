//
//  Picker+PhotoAsset.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/8.
//

import UIKit
import Photos

extension PhotoAsset {
    
    @discardableResult
    func checkAdjustmentStatus(
        completion: @escaping (Bool, PhotoAsset) -> Void
    ) -> PHContentEditingInputRequestID? {
        #if HXPICKER_ENABLE_EDITOR
        if photoEdit != nil || videoEdit != nil {
            completion(false, self)
            return nil
        }
        #endif
        if let asset = self.phAsset {
            if mediaSubType == .livePhoto {
                completion(false, self)
                return nil
            }
            return asset.checkAdjustmentStatus { (isAdjusted) in
                completion(isAdjusted, self)
            }
        }
        completion(false, self)
        return nil
    }
    var inICloud: Bool {
        guard let phAsset = phAsset,
              downloadStatus != .succeed else {
            return false
        }
        if !phAsset.isLocallayAvailable {
            return true
        }
        return false
    }
    func checkICloundStatus(
        allowSyncPhoto: Bool,
        hudAddedTo view: UIView? = UIApplication.shared.keyWindow,
        completion: @escaping (PhotoAsset, Bool) -> Void
    ) -> Bool {
        guard let phAsset = phAsset,
              downloadStatus != .succeed else {
            return false
        }
        if mediaType == .photo && !allowSyncPhoto {
            return false
        }
        if phAsset.inICloud {
            syncICloud(
                hudAddedTo: view,
                completion: completion
            )
            return true
        }else {
            downloadStatus = .succeed
        }
        return false
    }
    
    /// 获取iCloud状态
    /// - Parameter completion: 是否在iCloud上
    /// - Returns: 请求ID
    func requestICloudState(completion: @escaping (PhotoAsset, Bool) -> Void) -> PHImageRequestID? {
        guard let phAsset = phAsset,
              downloadStatus != .succeed else {
            completion(self, false)
            return nil
        }
        if mediaType == .photo {
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            return AssetManager.requestImageData(
                for: phAsset,
                options: options
            ) { (result) in
                switch result {
                case .failure(let error):
                    guard let info = error.info,
                          !info.isCancel else {
                        completion(self, false)
                        return
                    }
                    completion(self, info.inICloud)
                default:
                    self.downloadStatus = .succeed
                    completion(self, false)
                }
            }
        }
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .highQualityFormat
        return AssetManager.requestAVAsset(
            for: phAsset,
            options: options
        ) { result in
            switch result {
            case .failure(let error):
                guard let info = error.info,
                      !info.isCancel else {
                    completion(self, false)
                    return
                }
                completion(self, info.inICloud)
            default:
                self.downloadStatus = .succeed
                completion(self, false)
            }
        }
    }
    
    @discardableResult
    func syncICloud(
        iCloudHandler: PhotoAssetICloudHandler?,
        progressHandler: PhotoAssetProgressHandler?,
        completionHandler: ( (PhotoAsset, Bool) -> Void)?
    ) -> PHImageRequestID {
        if mediaType == .photo {
            return requestImageData(
                iCloudHandler: iCloudHandler,
                progressHandler: progressHandler
            ) { [weak self] photoAsset, result in
                guard let self = self else { return }
                switch result {
                case .success(_):
                    completionHandler?(self, true)
                case .failure(_):
                    completionHandler?(self, false)
                }
            }
        }else {
            return requestAVAsset(
                deliveryMode: .highQualityFormat,
                iCloudHandler: iCloudHandler,
                progressHandler: progressHandler
            ) { [weak self] _, _, _ in
                guard let self = self else { return }
                completionHandler?(self, true)
            } failure: { [weak self] _, _, _ in
                guard let self = self else { return }
                completionHandler?(self, false)
            }
        }
    }
    
    /// 同步iCloud上的资源
    /// - Parameters:
    ///   - view: 提示框的父视图
    ///   - completion: 同步完成 - 是否成功
    func syncICloud(
        hudAddedTo view: UIView? = UIApplication.shared.keyWindow,
        completion: ((PhotoAsset, Bool) -> Void)? = nil
    ) {
        var loadingView: ProgressHUD?
        syncICloud { _, _ in
            loadingView = ProgressHUD.showProgress(
                addedTo: view,
                text: "正在同步iCloud".localized + "...",
                animated: true
            )
        } progressHandler: { _, progress in
            loadingView?.progress = CGFloat(progress)
        } completionHandler: { photoAsset, isSuccess in
            ProgressHUD.hide(forView: view, animated: isSuccess)
            if !isSuccess {
                ProgressHUD.showWarning(
                    addedTo: view,
                    text: "iCloud同步失败".localized,
                    animated: true,
                    delayHide: 1.5
                )
            }
            loadingView = nil
            completion?(photoAsset, isSuccess)
        }
    }
}
