//
//  PhotoManager+Language.swift
//  HXPhotoPicker
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
        if self.languageType != languageType {
            // 与上次语言不一致，重新创建
            languageBundle = nil
        }
        if languageBundle == nil {
            let language: String
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
            case .vietnamese:
                language = "vi"
            case .russian:
                language = "ru"
            case .german:
                language = "de"
            case .french:
                language = "fr"
            case .arabic:
                language = "ar"
            case .custom(let bundle):
                language = ""
                languageBundle = bundle
            default:
            out: for customLanguage in customLanguages {
                    for preferredLanguage in Locale.preferredLanguages where preferredLanguage.hasPrefix(customLanguage.language) {
                        languageBundle = customLanguage.bundle
                        break out
                    }
                }
                language = languageStr
            }
            if languageBundle == nil, let path = bundle?.path(forResource: language, ofType: "lproj") {
                languageBundle = Bundle(path: path)
            }
            self.languageType = languageType
        }
        return languageBundle
    }
    
    var languageStr: String {
        var language = "en"
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
            }else if preferredLanguage.hasPrefix("vi") {
                language = "vi"
                break
            }else if preferredLanguage.hasPrefix("ru") {
                language = "ru"
                break
            }else if preferredLanguage.hasPrefix("de") {
                language = "de"
                break
            }else if preferredLanguage.hasPrefix("fr") {
                language = "fr"
                break
            }else if preferredLanguage.hasPrefix("en") {
                language = "en"
                break
            }else if preferredLanguage.hasPrefix("ar") {
                language = "ar"
                break
            }
        }
        return language
    }
}
