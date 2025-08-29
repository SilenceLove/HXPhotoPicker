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
    /// 阿姆哈拉语
    case amharic
    /// 孟加拉语
    case bengali
    /// 迪维希语
    case divehi
    /// 波斯语
    case persian
    /// 菲律宾语
    case filipino
    /// 豪萨语
    case hausa
    /// 希伯来语
    case hebrew
    /// 印地语
    case hindi
    /// 意大利语
    case italian
    /// 马来语
    case malay
    /// 尼泊尔语
    case nepali
    /// 旁遮普语
    case punjabi
    /// 僧伽罗语
    case sinhala
    /// 斯瓦希里语
    case swahili
    /// 叙利亚语
    case syriac
    /// 土耳其语
    case turkish
    /// 乌克兰语
    case ukrainian
    /// 乌尔都语
    case urdu
    
    case custom(Bundle)
}
