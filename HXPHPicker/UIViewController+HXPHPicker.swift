//
//  UIViewController+HXPHPicker.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2020/11/11.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func hx_pickerController() -> HXPHPickerController? {
        if self.navigationController is HXPHPickerController {
            return self.navigationController as? HXPHPickerController
        }
        return nil
    }
    
}
