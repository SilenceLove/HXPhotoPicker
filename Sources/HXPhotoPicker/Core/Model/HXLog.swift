//
//  HXLog.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/21.
//  Copyright © 2023 Silence. All rights reserved.
//


internal func HXLog(
    _ description: String,
    fileName: String = #file,
    lineNumber: Int = #line,
    functionName: String = #function
) {
    if !PhotoManager.shared.isDebugLogsEnabled {
        return
    }
    // swiftlint:disable:next line_length
    let traceString = "🖼 PhotoPicker. \(fileName.components(separatedBy: "/").last!) -> \(functionName) -> \(description) (line: \(lineNumber))"
    print(traceString)
}
