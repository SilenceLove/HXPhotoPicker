//
//  Core+FileManager.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/10/1.
//

import Foundation

extension FileManager: HXPickerCompatible {
    class var documentPath: String {
        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last else {
            return ""
        }
        return documentPath
    }
    class var cachesPath: String {
        guard let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last else {
            return ""
        }
        return cachesPath
    }
    class var tempPath: String {
        NSTemporaryDirectory()
    }
}

public extension HXPickerWrapper where Base: FileManager {
    static var documentPath: String {
        Base.documentPath
    }
    static var cachesPath: String {
        Base.cachesPath
    }
    static var tempPath: String {
        Base.tempPath
    }
}
