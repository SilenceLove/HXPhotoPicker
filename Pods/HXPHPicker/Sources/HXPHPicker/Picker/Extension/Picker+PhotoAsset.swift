//
//  Picker+PhotoAsset.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/8.
//

import UIKit

extension PhotoAsset {
    
    func checkAdjustmentStatus(completion: @escaping (Bool, PhotoAsset) -> Void) {
        #if HXPICKER_ENABLE_EDITOR
        if photoEdit != nil || videoEdit != nil {
            completion(false, self)
            return
        }
        #endif
        if let asset = self.phAsset {
            if mediaSubType == .livePhoto {
                completion(false, self)
                return
            }
            asset.checkAdjustmentStatus { (isAdjusted) in
                completion(isAdjusted, self)
            }
            return
        }
        completion(false, self)
    }
    var inICloud: Bool {
        guard let phAsset = phAsset else {
            return false
        }
        if downloadStatus != .succeed && !phAsset.isLocallayAvailable {
            return true
        }
        return false
    }
    func checkICloundStatus(
        allowSyncPhoto: Bool,
        hudAddedTo: UIView? = UIApplication.shared.keyWindow,
        completion: @escaping (Bool) -> Void
    ) -> Bool {
        guard let phAsset = phAsset else {
            return false
        }
        if mediaType == .photo && !allowSyncPhoto {
            return false
        }
        if downloadStatus != .succeed && phAsset.inICloud {
            var loadingView: ProgressHUD?
            if mediaType == .photo {
                requestImageData { _, _ in
                    loadingView = ProgressHUD.showLoading(
                        addedTo: hudAddedTo,
                        text: "正在同步iCloud".localized + "...",
                        animated: true
                    )
                } progressHandler: { _, progress in
                    loadingView?.updateText(
                        text: "正在同步iCloud".localized + "(" + String(Int(progress * 100)) + "%)"
                    )
                } resultHandler: { _, result in
                    switch result {
                    case .success(_):
                        ProgressHUD.hide(forView: hudAddedTo, animated: true)
                        loadingView = nil
                        completion(true)
                    case .failure(_):
                        ProgressHUD.hide(forView: hudAddedTo, animated: false)
                        ProgressHUD.showWarning(
                            addedTo: hudAddedTo,
                            text: "iCloud同步失败".localized,
                            animated: true,
                            delayHide: 1.5
                        )
                        loadingView = nil
                        completion(false)
                    }
                }
            }else if mediaType == .video {
                requestAVAsset { _, _ in
                    loadingView = ProgressHUD.showLoading(
                        addedTo: hudAddedTo,
                        text: "正在同步iCloud".localized + "...",
                        animated: true
                    )
                } progressHandler: { _, progress in
                    loadingView?.updateText(text: "正在同步iCloud".localized + "(" + String(Int(progress * 100)) + "%)")
                } success: { _, _, _ in
                    ProgressHUD.hide(forView: hudAddedTo, animated: true)
                    loadingView = nil
                    completion(true)
                } failure: { _, _, _ in
                    ProgressHUD.hide(forView: hudAddedTo, animated: false)
                    ProgressHUD.showWarning(
                        addedTo: hudAddedTo,
                        text: "iCloud同步失败".localized,
                        animated: true,
                        delayHide: 1.5
                    )
                    loadingView = nil
                    completion(false)
                }
            }
            return true
        }
        return false
    }
}
