//
//  EditorToolOptions.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import Foundation

public class EditorToolOptions {
    
    /// icon图标
    public let imageName: String
    
    /// 类型
    public let type: `Type`
    
    public init(imageName: String,
                type: `Type`) {
        self.imageName = imageName
        self.type = type
    }
}
