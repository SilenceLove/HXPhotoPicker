//
//  AlbumListConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: Album list configuration class / 相册列表配置类
public struct AlbumListConfiguration {
    
    /// Prompt color under Accessibility
    /// 可访问权限下的提示语颜色
    public var limitedStatusPromptColor: UIColor = "#999999".hx.color
    
    /// Hint color for dark style accessibility
    /// 暗黑风格可访问权限下的提示语颜色
    public var limitedStatusPromptDarkColor: UIColor = "#999999".hx.color
    
    /// Album name when there are no resources in the album
    /// 当相册里没有资源时的相册名称
    public var emptyAlbumName: String = "所有照片"
    
    /// The name of the cover image when there are no assets in the album
    /// 当相册里没有资源时的封面图片名
    public var emptyCoverImageName: String = "hx_picker_album_empty"
    
    /// list background color
    /// 列表背景颜色
    public var backgroundColor: UIColor = .white
    
    /// Table background color under dark style
    /// 暗黑风格下列表背景颜色
    public var backgroundDarkColor: UIColor = "#2E2F30".hx.color
    
    /// Customize cell, inherit AlbumViewCell and modify it
    /// 自定义cell，继承 AlbumViewCell 加以修改
    public var customCellClass: AlbumViewCell.Type?
     
    /// cell高度
    public var cellHeight: CGFloat = 100
    
    /// cell背景颜色
    public var cellBackgroundColor: UIColor = .white
    
    /// Cell background color in dark style
    /// 暗黑风格下cell背景颜色
    public var cellbackgroundDarkColor: UIColor = "#2E2F30".hx.color
    
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
    public var separatorLineColor: UIColor = "#eeeeee".hx.color
    
    /// Divider color in dark style
    /// 暗黑风格下分隔线颜色
    public var separatorLineDarkColor: UIColor = "#434344".hx.color.withAlphaComponent(0.6)
    
    /// Check the color of the tick
    /// 选中勾勾的颜色
    public var tickColor: UIColor = .systemBlue
    
    /// Dark style checked tick color
    /// 暗黑风格选中勾勾的颜色
    public var tickDarkColor: UIColor = "#ffffff".hx.color
    
    public init() {
        albumNameFont = .mediumPingFang(ofSize: 15)
        photoCountFont = .mediumPingFang(ofSize: 12)
    }
}
