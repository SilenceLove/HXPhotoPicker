//
//  HXPHPhotoListConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

// MARK: 照片列表配置类
public class HXPHPhotoListConfiguration: NSObject {
    /// 相册标题视图配置
    public lazy var titleViewConfig: HXAlbumTitleViewConfiguration = {
        let titleViewConfig = HXAlbumTitleViewConfiguration.init()
        return titleViewConfig
    }()
    
    /// 背景颜色
    public lazy var backgroundColor : UIColor = {
        return UIColor.white
    }()
    
    /// 暗黑风格下背景颜色
    public lazy var backgroundDarkColor : UIColor = {
        return "#2E2F30".hx_color
    }()
    
    /// 取消按钮的配置只有当 albumShowMode = .popup 时有效
    /// 取消按钮类型
    public var cancelType: HXPHPicker.PhotoList.CancelType = .text
    
    /// 取消按钮位置
    public var cancelPosition: HXPHPicker.PhotoList.CancelPosition = .right
    
    /// 取消按钮图片名
    public var cancelImageName: String = "hx_picker_photolist_cancel"
    
    /// 暗黑模式下取消按钮图片名
    public var cancelDarkImageName: String = "hx_picker_photolist_cancel"
    
    /// 每行显示数量
    public var rowNumber : Int = 4
    
    /// 横屏时每行显示数量
    public var landscapeRowNumber : Int = 7
    
    /// 每个照片之间的间隙
    public var spacing : CGFloat = 1
    
    /// cell相关配置
    public lazy var cell: HXPHPhotoListCellConfiguration = {
        return HXPHPhotoListCellConfiguration.init()
    }()
    
    /// 底部视图相关配置
    public lazy var bottomView: HXPHPickerBottomViewConfiguration = {
        let config = HXPHPickerBottomViewConfiguration.init()
        return config
    }()
    
    /// 允许添加相机
    public var allowAddCamera: Bool = true
    
    /// 相机cell配置
    public lazy var cameraCell: HXPHPhotoListCameraCellConfiguration = {
        return HXPHPhotoListCameraCellConfiguration.init()
    }()
    
    /// 相机配置
    public lazy var camera: HXPHCameraConfiguration = {
        return HXPHCameraConfiguration.init()
    }()
    
    /// 拍照完成后是否选择
    public var takePictureCompletionToSelected: Bool = true
    
    /// 拍照完成后保存到系统相册
    public var saveSystemAlbum: Bool = true
    
    /// 保存在自定义相册的名字，为空时则取 BundleName
    public var customAlbumName: String?
    
    /// 没有资源时展示的相关配置
    public lazy var emptyView : HXPHEmptyViewConfiguration = {
        return HXPHEmptyViewConfiguration.init()
    }()
}
