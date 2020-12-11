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
    var selectType : HXPHPicker.SelectType = .any
    
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
    var allowSelectedTogether: Bool = true
    
    /// 语言类型
    var languageType : HXPHPicker.LanguageType = .system
    
    /// 相册展示模式
    var albumShowMode : HXPHPicker.Album.ShowMode = .normal
    
    /// 外观风格
    var appearanceStyle: HXPHPicker.AppearanceStyle = .varied
    
    /// 选择模式
    var selectMode : HXPHPicker.SelectMode = .multiple
    
    /// 获取资源列表时是否按创建时间排序
    var creationDate : Bool = false
    
    /// 获取资源列表后是否按倒序展示
    var reverseOrder : Bool = false
    
    /// 展示动图
    var showImageAnimated : Bool = true
    
    /// 展示LivePhoto
    var showLivePhoto : Bool = true
    
    /// 状态栏样式
    var statusBarStyle : UIStatusBarStyle = .default
    
    /// 半透明效果
    var navigationBarIsTranslucent: Bool = true
    
    /// 导航控制器背景颜色
    var navigationViewBackgroundColor: UIColor = UIColor.white
    
    /// 暗黑风格下导航控制器背景颜色
    var navigationViewBackgroudDarkColor: UIColor = "#2E2F30".hx_color
    
    var navigationBarStyle: UIBarStyle = .default
    
    var navigationBarDarkStyle: UIBarStyle = .black
    
    /// 导航栏标题颜色
    var navigationTitleColor: UIColor = UIColor.black
    
    /// 暗黑风格下导航栏标题颜色
    var navigationTitleDarkColor: UIColor = UIColor.white
    
    /// TintColor
    var navigationTintColor: UIColor?
    
    /// 暗黑风格下TintColor
    var navigationDarkTintColor: UIColor = UIColor.white
    
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
    
    /// 可访问权限下的提示语颜色
    lazy var limitedStatusPromptColor: UIColor = {
        return "#999999".hx_color
    }()
    
    /// 暗黑风格可访问权限下的提示语颜色
    lazy var limitedStatusPromptDarkColor: UIColor = {
        return "#999999".hx_color
    }()
    
    /// 当相册里没有资源时的相册名称
    lazy var emptyAlbumName: String = {
        return "所有照片".hx_localized
    }()
    
    /// 当相册里没有资源时的封面图片名
    lazy var emptyCoverImageName: String = {
        return "hx_picker_album_empty"
    }()
    
    /// 列表背景颜色
    lazy var backgroundColor : UIColor = {
        return UIColor.white
    }()
    
    /// 暗黑风格下列表背景颜色
    lazy var backgroundDarkColor : UIColor = {
        return "#2E2F30".hx_color
    }()
    
    /// cell高度
    var cellHeight : CGFloat = 100
    
    /// cell背景颜色
    lazy var cellBackgroundColor: UIColor = {
        return UIColor.white
    }()
    
    /// 暗黑风格下cell背景颜色
    lazy var cellbackgroundDarkColor : UIColor = {
        return "#2E2F30".hx_color
    }()
    
    /// cell选中时的颜色
    var cellSelectedColor : UIColor?
    
    /// 暗黑风格下cell选中时的颜色
    lazy var cellSelectedDarkColor : UIColor = {
        return UIColor.init(red: 0.125, green: 0.125, blue: 0.125, alpha: 1)
    }()
    
    /// 相册名称颜色
    lazy var albumNameColor : UIColor = {
        return .black
    }()
    
    /// 暗黑风格下相册名称颜色
    lazy var albumNameDarkColor : UIColor = {
        return .white
    }()
    
    /// 相册名称字体
    lazy var albumNameFont : UIFont = {
        return UIFont.hx_mediumPingFang(size: 15)
    }()
    
    /// 照片数量颜色
    lazy var photoCountColor : UIColor = {
        return "#999999".hx_color
    }()
    
    /// 暗黑风格下相册名称颜色
    lazy var photoCountDarkColor : UIColor = {
        return "#dadada".hx_color
    }()
    
    /// 照片数量字体
    lazy var photoCountFont : UIFont = {
        return UIFont.hx_mediumPingFang(size: 12)
    }()
    
    /// 分隔线颜色
    lazy var separatorLineColor: UIColor = {
        return "#eeeeee".hx_color
    }()
    
    /// 暗黑风格下分隔线颜色
    lazy var separatorLineDarkColor : UIColor = {
        return "#434344".hx_color.withAlphaComponent(0.6)
    }()
    
    /// 选中勾勾的颜色
    lazy var tickColor: UIColor = {
        return "#333333".hx_color
    }()
    
    /// 暗黑风格选中勾勾的颜色
    lazy var tickDarkColor : UIColor = {
        return "#ffffff".hx_color
    }()
}
// MARK: 相册标题视图配置类
class HXAlbumTitleViewConfiguration: NSObject {
    
