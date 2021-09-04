//
//  AlbumListConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: 相册列表配置类
public class AlbumListConfiguration {
    
    /// 可访问权限下的提示语颜色
    public lazy var limitedStatusPromptColor: UIColor = "#999999".color
    
    /// 暗黑风格可访问权限下的提示语颜色
    public lazy var limitedStatusPromptDarkColor: UIColor = "#999999".color
    
    /// 当相册里没有资源时的相册名称
    public lazy var emptyAlbumName: String = "所有照片"
    
    /// 当相册里没有资源时的封面图片名
    public lazy var emptyCoverImageName: String = "hx_picker_album_empty"
    
    /// 列表背景颜色
    public lazy var backgroundColor: UIColor = .white
    
    /// 暗黑风格下列表背景颜色
    public lazy var backgroundDarkColor: UIColor = "#2E2F30".color
    
    /// 自定义cell，继承 AlbumViewCell 加以修改
    public var customCellClass: AlbumViewCell.Type?
    
    /// cell高度
    public var cellHeight: CGFloat = 100
    
    /// cell背景颜色
    public lazy var cellBackgroundColor: UIColor = .white
    
    /// 暗黑风格下cell背景颜色
    public lazy var cellbackgroundDarkColor: UIColor = "#2E2F30".color
    
    /// cell选中时的颜色
    public var cellSelectedColor: UIColor?
    
    /// 暗黑风格下cell选中时的颜色
    public lazy var cellSelectedDarkColor: UIColor = .init(
        red: 0.125,
        green: 0.125,
        blue: 0.125,
        alpha: 1
    )
    
    /// 相册名称颜色
    public lazy var albumNameColor: UIColor = .black
    
    /// 暗黑风格下相册名称颜色
    public lazy var albumNameDarkColor: UIColor = .white
    
    /// 相册名称字体
    public lazy var albumNameFont: UIFont = .mediumPingFang(ofSize: 15)
    
    /// 照片数量颜色
    public lazy var photoCountColor: UIColor = "#999999".color
    
    /// 暗黑风格下相册名称颜色
    public lazy var photoCountDarkColor: UIColor = "#dadada".color
    
    /// 照片数量字体
    public lazy var photoCountFont: UIFont = .mediumPingFang(ofSize: 12)
    
    /// 分隔线颜色
    public lazy var separatorLineColor: UIColor = "#eeeeee".color
    
    /// 暗黑风格下分隔线颜色
    public lazy var separatorLineDarkColor: UIColor = "#434344".color.withAlphaComponent(0.6)
    
    /// 选中勾勾的颜色
    public lazy var tickColor: UIColor = "#333333".color
    
    /// 暗黑风格选中勾勾的颜色
    public lazy var tickDarkColor: UIColor = "#ffffff".color
    
    public init() { }
}
