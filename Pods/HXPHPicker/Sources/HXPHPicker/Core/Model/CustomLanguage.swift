//
//  CustomLanguage.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/7.
//

import Foundation

public class CustomLanguage {
    /// 语言
    /// 会与 Locale.preferredLanguages 进行匹配，匹配成功的才会使用。请确保正确性
    public let language: String
    /// 语言文件路径
    public let path: String
    
    public init(language: String,
                path: String) {
        self.language = language
        self.path = path
    }
}