    /// 背景颜色
    var backgroundColor: UIColor?
    
    /// 暗黑风格下背景颜色
    var backgroudDarkColor: UIColor?
    
    /// 箭头背景颜色
    lazy var arrowBackgroundColor: UIColor = {
        return "#333333".hx_color
    }()
    
    /// 箭头颜色
    lazy var arrowColor: UIColor = {
        return "#ffffff".hx_color
    }()
    
    /// 暗黑风格下箭头背景颜色
    lazy var arrowBackgroudDarkColor: UIColor = {
        return "#ffffff".hx_color
    }()
    
    /// 暗黑风格下箭头颜色
    lazy var arrowDarkColor: UIColor = {
        return "#333333".hx_color
    }()
}
// MARK: 照片列表配置类
class HXPHPhotoListConfiguration: NSObject {
    
    /// 相册标题视图配置
    lazy var titleViewConfig: HXAlbumTitleViewConfiguration = {
        let titleViewConfig = HXAlbumTitleViewConfiguration.init()
        return titleViewConfig
    }()
    
    /// 背景颜色
    lazy var backgroundColor : UIColor = {
        return UIColor.white
    }()
    
    /// 暗黑风格下背景颜色
    lazy var backgroundDarkColor : UIColor = {
        return "#2E2F30".hx_color
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
        let bottomView = HXPHPickerBottomViewConfiguration.init()
        bottomView.showPrompt = true
        return bottomView
    }()
    
    /// 没有资源时展示的相关配置
    lazy var notAsset : HXPHNotAssetConfiguration = {
        return HXPHNotAssetConfiguration.init()
    }()
}
// MARK: 照片列表Cell配置类
class HXPHPhotoListCellConfiguration: NSObject {
    
    /// 背景颜色
    var backgroundColor: UIColor?
    
    /// 暗黑风格下背景颜色
    var backgroundDarkColor : UIColor?
    
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
        return .white
    }()
    
    /// 暗黑风格下背景颜色
    lazy var backgroundDarkColor : UIColor = {
        return .black
    }()
    
    /// 选择框配置
    lazy var selectBox: HXPHSelectBoxConfiguration = {
        let config = HXPHSelectBoxConfiguration.init()
        return config
    }()
    
    /// 自动播放视频
    var autoPlayVideo: Bool = false
    
    /// 底部视图相关配置
    lazy var bottomView: HXPHPickerBottomViewConfiguration = {
        let config = HXPHPickerBottomViewConfiguration.init()
        config.previewButtonHidden = true
        config.disableFinishButtonWhenNotSelected = false
        config.editButtonHidden = true
        return config
    }()
}
// MARK: 底部工具栏配置类
class HXPHPickerBottomViewConfiguration: NSObject {
    
    /// UIToolbar
    var backgroundColor: UIColor?
    var backgroundDarkColor: UIColor?
    
    /// UIToolbar
    var barTintColor: UIColor?
    var barTintDarkColor: UIColor?
    
    /// 半透明效果
    var isTranslucent: Bool = true
    
    /// barStyle
    var barStyle: UIBarStyle = UIBarStyle.default
    var barDarkStyle: UIBarStyle = UIBarStyle.black
    
    /// 隐藏预览按钮
    var previewButtonHidden: Bool = false
    
