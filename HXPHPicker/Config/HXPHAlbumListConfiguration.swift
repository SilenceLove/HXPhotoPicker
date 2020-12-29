//
//  HXPHAlbumListConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

// MARK: 相册列表配置类
public class HXPHAlbumListConfiguration: NSObject {
    
    /// 可访问权限下的提示语颜色
    public lazy var limitedStatusPromptColor: UIColor = {
        return "#999999".hx_color
    }()
    
    /// 暗黑风格可访问权限下的提示语颜色
    public lazy var limitedStatusPromptDarkColor: UIColor = {
        return "#999999".hx_color
    }()
    
    /// 当相册里没有资源时的相册名称
    public lazy var emptyAlbumName: String = {
        return "所有照片"
    }()
    
    /// 当相册里没有资源时的封面图片名
    public lazy var emptyCoverImageName: String = {
        return "hx_picker_album_empty"
    }()
    
    /// 列表背景颜色
    public lazy var backgroundColor : UIColor = {
        return UIColor.white
    }()
    
    /// 暗黑风格下列表背景颜色
    public lazy var backgroundDarkColor : UIColor = {
        return "#2E2F30".hx_color
    }()
    
    /// 自定义cell，继承 HXAlbumViewCell 加以修改
    public var customCellClass: HXAlbumViewCell.Type?
    
    /// cell高度
    public var cellHeight : CGFloat = 100
    
    /// cell背景颜色
    public lazy var cellBackgroundColor: UIColor = {
        return UIColor.white
    }()
    
    /// 暗黑风格下cell背景颜色
    public lazy var cellbackgroundDarkColor : UIColor = {
        return "#2E2F30".hx_color
    }()
    
    /// cell选中时的颜色
    public var cellSelectedColor : UIColor?
    
    /// 暗黑风格下cell选中时的颜色
    public lazy var cellSelectedDarkColor : UIColor = {
        return UIColor.init(red: 0.125, green: 0.125, blue: 0.125, alpha: 1)
    }()
    
    /// 相册名称颜色
    public lazy var albumNameColor : UIColor = {
        return .black
    }()
    
    /// 暗黑风格下相册名称颜色
    public lazy var albumNameDarkColor : UIColor = {
        return .white
    }()
    
    /// 相册名称字体
    public lazy var albumNameFont : UIFont = {
        return UIFont.hx_mediumPingFang(size: 15)
    }()
    
    /// 照片数量颜色
    public lazy var photoCountColor : UIColor = {
        return "#999999".hx_color
    }()
    
    /// 暗黑风格下相册名称颜色
    public lazy var photoCountDarkColor : UIColor = {
        return "#dadada".hx_color
    }()
    
    /// 照片数量字体
    public lazy var photoCountFont : UIFont = {
        return UIFont.hx_mediumPingFang(size: 12)
    }()
    
    /// 分隔线颜色
    public lazy var separatorLineColor: UIColor = {
        return "#eeeeee".hx_color
    }()
    
    /// 暗黑风格下分隔线颜色
    public lazy var separatorLineDarkColor : UIColor = {
        return "#434344".hx_color.withAlphaComponent(0.6)
    }()
    
    /// 选中勾勾的颜色
    public lazy var tickColor: UIColor = {
        return "#333333".hx_color
    }()
    
    /// 暗黑风格选中勾勾的颜色
    public lazy var tickDarkColor : UIColor = {
        return "#ffffff".hx_color
    }()
}
