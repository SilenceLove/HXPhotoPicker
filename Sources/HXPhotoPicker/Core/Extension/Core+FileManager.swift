//
//  Core+FileManager.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/10/1.
//

import Foundation

extension FileManager: HXPickerCompatible {
    class var documentPath: String {
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? ""
    }
    class var cachesPath: String {
        NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last ?? ""
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
