//
//  Core+Data.swift
//  HXPHPicker
//
//  Created by Slience on 2021/5/20.
//

import Foundation

extension Data {
    
    var imageContentType: ImageContentType {
        var values = [UInt8](repeating: 0, count: 1)
        copyBytes(to: &values, count: 1)
        switch values[0] {
        case 0xFF:
            return .jpg
        case 0x89:
            return .png
        case 0x47, 0x49, 0x46:
            return .gif
        default:
            return .unknown
        }
    }
    
    var isGif: Bool {
        imageContentType == .gif
    }
}
