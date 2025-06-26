//
//  PhotoListConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: Photo list configuration class / 照片列表配置类
public struct PhotoListConfiguration {
    
    public var listView: PhotoPickerList.Type = PhotoPickerListViewController.self
    
    public var leftNavigationItems: [PhotoNavigationItem.Type] = []
    
    public var rightNavigationItems: [PhotoNavigationItem.Type] = [PhotoTextCancelItemView.self, PhotoPickerFilterItemView.self]
    
    public var navigationTitle: PhotoPickerNavigationTitle.Type = AlbumTitleView.self
    
    /// Album title view configuration
    /// 相册标题视图配置
    public var titleView: AlbumTitleViewConfiguration = .init()
    
    /// Sort the list by
    /// 列表排序方式
    /// - Default: ASC
    /// - ASC:  Sort in ascending order, scroll to bottom automatically / 升序排列，自动滚动到底部
    /// - DESC: Reverse order, auto scroll to top / 倒序排列，自动滚动到顶部
    public var sort: Sort = .asc
    
    /// 背景颜色
    public var backgroundColor: UIColor = .white
    
    /// Background color in dark style
    /// 暗黑风格下背景颜色
    public var backgroundDarkColor: UIColor = .black
    
    @available(*, deprecated, message: "Use the registration APIs declared in the PhotoNavigationItem protocol")
    public var cancelType: PhotoPickerViewController.CancelType = .text
    
    @available(*, deprecated, message: "Use the registration APIs declared in the PhotoNavigationItem protocol")
    public var cancelPosition: PhotoPickerViewController.CancelPosition = .right
    
    /// Cancel button image name
    /// 取消按钮图片名
    public var cancelImageName: String {
        get { .imageResource.picker.photoList.cancel.name }
        set { HX.imageResource.picker.photoList.cancel = .local(newValue) }
    }
    
    /// Cancel button image name in dark mode
    /// 暗黑模式下取消按钮图片名
    public var cancelDarkImageName: String {
        get { .imageResource.picker.photoList.cancelDark.name }
        set { HX.imageResource.picker.photoList.cancelDark = .local(newValue) }
    }
    
    /// 导航栏是否显示筛选按钮
    public var isShowFilterItem: Bool = true
    
    public var filterThemeColor: UIColor?
    public var filterThemeDarkColor: UIColor?
    
    /// Display quantity per line
    /// 每行显示数量
    public var rowNumber: Int = UIDevice.isPad ? 5 : 4
    
    /// Display the number of each line when the screen is horizontal
    /// 横屏时每行显示数量
    public var landscapeRowNumber: Int = 7
    
    public var spltRowNumber: Int = 5
    
    /// Gap between each photo
    /// 每个照片之间的间隙
    public var spacing: CGFloat = 1
    
    /// Allow Haptic Touch preview, iOS13+
    /// 允许 Haptic Touch 预览，iOS13 以上
    public var allowHapticTouchPreview: Bool = true
    
    /// Haptic Touch allows adding menus when previewing, iOS13 and above
    /// Haptic Touch 预览时允许添加菜单，iOS13 以上
    public var allowAddMenuElements: Bool = true
    
    /// Allow swipe selection
    /// 允许滑动选择
    public var allowSwipeToSelect: Bool = true
    
    /// Allow automatic up/down scrolling when swiping to select
    /// 滑动选择时允许自动向上/下滚动
    public var swipeSelectAllowAutoScroll: Bool = true
    
    /// When pickerPresentStyle != .none, the area to the left of the swipe gesture is ignored
    /// 当 pickerPresentStyle != .none 时，滑动手势左边忽略的区域
    public var swipeSelectIgnoreLeftArea: CGFloat = 40
    
    /// Rate when scrolling up/down automatically
    /// 自动向上/下滚动时的速率
    public var swipeSelectScrollSpeed: CGFloat = 1
    
    /// The height of the top area that triggers autoscroll
    /// 触发自动滚动的顶部区域的高度
    public var autoSwipeTopAreaHeight: CGFloat = 100
    
