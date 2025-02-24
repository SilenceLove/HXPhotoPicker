//
//  Core+URL.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/6/17.
//

import Foundation

extension URL {
    var isGif: Bool {
        absoluteString.hasSuffix("gif") || absoluteString.hasSuffix("GIF")
    }
    var fileSize: Int {
        guard let fileSize = try? resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return 0
        }
        return fileSize
    }
    
    var fileType: FileType {
        guard let fileData = try? Data(contentsOf: self) else {
            return .unknown
        }
        return fileData.fileType
    }
}
