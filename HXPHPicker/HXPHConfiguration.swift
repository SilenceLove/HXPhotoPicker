//
//  HXPHConfiguration.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2020/11/9.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

class HXPHConfiguration: NSObject {
    
    /// 选择的类型
    var selectType : HXPHSelectType = HXPHSelectType.any
    
    /// 最多可以选择的照片数，如果为0则不限制
    var maximumSelectPhotoCount : Int = 0
    
    /// 最多可以选择的视频数，如果为0则不限制
    var maximumSelectVideoCount : Int = 0
    
    /// 最多可以选择的资源数，如果为0则不限制
    var maximumSelectCount: Int = 9
    
    /// 视频最大选择时长，为0则不限制
    var videoMaximumSelectDuration: Int = 0
    
    /// 视频最小选择时长，为0则不限制
    var videoMinimumSelectDuration: Int = 0
    
    /// 照片和视频可以一起选择
    var photosAndVideosCanBeSelectedTogether: Bool = true
    
    /// 语言类型
    var languageType : HXPHLanguageType = HXPHLanguageType.system
    
    /// 相册展示类型
    var albumShowMode : HXAlbumShowMode = HXAlbumShowMode.normal
    
    /// 选择模式
    var selectMode : HXPHAssetSelectMode = HXPHAssetSelectMode.multiple
    
    /// 获取资源列表时是否按创建时间排序
    var creationDate : Bool = true
    
    /// 获取资源列表后是否按倒序展示
    var reverseOrder : Bool = false
    
    /// 展示动图
    var showAnimatedAsset : Bool = true
    
    /// 展示LivePhoto
    var showLivePhotoAsset : Bool = true
    
    /// 状态栏样式
    var statusBarStyle : UIStatusBarStyle = UIStatusBarStyle.default
    
    /// 半透明效果
    var navigationBarIsTranslucent: Bool = true
    
    /// 相册列表配置
    lazy var albumList : HXPHAlbumListConfiguration = {
        return HXPHAlbumListConfiguration.init()
    }()
    
    /// 照片列表配置
    lazy var photoList: HXPHPhotoListConfiguration = {
        return HXPHPhotoListConfiguration.init()
    }()
    
    /// 预览界面配置
    lazy var previewView: HXPHPreviewViewConfiguration = {
        return HXPHPreviewViewConfiguration.init()
    }()
    
    /// 未授权提示界面相关配置
    lazy var notAuthorized : HXPHNotAuthorizedConfiguration = {
        return HXPHNotAuthorizedConfiguration.init()
    }()
}
// MARK: 相册列表配置类
class HXPHAlbumListConfiguration: NSObject {
    
    /// 当相册里没有资源时的相册名称
    lazy var emptyAlbumName: String = {
        return "所有照片"
    }()
    
    /// 当相册里没有资源时的封面图片名
    lazy var emptyCoverImageName: String = {
        return ""
    }()
    
    /// 列表背景颜色
    lazy var backgroundColor : UIColor = {
        return UIColor.white
    }()
    
    /// cell高度
    var cellHeight : CGFloat = 100
    
    /// cell背景颜色
    lazy var cellBackgroudColor: UIColor = {
        return UIColor.white
    }()
    
    /// cell选中时的颜色
    var cellSelectedColor : UIColor?
    
    /// 相册名称颜色
    lazy var albumNameColor : UIColor = {
        return UIColor.black
    }()
    
    /// 相册名称字体
    lazy var albumNameFont : UIFont = {
        return UIFont.hx_mediumPingFang(size: 15)
    }()
    
    /// 照片数量颜色
    lazy var photoCountColor : UIColor = {
        return UIColor.init(hx_hexString: "#999999")
    }()
    
    /// 照片数量字体
    lazy var photoCountFont : UIFont = {
        return UIFont.hx_mediumPingFang(size: 12)
    }()
    
    /// 分隔线颜色
    lazy var separatorLineColor: UIColor = {
        return UIColor(hx_hexString: "#eeeeee")
    }()
}
// MARK: 照片列表配置类
class HXPHPhotoListConfiguration: NSObject {
    
    /// 背景颜色
    lazy var backgroundColor : UIColor = {
        return UIColor.white
    }()
    
    /// 每行显示数量
    var rowNumber : Int = 4
    
    /// 横屏时每行显示数量
    var landscapeRowNumber : Int = 7
    
    /// 每个照片之间的间隙
    var spacing : CGFloat = 1
    
    /// cell相关配置
    lazy var cell: HXPHPhotoListCellConfiguration = {
        return HXPHPhotoListCellConfiguration.init()
    }()
    
    /// 底部视图相关配置
    lazy var bottomView: HXPHPickerBottomViewConfiguration = {
        return HXPHPickerBottomViewConfiguration.init()
    }()
}
// MARK: 照片列表Cell配置类
class HXPHPhotoListCellConfiguration: NSObject {
    
    /// 背景颜色
    var backgroundColor: UIColor?
    
    /// 选择框顶部的间距
    var selectBoxTopMargin: CGFloat = 5
    
    /// 选择框右边的间距
    var selectBoxRightMargin: CGFloat = 5
    