    /// The height of the bottom area that triggers autoscroll
    /// 触发自动滚动的底部区域的高度
    public var autoSwipeBottomAreaHeight: CGFloat = 100
    
    /// cell related configuration
    /// cell相关配置
    public var cell: PhotoListCellConfiguration = .init()
    
    /// 自定义底部工具栏视图
    public var photoToolbar: PhotoToolBar.Type? = PhotoToolBarView.self
    
    /// Bottom view related configuration
    /// 默认的底部视图相关配置
    public var bottomView: PickerBottomViewConfiguration = .init()
    
    /// Allow adding cameras
    /// 允许添加相机
    public var allowAddCamera: Bool = true
    
    /// Camera cell configuration
    /// 相机cell配置
    public var cameraCell: CameraCell = .init()
    
    /// In single-choice mode, select directly after taking a photo and complete the selection
    /// 单选模式下，拍照完成之后直接选中并且完成选择
    public var finishSelectionAfterTakingPhoto: Bool = false
    
    /// camera type
    /// 相机类型
    public var cameraType: CameraType
    
    /// Whether to choose after taking pictures
    /// 拍照完成后是否选择
    public var takePictureCompletionToSelected: Bool = true
    
    /// After the photo is completed, save it to the system album
    /// 拍照完成后保存到系统相册
    public var isSaveSystemAlbum: Bool = true
    
    /// The name saved in the custom album, or BundleName when it is empty
    /// 保存在自定义相册的名字，为空时则取 BundleName
    public var customAlbumName: String? {
        get {
            switch saveSystemAlbumType {
            case .custom(let name):
                return name
            default:
                return nil
            }
        }
        set {
            if let name = newValue {
                saveSystemAlbumType = .custom(name)
            }else {
                saveSystemAlbumType = .displayName
            }
        }
    }
    
    /// 保存到自定义相册的类型
    public var saveSystemAlbumType: AssetSaveUtil.AlbumType = .displayName
    
    /// When the album permission is the selected photo, it is allowed to add more cells and select more photos/videos
    /// 当相册权限为选中的照片时，允许添加更多cell，选择更多照片/视频
    public var allowAddLimit: Bool = true
    
    /// When the album permission is the selected photo, add the configuration of the photo cell
    /// 当相册权限为选中的照片时，添加照片cell的配置
    public var limitCell: LimitCell = .init()
    
    /// The bottom shows the number of photos/videos
    /// 底部显示 照片/视频 数量
    public var isShowAssetNumber: Bool = true
    
    public var assetNumber: AssetNumber = .init()
    
    /// Relevant configuration displayed when there is no resource
    /// 没有资源时展示的相关配置
    public var emptyView: EmptyViewConfiguration = .init()
    
    /// 预览样式
    public var previewStyle: PhotoPickerPreviewJumpStyle = .push
    
    /// 初始滚动到指定`PhotoAsset`对应的标识，为空时 默认滚动到最后一个选中的`PhotoAsset`
    ///  PHAsset.localIdentifier / PhotoAsset.localAssetIdentifier
    public var selectedAssetIdentifier: String?
    
    public init() {
        #if HXPICKER_ENABLE_CAMERA && !targetEnvironment(macCatalyst)
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            cameraType = .system(.init())
        }else {
            cameraType = .custom(.init())
        }
        #else
        cameraType = .system(.init())
        #endif
    }
    
    public mutating func setThemeColor(_ color: UIColor) {
        titleView.setThemeColor(color)
        bottomView.setThemeColor(color)
        cell.setThemeColor(color)
        assetNumber.setThemeColor(color)
        #if HXPICKER_ENABLE_CAMERA && !targetEnvironment(macCatalyst)
        if var cameraConfig = cameraType.customConfig {
            cameraConfig.tintColor = color
            cameraType = .custom(cameraConfig)
        }
        #endif
        filterThemeColor = color
        filterThemeDarkColor = color
    }
}

