//
//  AssetPermissionsUtil.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/3/25.
//  Copyright © 2024 Silence. All rights reserved.
//

import Photos

public struct AssetPermissionsUtil {
    
    /// 获取当前相册权限状态
    /// - Returns: 权限状态
    public static var authorizationStatus: PHAuthorizationStatus {
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }
        return status
    }
    
    /// 获取相机权限
    /// - Parameter completionHandler: 获取结果
    public static func requestCameraAccess(
        completionHandler: @escaping (Bool) -> Void
    ) {
        #if !targetEnvironment(macCatalyst)
        AVCaptureDevice.requestAccess(
            for: .video
        ) { (granted) in
            DispatchQueue.main.async {
                completionHandler(granted)
            }
        }
        #else
        completionHandler(false)
        #endif
    }
    
    /// 当前相机权限状态
    /// - Returns: 权限状态
    #if !targetEnvironment(macCatalyst)
    public static var cameraAuthorizationStatus:  AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    }
    #endif
    
    /// 当前相册权限状态是否是Limited
    public static var isLimitedAuthorizationStatus:  Bool {
        #if !targetEnvironment(macCatalyst)
        if #available(iOS 14, *), authorizationStatus == .limited  {
            return true
        }
        #endif
        return false
    }
    
    /// 请求获取相册权限
    /// - Parameters:
    ///   - handler: 请求权限完成
    public static func requestAuthorization(
        with handler: @escaping (PHAuthorizationStatus) -> Void
    ) {
        let status = authorizationStatus
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
