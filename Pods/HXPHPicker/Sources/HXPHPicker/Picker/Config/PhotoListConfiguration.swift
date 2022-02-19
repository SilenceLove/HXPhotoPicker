//
//  PhotoListConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: 照片列表配置类
public struct PhotoListConfiguration {
    /// 相册标题视图配置
    public var titleView: AlbumTitleViewConfiguration = .init()
    
    /// 列表排序方式
    /// - Default: ASC
    /// - ASC:  升序排列，自动滚动到底部
    /// - DESC: 倒序排列，自动滚动到顶部
    public var sort: Sort = .asc
    
    /// 背景颜色
    public var backgroundColor: UIColor = .white
    
    /// 暗黑风格下背景颜色
    public var backgroundDarkColor: UIColor = "#2E2F30".color
    
    /// 取消按钮的配置只有当 albumShowMode = .popup 时有效
    /// 取消按钮类型
    public var cancelType: PhotoPickerViewController.CancelType = .text
    
    /// 取消按钮位置
    public var cancelPosition: PhotoPickerViewController.CancelPosition = .right
    
    /// 取消按钮图片名
    public var cancelImageName: String = "hx_picker_photolist_cancel"
    
    /// 暗黑模式下取消按钮图片名
    public var cancelDarkImageName: String = "hx_picker_photolist_cancel"
    
    /// 每行显示数量
    public var rowNumber: Int = UIDevice.isPad ? 5 : 4
    
    /// 横屏时每行显示数量
    public var landscapeRowNumber: Int = 7
    
    /// 每个照片之间的间隙
    public var spacing: CGFloat = 1
    
    /// 允许 Haptic Touch 预览，iOS13 以上
    public var allowHapticTouchPreview: Bool = true
    
    /// Haptic Touch 预览时允许添加菜单，iOS13 以上
    public var allowAddMenuElements: Bool = true
    
    /// 允许滑动选择
    public var allowSwipeToSelect: Bool = false
    
    /// 滑动选择时允许自动向上/下滚动
    /// 当 allowSyncICloudWhenSelectPhoto = true 时，自动滚动失效
    public var swipeSelectAllowAutoScroll: Bool = true
    
    /// 自动向上/下滚动时的速率
    public var swipeSelectScrollSpeed: CGFloat = 1
    
    /// 触发自动滚动的顶部区域的高度
    public var autoSwipeTopAreaHeight: CGFloat = 100
    
    /// 触发自动滚动的底部区域的高度
    public var autoSwipeBottomAreaHeight: CGFloat = 100
    
    /// cell相关配置
    public var cell: PhotoListCellConfiguration = .init()
    
    /// 底部视图相关配置
    public var bottomView: PickerBottomViewConfiguration = .init()
    
    /// 允许添加相机
    public var allowAddCamera: Bool = true
    
    /// 相机cell配置
    public var cameraCell: CameraCell = .init()
    
    /// 单选模式下，拍照完成之后直接选中并且完成选择
    public var finishSelectionAfterTakingPhoto: Bool = false
    
    /// 相机类型
    public var cameraType: CameraType
    
    /// 拍照完成后是否选择
    public var takePictureCompletionToSelected: Bool = true
    
    /// 拍照完成后保存到系统相册
    public var saveSystemAlbum: Bool = true
    
    /// 保存在自定义相册的名字，为空时则取 BundleName
    public var customAlbumName: String?
    
    /// 当相册权限为选中的照片时，允许添加更多cell，选择更多照片/视频
    public var allowAddLimit: Bool = true
    
    /// 当相册权限为选中的照片时，添加照片cell的配置
    public var limitCell: LimitCell = .init()
    
    /// 底部显示 照片/视频 数量
    public var showAssetNumber: Bool = true
    
    public var assetNumber: AssetNumber = .init()
    
    /// 没有资源时展示的相关配置
    public var emptyView: EmptyViewConfiguration = .init()
    
    public init() {
        #if HXPICKER_ENABLE_CAMERA
        cameraType = .custom(.init())
        #else
        cameraType = .system(.init())
        #endif
    }
}

extension PhotoListConfiguration {
    public enum CameraType {
        /// 系统相机
        case system(SystemCameraConfiguration)
        #if HXPICKER_ENABLE_CAMERA
        /// 自带相机
        case custom(CameraConfiguration)
        #endif
        
        public var systemConfig: SystemCameraConfiguration? {
            switch self {
            case .system(let config):
                return config
            #if HXPICKER_ENABLE_CAMERA
            default:
                return nil
            #endif
            }
        }
        
        #if HXPICKER_ENABLE_CAMERA
        public var customConfig: CameraConfiguration? {
            switch self {
            case .custom(let config):
                return config
            default:
                return nil
            }
        }
        #endif
    }
}

// MARK: 照片列表相机Cell配置类
extension PhotoListConfiguration {
    
    public struct CameraCell {
        
        /// 允许相机预览
        public var allowPreview: Bool = false
        
        /// 背景颜色
        public var backgroundColor: UIColor? = "#f1f1f1".color
        
        /// 暗黑风格下背景颜色
        public var backgroundDarkColor: UIColor? = "#404040".color
        
        /// 相机图标
        public var cameraImageName: String = "hx_picker_photoList_photograph"
        
        /// 暗黑风格下的相机图标 / 相机预览成功之后的图标
        public var cameraDarkImageName: String = "hx_picker_photoList_photograph_white"
        
        public init() { }
    }
}

extension PhotoListConfiguration {
    
    public struct LimitCell {
        
        /// 背景颜色
        public var backgroundColor: UIColor? = "#f1f1f1".color
        
        /// 背景颜色
        public var backgroundDarkColor: UIColor? = "#404040".color
        
        /// 加号颜色
        public var lineColor: UIColor = "#999999".color
        
        /// 加号暗黑模式下的颜色
        public var lineDarkColor: UIColor = "#ffffff".color
        
        /// 加号两条线的宽度
        public var lineWidth: CGFloat = 4
        
        /// 加号两条线的长度
        public var lineLength: CGFloat = 25
        
        /// 文字标题
        public var title: String? = "更多"
        
        /// 标题颜色
        public var titleColor: UIColor = "#999999".color
        
        /// 标题暗黑模式下的颜色
        public var titleDarkColor: UIColor = "#ffffff".color
        
        /// 标题字体
        public var titleFont: UIFont = .mediumPingFang(ofSize: 14)
        
        public init() { }
    }
}

extension PhotoListConfiguration {
    
    public struct AssetNumber {
        public var textColor: UIColor = "#333333".color
        public var textDarkColor: UIColor = "#ffffff".color
        public var textFont: UIFont = .mediumPingFang(ofSize: 15)
        public init() { }
    }
}
