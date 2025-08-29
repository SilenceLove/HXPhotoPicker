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
            case .spanish:
                language = "es"
            case .portuguese:
                language = "pt"
            case .amharic:
                language = "am-ET"
            case .bengali:
                language = "bn-BD"
            case .divehi:
                language = "dv"
            case .persian:
                language = "fa"
            case .filipino:
                language = "fil"
            case .hausa:
                language = "ha-NG"
            case .hebrew:
                language = "he"
            case .hindi:
                language = "hi"
            case .italian:
                language = "it"
            case .malay:
                language = "ms"
            case .nepali:
                language = "ne"
            case .punjabi:
                language = "pa"
            case .sinhala:
                language = "si"
            case .swahili:
                language = "sw"
            case .syriac:
                language = "syc"
            case .turkish:
                language = "tr"
            case .ukrainian:
                language = "uk"
            case .urdu:
                language = "ur"
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
            }else if preferredLanguage.hasPrefix("es") {
                language = "es"
                break
            }else if preferredLanguage.hasPrefix("pt") {
                language = "pt"
                break
            }else if preferredLanguage.hasPrefix("am") {
                language = "am-ET"
                break
            }else if preferredLanguage.hasPrefix("bn") {
                language = "bn-BD"
                break
            }else if preferredLanguage.hasPrefix("dv") {
                language = "dv"
                break
            }else if preferredLanguage.hasPrefix("fa") {
                language = "fa"
                break
            }else if preferredLanguage.hasPrefix("fil") {
                language = "fil"
                break
            }else if preferredLanguage.hasPrefix("ha") {
                language = "ha-NG"
                break
            }else if preferredLanguage.hasPrefix("he") {
                language = "he"
                break
            }else if preferredLanguage.hasPrefix("hi") {
                language = "hi"
                break
            }else if preferredLanguage.hasPrefix("it") {
                language = "it"
                break
            }else if preferredLanguage.hasPrefix("ms") {
                language = "ms"
                break
            }else if preferredLanguage.hasPrefix("ne") {
                language = "ne"
                break
            }else if preferredLanguage.hasPrefix("pa") {
                language = "pa"
                break
            }else if preferredLanguage.hasPrefix("si") {
                language = "si"
                break
            }else if preferredLanguage.hasPrefix("sw") {
                language = "sw"
                break
            }else if preferredLanguage.hasPrefix("syc") {
                language = "syc"
                break
            }else if preferredLanguage.hasPrefix("tr") {
                language = "tr"
                break
            }else if preferredLanguage.hasPrefix("uk") {
                language = "uk"
                break
            }else if preferredLanguage.hasPrefix("ur") {
                language = "ur"
                break
            }
        }
        return language
    }
}
