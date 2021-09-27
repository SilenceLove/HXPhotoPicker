//
//  AssetManager+Authorization.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import Photos

public extension AssetManager {
    
    /// 获取当前相册权限状态
    /// - Returns: 权限状态
    static func authorizationStatus() -> PHAuthorizationStatus {
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            // Fallback on earlier versions
            status = PHPhotoLibrary.authorizationStatus()
        }
        return status
    }
    
    /// 获取相机权限
    /// - Parameter completionHandler: 获取结果
    static func requestCameraAccess(
        completionHandler: @escaping (Bool) -> Void
    ) {
        AVCaptureDevice.requestAccess(
            for: .video
        ) { (granted) in
            DispatchQueue.main.async {
                completionHandler(granted)
            }
        }
    }
    
    /// 当前相机权限状态
    /// - Returns: 权限状态
    static func cameraAuthorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    }
    
    /// 当前相册权限状态是否是Limited
    static func authorizationStatusIsLimited() -> Bool {
        if #available(iOS 14, *) {
            if authorizationStatus() == .limited {
                return true
            }
        }
        return false
    }
    
    /// 请求获取相册权限
    /// - Parameters:
    ///   - handler: 请求权限完成
    static func requestAuthorization(
        with handler: @escaping (PHAuthorizationStatus) -> Void
    ) {
        let status = authorizationStatus()
        if status == PHAuthorizationStatus.notDetermined {
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(
                    for: .readWrite
                ) { (authorizationStatus) in
                    DispatchQueue.main.async {
                        handler(authorizationStatus)
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { (authorizationStatus) in
                    DispatchQueue.main.async {
                        handler(authorizationStatus)
                    }
                }
            }
        }else {
            handler(status)
        }
    }
}
