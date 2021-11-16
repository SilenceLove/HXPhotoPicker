//
//  VideoCropTimeConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/10.
//

import UIKit

public struct VideoCropTimeConfiguration {
    
    /// 视频最大裁剪时长，最小1
    public var maximumVideoCroppingTime: TimeInterval = 10
    
    /// 视频最小裁剪时长，最小1
    public var minimumVideoCroppingTime: TimeInterval = 1
    
    public init() { }
}
