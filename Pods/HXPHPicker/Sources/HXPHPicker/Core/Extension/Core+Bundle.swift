//
//  Core+Bundle.swift
//  HXPHPickerExample
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
        var newValue = bundle?.localizedString(forKey: key, value: value, table: nil)
        if newValue == nil {
            newValue = key
        }
        return newValue!
    }
}
