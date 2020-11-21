//
//  Bundle+HXPhotoPicker.swift
//  HXPHPickerExample
//
//  Created by 洪欣 on 2020/11/15.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

extension Bundle {
    
    class func hx_localizedString(for key: String) -> String {
        return hx_localizedString(for: key, value: nil)
    }
    
    class func hx_localizedString(for key: String, value: String?) -> String {
        let bundle = HXPHManager.shared.languageBundle
        var newValue = bundle?.localizedString(forKey: key, value: value, table: nil)
        if newValue == nil {
            newValue = key
        }
        return newValue!
    }
}
