//
//  Picker+UIViewController.swift
//  照片选择器-Swift
//
//  Created by Silence on 2020/11/11.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

extension UIViewController {
    
    var pickerController: PhotoPickerController? {
        get {
            if self.navigationController is PhotoPickerController {
                return self.navigationController as? PhotoPickerController
            }
            return nil
        }
    }
}