    /// 预览按钮标题颜色
    lazy var previewButtonTitleColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }()
    
    /// 暗黑风格下预览按钮标题颜色
    lazy var previewButtonTitleDarkColor: UIColor = {
        return .white
    }()
    
    /// 预览按钮禁用下的标题颜色
    var previewButtonDisableTitleColor: UIColor?
    var previewButtonDisableTitleDarkColor: UIColor?
    
    /// 隐藏原图按钮
    var originalButtonHidden : Bool = false
    
    /// 原图按钮标题颜色
    lazy var originalButtonTitleColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }()
    
    /// 暗黑风格下预览按钮标题颜色
    lazy var originalButtonTitleDarkColor: UIColor = {
        return .white
    }()
    
    /// 原图按钮选择框相关配置
    lazy var originalSelectBox: HXPHSelectBoxConfiguration = {
        let config = HXPHSelectBoxConfiguration.init()
        config.type = .tick
        // 原图按钮选中时的背景颜色
        config.selectedBackgroundColor = UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
        // 暗黑风格下原图按钮选中时的背景颜色
        config.selectedBackgroudDarkColor = UIColor.white
        // 原图按钮未选中时的边框宽度
        config.borderWidth = 1
        // 原图按钮未选中时的边框颜色
        config.borderColor = config.selectedBackgroundColor
        // 暗黑风格下原图按钮未选中时的边框颜色
        config.borderDarkColor = UIColor.white
        // 原图按钮未选中时框框中间的颜色
        config.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        // 原图按钮选中时的勾勾宽度
        config.tickWidth = 1
        return config
    }()
    
    /// 完成按钮标题颜色
    lazy var finishButtonTitleColor: UIColor = {
        return UIColor.white
    }()
    
    /// 暗黑风格下完成按钮标题颜色
    lazy var finishButtonTitleDarkColor: UIColor = {
        return .black
    }()
    
    /// 完成按钮禁用下的标题颜色
    lazy var finishButtonDisableTitleColor: UIColor = {
        return UIColor.white.withAlphaComponent(0.6)
    }()
    
    /// 暗黑风格下完成按钮禁用下的标题颜色
    lazy var finishButtonDisableTitleDarkColor: UIColor = {
        return UIColor.black.withAlphaComponent(0.6)
    }()
    
    /// 完成按钮选中时的背景颜色
    lazy var finishButtonBackgroundColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }()
    
    /// 暗黑风格下完成按钮选中时的背景颜色
    lazy var finishButtonDarkBackgroundColor: UIColor = {
        return .white
    }()
    
    /// 完成按钮禁用时的背景颜色
    lazy var finishButtonDisableBackgroundColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1).withAlphaComponent(0.4)
    }()
    
    /// 暗黑风格下完成按钮禁用时的背景颜色
    lazy var finishButtonDisableDarkBackgroundColor: UIColor = {
        return UIColor.white.withAlphaComponent(0.4)
    }()
    
    /// 未选择资源时是否禁用完成按钮
    var disableFinishButtonWhenNotSelected: Bool = true
    
    /// 隐藏编辑按钮
    var editButtonHidden: Bool = true
    
    /// 编辑按钮标题颜色
    lazy var editButtonTitleColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }()
    
    /// 暗黑风格下编辑按钮标题颜色
    lazy var editButtonTitleDarkColor: UIColor = {
        return .white
    }()
    
    /// 编辑按钮禁用下的标题颜色
    var editButtonDisableTitleColor: UIColor?
    var editButtonDisableTitleDarkColor: UIColor?
    
    /// 显示提示视图
    var showPrompt: Bool = false
    
    /// 提示图标颜色
    lazy var promptIconColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }()
    
    /// 暗黑风格下提示图标颜色
    lazy var promptIconDarkColor: UIColor = {
        return .white
    }()
    
    /// 提示语颜色
    lazy var promptTitleColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }()
    
    /// 暗黑风格下提示语颜色
    lazy var promptTitleDarkColor: UIColor = {
        return .white
    }()
    
    /// 提示语颜色
    lazy var promptArrowColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }()
    
    /// 暗黑风格下提示语颜色
    lazy var promptArrowDarkColor: UIColor = {
        return .white
    }()
}
// MARK: 选择框配置类
class HXPHSelectBoxConfiguration: NSObject {
    
