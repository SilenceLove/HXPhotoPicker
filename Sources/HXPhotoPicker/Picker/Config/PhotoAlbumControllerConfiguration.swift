//
//  PhotoAlbumControllerConfiguration.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/20.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

// MARK: Album Controller configuration / 相册控制器配置
public struct PhotoAlbumControllerConfiguration {
    
    public var albumController: PhotoAlbumController.Type = PhotoAlbumViewController.self
    
    public var leftNavigationItems: [PhotoNavigationItem.Type] = []
    
    public var rightNavigationItems: [PhotoNavigationItem.Type] = [PhotoTextCancelItemView.self]
    
    /// Prompt color under Accessibility
    /// 可访问权限下的提示语颜色
    public var limitedStatusPromptColor: UIColor = "#999999".hx.color
    
    /// Hint color for dark style accessibility
    /// 暗黑风格可访问权限下的提示语颜色
    public var limitedStatusPromptDarkColor: UIColor = "#999999".hx.color
    
    /// list background color
    /// 列表背景颜色
    public var backgroundColor: UIColor = .white
    
    /// Table background color under dark style
    /// 暗黑风格下列表背景颜色
    public var backgroundDarkColor: UIColor = .black
    
    /// cell背景颜色
    public var cellBackgroundColor: UIColor = .white
    
    /// Cell background color in dark style
    /// 暗黑风格下cell背景颜色
    public var cellBackgroundDarkColor: UIColor = .black
    
    /// The color of the cell when it is selected
    /// cell选中时的颜色
    public var cellSelectedColor: UIColor?
    
    /// The color of the cell when the cell is selected in the dark style
    /// 暗黑风格下cell选中时的颜色
    public var cellSelectedDarkColor: UIColor = .init(
        red: 0.125,
        green: 0.125,
        blue: 0.125,
        alpha: 1
    )
    
    /// header标题颜色
    public var headerTitleColor: UIColor = .black
    
    /// Album name color in dark style
    /// 暗黑风格下header标题颜色
    public var headerTitleDarkColor: UIColor = .white
    
    /// header标题字体
    public var headerTitleFont: UIFont
    
    /// header按钮颜色
    public var headerButtonTitleColor: UIColor = .systemBlue
    
    /// Album name color in dark style
    /// 暗黑风格下header按钮颜色
    public var headerButtonTitleDarkColor: UIColor = .systemBlue
    
    /// header按钮字体
    public var headerButtonTitleFont: UIFont
    
    /// 相册名称颜色
    public var albumNameColor: UIColor = .black
    
    /// Album name color in dark style
    /// 暗黑风格下相册名称颜色
    public var albumNameDarkColor: UIColor = .white
    
    /// 相册名称字体
    public var albumNameFont: UIFont
    
    /// 照片数量颜色
    public var photoCountColor: UIColor = "#999999".hx.color
    
    /// Photo quantity color in dark style
    /// 暗黑风格下照片数量颜色
    public var photoCountDarkColor: UIColor = "#dadada".hx.color
    
    /// Whether to show the number of photos
    /// 是否显示照片数量
    public var isShowPhotoCount: Bool = true
    
    /// photo quantity font
    /// 照片数量字体
    public var photoCountFont: UIFont
    
    /// Divider color
    /// 分隔线颜色
    public var separatorLineColor: UIColor = "#e1e1e1".hx.color
    
    /// Divider color in dark style
    /// 暗黑风格下分隔线颜色
    public var separatorLineDarkColor: UIColor = "#434344".hx.color.withAlphaComponent(0.6)
    
    /// 媒体类型图标的颜色
    public var imageColor: UIColor = .systemBlue
    
    /// 暗黑风格媒体类型图标的颜色
    public var imageDarkColor: UIColor = .systemBlue
    
    /// 媒体类型名称颜色
    public var mediaTitleColor: UIColor = .systemBlue
    
    /// Album name color in dark style
    /// 暗黑风格下媒体类型名称颜色
    public var mediaTitleDarkColor: UIColor = .systemBlue
    
    /// 媒体类型名称字体
    public var mediaTitleFont: UIFont
    
    /// 媒体类型数量颜色
    public var mediaCountColor: UIColor = "#999999".hx.color
    
    /// 暗黑风格下媒体类型数量颜色
    public var mediaCountDarkColor: UIColor = "#dadada".hx.color
    
    /// 媒体类型数量字体
    public var mediaCountFont: UIFont
    
    /// cell上箭头的颜色
    public var arrowColor: UIColor = "#999999".hx.color
    
    /// 暗黑风格下cell上箭头的颜色
    public var arrowDarkColor: UIColor = "#dadada".hx.color
    
    public init() {
        albumNameFont = .systemFont(ofSize: 15, weight: .medium)
        photoCountFont = .systemFont(ofSize: 13, weight: .medium)
        mediaTitleFont = .systemFont(ofSize: 19, weight: .regular)
        mediaCountFont = .systemFont(ofSize: 15, weight: .regular)
        headerTitleFont = .systemFont(ofSize: 21, weight: .semibold)
        headerButtonTitleFont = .systemFont(ofSize: 16, weight: .regular)
    }
    
    public mutating func setThemeColor(_ color: UIColor) {
        headerButtonTitleColor = color
        headerButtonTitleDarkColor = color
        imageColor = color
        imageDarkColor = color
        mediaTitleColor = color
        mediaTitleDarkColor = color
    }
}
