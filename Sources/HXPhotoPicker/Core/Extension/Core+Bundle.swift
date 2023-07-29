//
//  Core+Bundle.swift
//  HXPhotoPicker
//
//  Created by Silence on 2020/11/15.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
 
extension Bundle {
    
    static func localizedString(for key: String) -> String {
        return localizedString(for: key, value: nil)
    }
    
    static func localizedString(for key: String, value: String?) -> String {
        let bundle = PhotoManager.shared.languageBundle
        guard let newValue = bundle?.localizedString(forKey: key, value: value, table: nil) else {
            return key
        }
        return newValue
    }
}
