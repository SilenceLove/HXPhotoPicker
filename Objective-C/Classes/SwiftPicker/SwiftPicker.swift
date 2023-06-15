//
//  SwiftPicker.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2023/6/14.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit
import HXPhotoPicker
 
class SwiftPicker: NSObject {
    
    @objc
    @discardableResult
    class func openPicker(
        _ config: SwiftPickerConfiguration,
        fromVC: UIViewController,
        finish: ((SwiftPickerResult, PhotoPickerController) -> Void)? = nil,
        cancel: ((PhotoPickerController) -> Void)? = nil
    ) -> PhotoPickerController {
        /// 根据需求自己添加要修改的属性
        var pickerConfig = PickerConfiguration()
        pickerConfig.isAutoBack = config.isAutoBack
        pickerConfig.selectOptions = config.selectOptions.toSwift
        pickerConfig.selectMode = config.selectMode.toSwift
        pickerConfig.allowSelectedTogether = config.allowSelectedTogether
        pickerConfig.allowSyncICloudWhenSelectPhoto = config.allowSyncICloudWhenSelectPhoto
        pickerConfig.albumShowMode = config.albumShowMode.toSwift
        let controller = PhotoPickerController(config: pickerConfig) {
            finish?(.init(photoAssets: $0.photoAssets, isOriginal: $0.isOriginal), $1)
        } cancel: {
            cancel?($0)
        }
        fromVC.present(controller, animated: true)
        return controller
    }
}

extension UIView {
    
    @objc
    func showLoading(_ text: String) {
        hx.show(text: text)
    }
    
    @objc
    func hide() {
        hx.hide()
    }
}