    /// 选择框的大小
    var size: CGSize = CGSize(width: 25, height: 25)
    
    /// 选择框的类型
    var type: HXPHPicker.PhotoList.Cell.SelectBoxType = .number
    
    /// 标题的文字大小
    var titleFontSize: CGFloat = 16
    
    /// 选中之后的 标题 颜色
    lazy var titleColor: UIColor = {
        return .white
    }()
    
    /// 暗黑风格下选中之后的 标题 颜色
    lazy var titleDarkColor : UIColor = {
        return .white
    }()
    
    /// 选中状态下勾勾的宽度
    var tickWidth: CGFloat = 2
    
    /// 选中之后的 勾勾 颜色
    lazy var tickColor: UIColor = {
        return UIColor.white
    }()
    
    /// 暗黑风格下选中之后的 勾勾 颜色
    lazy var tickDarkColor : UIColor = {
        return .black
    }()
    
    /// 未选中时框框中间的颜色
    lazy var backgroundColor: UIColor = {
        return UIColor.black.withAlphaComponent(0.4)
    }()
    
    /// 暗黑风格下未选中时框框中间的颜色
    lazy var darkBackgroundColor : UIColor = {
        return UIColor.black.withAlphaComponent(0.2)
    }()
    
    /// 选中之后的背景颜色
    lazy var selectedBackgroundColor: UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }()
    
    /// 暗黑风格下选中之后的背景颜色
    lazy var selectedBackgroudDarkColor : UIColor = {
        return UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }()
    
    /// 未选中时的边框宽度
    var borderWidth: CGFloat = 1.5
    
    /// 未选中时的边框颜色
    lazy var borderColor: UIColor = {
        return .white
    }()
    
    /// 暗黑风格下未选中时的边框颜色
    lazy var borderDarkColor : UIColor = {
        return .white
    }()
    
}

// MARK: 未授权界面配置类
class HXPHNotAuthorizedConfiguration: NSObject {
    
    /// 背景颜色
    lazy var backgroundColor: UIColor = {
        return UIColor.white
    }()
    
    /// 暗黑风格下的背景颜色
    lazy var darkBackgroundColor: UIColor = {
        return "#2E2F30".hx_color
    }()
    
    /// 关闭按钮图片名
    lazy var closeButtonImageName: String = {
        return "hx_picker_notAuthorized_close"
    }()
    
    /// 暗黑风格下的关闭按钮图片名
    lazy var closeButtonDarkImageName: String = {
        return "hx_picker_notAuthorized_close_dark"
    }()
    
    /// 标题颜色
    lazy var titleColor: UIColor = {
        return UIColor.black
    }()
    
    /// 暗黑风格下的标题颜色
    lazy var titleDarkColor: UIColor = {
        return .white
    }()
    
    /// 子标题颜色
    lazy var subTitleColor: UIColor = {
        return "#444444".hx_color
    }()
    
    /// 暗黑风格下的子标题颜色
    lazy var darkSubTitleColor: UIColor = {
        return .white
    }()
    
    /// 跳转按钮背景颜色
    lazy var jumpButtonBackgroundColor: UIColor = {
        return "#333333".hx_color
    }()
    
    /// 暗黑风格下跳转按钮背景颜色
    lazy var jumpButtonDarkBackgroundColor: UIColor = {
        return .white
    }()
    
    /// 跳转按钮文字颜色
    lazy var jumpButtonTitleColor: UIColor = {
        return "#ffffff".hx_color
    }()
    
    /// 暗黑风格下跳转按钮文字颜色
    lazy var jumpButtonTitleDarkColor: UIColor = {
        return "#333333".hx_color
    }()
}

class HXPHNotAssetConfiguration: NSObject {
    
    /// 标题颜色
    lazy var titleColor: UIColor = {
        return "#666666".hx_color
    }()
    
    /// 暗黑风格下标题颜色
    lazy var titleDarkColor: UIColor = {
        return "#ffffff".hx_color
    }()
    
    /// 子标题颜色
    lazy var subTitleColor: UIColor = {
        return "#999999".hx_color
    }()
    
    /// 暗黑风格下子标题颜色
    lazy var subTitleDarkColor: UIColor = {
        return "#dadada".hx_color
    }()
}
