//
//  PickerConfiguration.swift
//  照片选择器-Swift
//
//  Created by Silence on 2020/11/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

public class PickerConfiguration: BaseConfiguration {
    
    /// 资源可选项，控制获取系统相册资源的类型
    /// .livePhoto .gifPhoto 是photo的子项
    /// 默认只获取静态图片和视频
    public var selectOptions: PickerAssetOptions = [.photo, .video]
    
    /// 选择模式
    public var selectMode: PickerSelectMode = .multiple
    
    /// 照片和视频可以一起选择
    public var allowSelectedTogether: Bool = true
    
    /// 允许加载系统照片库
    public var allowLoadPhotoLibrary: Bool = true
    
    /// 选择照片时，先判断是否在iCloud上。如果在iCloud上会先同步iCloud上的资源
    /// 如果在断网或者系统iCloud出错的情况下:
    /// true: 选择失败
    /// fasle: 获取原始图片会失败
    public var allowSyncICloudWhenSelectPhoto: Bool = true
    
    /// 相册展示模式
    public var albumShowMode: AlbumShowMode = .normal
    
    /// 获取资源列表时是否按创建时间排序
    public var creationDate: Bool = false
    
    /// 资源列表照片Cell点击动作
    public var photoSelectionTapAction: SelectionTapAction = .preview
    
    /// 资源列表视频Cell点击动作
    public var videoSelectionTapAction: SelectionTapAction = .preview
    
    /// 最多可以选择的照片数，如果为0则不限制
    public var maximumSelectedPhotoCount: Int = 0
    
    /// 最多可以选择的视频数，如果为0则不限制
    public var maximumSelectedVideoCount: Int = 0
    
    /// 最多可以选择的资源数，如果为0则不限制
    public var maximumSelectedCount: Int = 9
    
    /// 视频最大选择时长，为0则不限制
    public var maximumSelectedVideoDuration: Int = 0
    
    /// 视频最小选择时长，为0则不限制
    public var minimumSelectedVideoDuration: Int = 0
    
    /// 视频选择的最大文件大小，为0则不限制
    public var maximumSelectedVideoFileSize: Int = 0
    
    /// 照片选择的最大文件大小，为0则不限制
    public var maximumSelectedPhotoFileSize: Int = 0
    
    #if HXPICKER_ENABLE_EDITOR
    /// 可编辑资源类型
    /// 视频允许编辑：当选择的视频时长超过限制将自动进入编辑界面
    /// 显示编辑按钮的配置为：previewView.bottomView.editButtonHidden
    public var editorOptions: PickerAssetOptions = [.photo, .video]
    
    /// 视频最大编辑时长，为0则不限制，超过限制不可编辑（视频时长超出最大选择时长才生效）
    public var maximumVideoEditDuration: Int = 0
    
    /// 视频编辑配置
    public lazy var videoEditor: VideoEditorConfiguration = .init()
    
    /// 照片编辑配置
    public lazy var photoEditor: PhotoEditorConfiguration = .init()
    
    /// 跳转编辑界面自定义转场动画
    public var editorCustomTransition: Bool = true
    #endif
    
    /// 状态栏样式
    public var statusBarStyle: UIStatusBarStyle = .default
    
    /// 半透明效果
    public var navigationBarIsTranslucent: Bool = true
    
    /// 导航控制器背景颜色
    public var navigationViewBackgroundColor: UIColor = .white
    
    /// 暗黑风格下导航控制器背景颜色
    public var navigationViewBackgroudDarkColor: UIColor = "#2E2F30".color
    
    /// 导航栏样式
    public var navigationBarStyle: UIBarStyle = .default
    
    /// 暗黑风格下导航栏样式
    public var navigationBarDarkStyle: UIBarStyle = .black
    
    public var adaptiveBarAppearance: Bool = true
    
    /// 导航栏标题颜色
    public var navigationTitleColor: UIColor = .black
    
    /// 暗黑风格下导航栏标题颜色
    public var navigationTitleDarkColor: UIColor = .white
    
    /// TintColor
    public var navigationTintColor: UIColor?
    
    /// 暗黑风格下TintColor
    public var navigationDarkTintColor: UIColor?
    
    /// 相册列表配置
    public lazy var albumList: AlbumListConfiguration = .init()
    
    /// 照片列表配置
    public lazy var photoList: PhotoListConfiguration = .init()
    
    /// 预览界面配置
    public lazy var previewView: PreviewViewConfiguration = .init()
    
    /// 未授权提示界面相关配置
    public lazy var notAuthorized: NotAuthorizedConfiguration = .init()
    
    /// 是否缓存[相机胶卷/所有照片]相册
    public var isCacheCameraAlbum: Bool = true
    
    public override init() {
        super.init()
        PhotoManager.shared.isCacheCameraAlbum = isCacheCameraAlbum
    }
}
