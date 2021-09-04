//
//  Core+URL.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/17.
//

import Foundation

extension URL {
    var isGif: Bool {
        absoluteString.hasSuffix("gif") || absoluteString.hasSuffix("GIF")
    }
    var fileSize: Int {
         do {
            let fileSize = try resourceValues(forKeys: [.fileSizeKey])
            return fileSize.fileSize ?? 0
         } catch {}
        return 0
    }
}
