//
//  Picker+Int.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/5.
//

import Foundation

extension Int {
    
    var bytesString: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(self))
    }
}
