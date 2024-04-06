//  CustomLanguage.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/7.
//  Created by Silence on 2024/3/30.
//  Copyright © 2024 Silence. All rights reserved.
//

import Foundation

public class CustomLanguage {
    
    /// 会与 Locale.preferredLanguages 进行匹配，匹配成功的才会使用。请确保正确性
    public let language: String
    /// 语言Bundle
    /// ```
    /// - xxx.lproj
    ///   - Localizable.strings
    /// ```
    public let bundle: Bundle
    
    public init(
        language: String,
        bundle: Bundle
    ) {
        self.language = language
        self.bundle = bundle
    }
}
