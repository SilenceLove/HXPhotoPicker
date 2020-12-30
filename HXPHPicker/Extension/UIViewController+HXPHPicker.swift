//
//  UIViewController+HXPHPicker.swift
//  照片选择器-Swift
//
//  Created by Silence on 2020/11/11.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

extension UIViewController {
    
    var pickerController: HXPHPickerController? {
        get {
            if self.navigationController is HXPHPickerController {
                return self.navigationController as? HXPHPickerController
            }
            return nil
        }
    }
}
