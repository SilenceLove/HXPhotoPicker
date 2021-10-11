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
    
    /// Haptic Touch 预览时允许添加菜案，iOS13 以上
    public var allowAddMenuElements: Bool = true
    
    /// 允许滑动选择
    public var allowSwipeToSelect: Bool = true
    
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
    public var cameraCell: PhotoListCameraCellConfiguration = .init()
    
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
