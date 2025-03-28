//
//  LanguageType.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/7.
//

import Foundation

public enum LanguageType: Equatable {
    /// 跟随系统语言
    case system
    /// 中文简体
    case simplifiedChinese
    /// 中文繁体
    case traditionalChinese
    /// 日文
    case japanese
    /// 韩文
    case korean
    /// 英文
    case english
    /// 泰语
    case thai
    /// 印尼语
    case indonesia
    /// 越南语
    case vietnamese
    /// 俄语
    case russian
    /// 德语
    case german
    /// 法语
    case french
    /// 阿拉伯
    case arabic
    /// 西班牙
    case spanish
    /// 葡萄牙
    case portuguese
    
    case custom(Bundle)
}
