//
//  PhotoDebugLogsConfig.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/21.
//  Copyright © 2023 Silence. All rights reserved.
//

import Foundation

public protocol PhotoDebugLogsConfig {
    var isDebugLogsEnabled: Bool { get set }
}

public extension PhotoDebugLogsConfig {
    var isDebugLogsEnabled: Bool {
        get { PhotoManager.shared.isDebugLogsEnabled }
        set { PhotoManager.shared.isDebugLogsEnabled = newValue }
    }
}



