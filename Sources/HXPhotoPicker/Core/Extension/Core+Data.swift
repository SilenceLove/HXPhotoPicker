//
//  Core+Data.swift
//  HXPhotoPicker
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
    
    var isHEIC: Bool {
        guard count > 12 else { return false }
            let magicRange = subdata(in: 4..<12)
            let magicString = String(data: magicRange, encoding: .ascii) ?? ""
            // 常见的HEIF/HEIC文件类型
            let heicKeywords = ["ftypheic", "ftypheix", "ftyphevc", "ftypmif1", "ftypmsf1", "ftypheis"]
            for keyword in heicKeywords {
                if magicString.hasPrefix(keyword) {
                    return true
                }
            }
            return false
    }
    
    var fileType: FileType {
        guard let firstByte = first else {
            return .unknown
        }
        switch firstByte {
        case 0xFF:
            return .image
        case 0x25:
            return .auido
        case 0x00:
            return .video
        default:
            return .unknown
        }
    }
}