extension PhotoListConfiguration {
    public enum CameraType {
        /// system camera
        /// 系统相机
        case system(SystemCameraConfiguration)
        #if HXPICKER_ENABLE_CAMERA && !targetEnvironment(macCatalyst)
        /// The frame comes with a camera
        /// 自带相机
        case custom(CameraConfiguration)
        #endif
        
        public var systemConfig: SystemCameraConfiguration? {
            switch self {
            case .system(let config):
                return config
            #if HXPICKER_ENABLE_CAMERA && !targetEnvironment(macCatalyst)
            default:
                return nil
            #endif
            }
        }
        
        #if HXPICKER_ENABLE_CAMERA && !targetEnvironment(macCatalyst)
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

// MARK: Photo list camera Cell configuration class / 照片列表相机Cell配置类
extension PhotoListConfiguration {
    
    public struct CameraCell {
        
        /// Allow camera preview
        /// 允许相机预览
        public var allowPreview: Bool = false
        
        /// 背景颜色
        public var backgroundColor: UIColor? = "#f1f1f1".hx.color
        
        /// Background color in dark style
        /// 暗黑风格下背景颜色
        public var backgroundDarkColor: UIColor? = "#404040".hx.color
        
        /// camera icon
        /// 相机图标
        public var cameraImageName: String {
            get { .imageResource.picker.photoList.cell.camera.name }
            set { HX.imageResource.picker.photoList.cell.camera = .local(newValue) }
        }
        
        /// Camera icon in dark style / icon after successful camera preview
        /// 暗黑风格下的相机图标 / 相机预览成功之后的图标
        public var cameraDarkImageName: String {
            get { .imageResource.picker.photoList.cell.cameraDark.name }
            set { HX.imageResource.picker.photoList.cell.cameraDark = .local(newValue) }
        }
        
        public init() {
            HX.imageResource.picker.photoList.cell.camera = .local("hx_picker_photoList_photograph")
        }
    }
}

extension PhotoListConfiguration {
    
    public struct LimitCell {
        
        /// 背景颜色
        public var backgroundColor: UIColor? = "#f1f1f1".hx.color
        
        /// Background color in dark mode
        /// 暗黑模式下的背景颜色
        public var backgroundDarkColor: UIColor? = "#404040".hx.color
        
        /// 加号颜色
        public var lineColor: UIColor = "#999999".hx.color
        
        /// plus color in dark mode
        /// 加号暗黑模式下的颜色
        public var lineDarkColor: UIColor = "#ffffff".hx.color
        
        /// The width of the two lines of the plus sign
        /// 加号两条线的宽度
        public var lineWidth: CGFloat = 4
        
        /// plus the length of the two lines
        /// 加号两条线的长度
        public var lineLength: CGFloat = 25
        
        /// text title
        /// 文字标题
        public var title: String? = "更多"
        
        /// title color
        /// 标题颜色
        public var titleColor: UIColor = "#999999".hx.color
        
        /// The color of the title in dark mode
        /// 标题暗黑模式下的颜色
        public var titleDarkColor: UIColor = "#ffffff".hx.color
        
        /// title font
        /// 标题字体
        public var titleFont: UIFont
        
        public init() {
            titleFont = .mediumPingFang(ofSize: 14)
        }
    }
}

extension PhotoListConfiguration {
    
    public struct AssetNumber {
        public var textColor: UIColor = "#333333".hx.color
        public var textDarkColor: UIColor = "#ffffff".hx.color
        public var textFont: UIFont
        
        public var filterTitleColor: UIColor = "#555555".hx.color
        public var filterTitleDarkColor: UIColor = "#ffffff".hx.color
        public var filterContentColor: UIColor = .systemBlue
        public var filterContentDarkColor: UIColor = .systemBlue
        public var filterFont: UIFont
        public init() {
            textFont = .mediumPingFang(ofSize: 15)
            filterFont = .regularPingFang(ofSize: 13)
        }
        
        public mutating func setThemeColor(_ color: UIColor) {
            filterContentColor = color
            filterContentDarkColor = color
        }
    }
}
