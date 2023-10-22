//
//  PickerDebugLogsConfig.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/21.
//  Copyright © 2023 洪欣. All rights reserved.
//

import Foundation

public protocol PickerDebugLogsConfig {
    var isDebugLogsEnabled: Bool { get set }
}

public extension PickerDebugLogsConfig {
    var isDebugLogsEnabled: Bool {
        get { PhotoManager.shared.isDebugLogsEnabled }
        set { PhotoManager.shared.isDebugLogsEnabled = newValue }
    }
}