    /// 选择框相关配置
    lazy var selectBox: HXPHSelectBoxConfiguration = {
        return HXPHSelectBoxConfiguration.init()
    }()
}
// MARK: 预览界面配置类
class HXPHPreviewViewConfiguration: NSObject {
    
    /// 背景颜色
    lazy var backgroundColor : UIColor = {
        return UIColor.white
    }()
    
    /// 选择框配置
    lazy var selectBox: HXPHSelectBoxConfiguration = {
        let config = HXPHSelectBoxConfiguration.init()
        return config
    }()
    
    /// 底部视图相关配置
    lazy var bottomView: HXPHPickerBottomViewConfiguration = {
        let config = HXPHPickerBottomViewConfiguration.init()
        config.previewButtonHidden = true
        return config
    }()
}
// MARK: 底部工具栏配置类
class HXPHPickerBottomViewConfiguration: NSObject {
    
    /// UIToolbar
    var backgroundColor: UIColor?
    
    /// UIToolbar
    var barTintColor: UIColor?
    
    /// 半透明效果
    var isTranslucent: Bool = true
    
    /// barStyle
    var barStyle: UIBarStyle = UIBarStyle.default
    
    /// 隐藏预览按钮
    var previewButtonHidden: Bool = false
    
    /// 预览按钮标题颜色
    lazy var previewButtonTitleColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }()
    
    /// 预览按钮禁用下的标题颜色
    var previewButtonDisableTitleColor: UIColor?
    
    /// 隐藏原图按钮
    var originalButtonHidden : Bool = false
    
    /// 原图按钮标题颜色
    lazy var originalButtonTitleColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }()
    
    /// 原图按钮选择框相关配置
    lazy var originalSelectBox: HXPHSelectBoxConfiguration = {
        let config = HXPHSelectBoxConfiguration.init()
        config.type = HXPHPickerCellSelectBoxType.tick
        // 原图按钮选中时的背景颜色
        config.selectedBackgroudColor = UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
        // 原图按钮未选中时的边框宽度
        config.borderWidth = 1
        // 原图按钮未选中时的边框颜色
        config.borderColor = config.selectedBackgroudColor
        // 原图按钮未选中时框框中间的颜色
        config.backgroudColor = UIColor.white.withAlphaComponent(0.3)
        // 原图按钮选中时的勾勾颜色
        config.tickColor = UIColor.white
        // 原图按钮选中时的勾勾宽度
        config.tickWidth = 1
        return config
    }()
    
    /// 完成按钮标题颜色
    lazy var finishButtonTitleColor: UIColor = {
        return UIColor.white
    }()
    
    /// 完成按钮禁用下的标题颜色
    lazy var finishButtonDisableTitleColor: UIColor = {
        return UIColor.white.withAlphaComponent(0.6)
    }()
    
    /// 完成按钮选中时的背景颜色
    lazy var finishButtonBackgroudColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }()
    
    /// 完成按钮禁用时的背景颜色
    lazy var finishButtonDisableBackgroudColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1).withAlphaComponent(0.4)
    }()
    
    /// 未选择资源时是否禁用完成按钮
    var disableFinishButtonWhenNotSelected: Bool = false
}
// MARK: 选择框配置类
class HXPHSelectBoxConfiguration: NSObject {
    
    /// 选择框的大小
    var size: CGSize = CGSize(width: 25, height: 25)
    
    /// 选择框的类型
    var type: HXPHPickerCellSelectBoxType = HXPHPickerCellSelectBoxType.number
    
    /// 标题的文字大小
    var titleFontSize: CGFloat = 16
    
    /// 选中之后的 标题 颜色
    lazy var titleColor: UIColor = {
        return UIColor.white
    }()
    
    /// 选中状态下勾勾的宽度
    var tickWidth: CGFloat = 2
    
    /// 选中之后的 勾勾 颜色
    lazy var tickColor: UIColor = {
        return UIColor.white
    }()
    
    /// 未选中时框框中间的颜色
    lazy var backgroudColor: UIColor = {
        return UIColor.black.withAlphaComponent(0.4)
    }()
    
    /// 选中之后的背景颜色
    lazy var selectedBackgroudColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }()
    
    /// 未选中时的边框宽度
    var borderWidth: CGFloat = 1.5
    
    /// 未选中时的边框颜色
    lazy var borderColor: UIColor = {
        return UIColor.white
    }()
    
}

// MARK: 未授权界面配置类
class HXPHNotAuthorizedConfiguration: NSObject {
    
    /// 背景颜色
    lazy var backgroudColor: UIColor = {
        return UIColor.white
    }()
    
    /// 关闭按钮图片名
    lazy var closeButtonImageName: String = {
        return ""
    }()
    
    /// 标题颜色
    lazy var titleColor: UIColor = {
        return UIColor.black
    }()
    
    /// 子标题颜色
    lazy var subTitleColor: UIColor = {
        return UIColor(hx_hexString: "#444444")
    }()
    
    /// 跳转按钮背景颜色
    lazy var jumpButtonBackgroudColor: UIColor = {
        return UIColor(hx_hexString: "666666")
    }()
    
    /// 跳转按钮文字颜色
    lazy var jumpButtonTitleColor: UIColor = {
        return UIColor(hx_hexString: "ffffff")
    }()
}
