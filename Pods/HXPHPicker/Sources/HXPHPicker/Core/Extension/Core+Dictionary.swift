//
//  Core+Dictionary.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/7.
//

import Photos

extension Dictionary {
    
    /// 资源是否存在iCloud上
    var inICloud: Bool {
        if let isICloud = self[AnyHashable(PHImageResultIsInCloudKey) as! Key] as? Int {
            return isICloud == 1
        }
        return false
    }
    
    /// 资源是否取消了下载
    var isCancel: Bool {
        if let isCancel = self[AnyHashable(PHImageCancelledKey) as! Key] as? Int {
            return isCancel == 1
        }
        return false
    }
    var error: Error? {
        self[AnyHashable(PHImageErrorKey) as! Key] as? Error
    }
    /// 判断资源是否下载错误
    var isError: Bool {
        self[AnyHashable(PHImageErrorKey) as! Key] != nil
    }
    
    /// 判断资源下载得到的是否为退化的
    var isDegraded: Bool {
        if let isDegraded = self[AnyHashable(PHImageResultIsDegradedKey) as! Key] as? Int {
            return isDegraded == 1
        }
        return false
    }
    
    /// 判断资源是否下载完成
    var downloadFinined: Bool {
        !isCancel && !isError && !isDegraded
    }
}
