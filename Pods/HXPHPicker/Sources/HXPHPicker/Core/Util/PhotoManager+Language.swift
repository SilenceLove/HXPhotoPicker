//
//  PhotoManager+Language.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import Foundation

extension PhotoManager {
    
    /// 创建语言Bundle
    /// - Parameter languageType: 对应的语言类型
    /// - Returns: 语言Bundle
    @discardableResult
    public func createLanguageBundle(languageType: LanguageType) -> Bundle? {
        if bundle == nil {
            createBundle()
        }
        if self.languageType != languageType || isCustomLanguage {
            // 与上次语言不一致，重新创建
            languageBundle = nil
        }
        isCustomLanguage = false
        if languageBundle == nil {
            var language = "en"
            switch languageType {
            case .simplifiedChinese:
                language = "zh-Hans"
            case .traditionalChinese:
                language = "zh-Hant"
            case .japanese:
                language = "ja"
            case .korean:
                language = "ko"
            case .english:
                language = "en"
            case .thai:
                language = "th"
            case .indonesia:
                language = "id"
            default:
                if let fixedLanguage = fixedCustomLanguage {
                    isCustomLanguage = true
                    languageBundle = Bundle.init(path: fixedLanguage.path)
                    return languageBundle
                }
                for customLanguage in customLanguages {
                    if Locale.preferredLanguages.contains(customLanguage.language) {
                        isCustomLanguage = true
                        languageBundle = Bundle.init(path: customLanguage.path)
                        return languageBundle
                    }
                }
                for preferredLanguage in Locale.preferredLanguages {
                    if preferredLanguage.hasPrefix("zh") {
                        if preferredLanguage.range(of: "Hans") != nil {
                            language = "zh-Hans"
                        }else {
                            language = "zh-Hant"
                        }
                        break
                    }else if preferredLanguage.hasPrefix("ja") {
                        language = "ja"
                        break
                    }else if preferredLanguage.hasPrefix("ko") {
                        language = "ko"
                        break
                    }else if preferredLanguage.hasPrefix("th") {
                        language = "th"
                        break
                    }else if preferredLanguage.hasPrefix("id") {
                        language = "id"
                        break
                    }
                }
            }
            let path = bundle?.path(forResource: language, ofType: "lproj")
            if path != nil {
                languageBundle = Bundle.init(path: path!)
            }
            self.languageType = languageType
        }
        return languageBundle
    }
}
