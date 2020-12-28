//
//  HXPHConfiguration.swift
//  照片选择器-Swift
//
//  Created by Silence on 2020/11/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import AVFoundation

class HXPHConfiguration: NSObject {
    
    /// 如果自带的语言不够，可以添加自定义的语言文字
    /// HXPHManager.shared.customLanguages 自定义语言数组
    /// HXPHManager.shared.fixedCustomLanguage 如果有多种自定义语言，可以固定显示某一种
    /// 语言类型
    var languageType: HXPHPicker.LanguageType = .system
    
    /// 选择的类型，控制获取系统相册资源的类型
    var selectType : HXPHPicker.SelectType = .any
    
    /// 选择模式
    var selectMode: HXPHPicker.SelectMode = .multiple
    
    /// 照片和视频可以一起选择
    var allowSelectedTogether: Bool = true
    
    /// 允许加载系统照片库
    var allowLoadPhotoLibrary: Bool = true
    
    /// 相册展示模式
    var albumShowMode: HXPHPicker.Album.ShowMode = .normal
    
    /// 外观风格
    var appearanceStyle: HXPHPicker.AppearanceStyle = .varied
    
    /// 获取资源列表时是否按创建时间排序
    var creationDate: Bool = false
    
    /// 获取资源列表后是否按倒序展示
    var reverseOrder: Bool = false
    
    /// 展示动图
    var showImageAnimated: Bool = true
    
    /// 展示LivePhoto
    var showLivePhoto: Bool = true
    
    /// 最多可以选择的照片数，如果为0则不限制
    var maximumSelectedPhotoCount : Int = 0
    
    /// 最多可以选择的视频数，如果为0则不限制
    var maximumSelectedVideoCount : Int = 0
    
    /// 最多可以选择的资源数，如果为0则不限制
    var maximumSelectedCount: Int = 9
    
    /// 视频最大选择时长，为0则不限制
    var maximumSelectedVideoDuration: Int = 0
    
    /// 视频最小选择时长，为0则不限制
    var minimumSelectedVideoDuration: Int = 0
    
    /// 视频选择的最大文件大小，为0则不限制
    /// 如果限制了大小请将 photoList.cell.showDisableMask = false
    /// 限制并且显示遮罩会导致界面滑动卡顿
    var maximumSelectedVideoFileSize: Int = 0
    
    /// 照片选择的最大文件大小，为0则不限制
    /// 如果限制了大小请将 photoList.cell.showDisableMask = false
    /// 限制并且显示遮罩会导致界面滑动卡顿 
    var maximumSelectedPhotoFileSize: Int = 0
    
    /// 允许编辑照片
    var allowEditPhoto: Bool = true
    
    /// 允许编辑视频
    var allowEditVideo: Bool = true
    
    /// 状态栏样式
    var statusBarStyle: UIStatusBarStyle = .default
    
    /// 半透明效果
    var navigationBarIsTranslucent: Bool = true
    
    /// 导航控制器背景颜色
    var navigationViewBackgroundColor: UIColor = UIColor.white
    
    /// 暗黑风格下导航控制器背景颜色
    var navigationViewBackgroudDarkColor: UIColor = "#2E2F30".hx_color
    
    /// 导航栏样式
    var navigationBarStyle: UIBarStyle = .default
    
    /// 暗黑风格下导航栏样式
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
        return "所有照片"
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
    
    /// 自定义cell，继承 HXAlbumViewCell 加以修改
    var customCellClass: HXAlbumViewCell.Type?
    
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
// MARK: 相册标题视图配置类，弹窗展示相册列表时有效
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
    
    /// 取消按钮的配置只有当 albumShowMode = .popup 时有效
    /// 取消按钮类型
    var cancelType: HXPHPicker.PhotoList.CancelType = .text
    
    /// 取消按钮位置
    var cancelPosition: HXPHPicker.PhotoList.CancelPosition = .right
    
    /// 取消按钮图片名
    var cancelImageName: String = "hx_picker_photolist_cancel"
    
    /// 暗黑模式下取消按钮图片名
    var cancelDarkImageName: String = "hx_picker_photolist_cancel"
    
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
        let config = HXPHPickerBottomViewConfiguration.init()
        return config
    }()
    
    /// 允许添加相机
    var allowAddCamera: Bool = true
    
    /// 相机cell配置
    lazy var cameraCell: HXPHPhotoListCameraCellConfiguration = {
        return HXPHPhotoListCameraCellConfiguration.init()
    }()
    
    /// 相机配置
    lazy var camera: HXPHCameraConfiguration = {
        return HXPHCameraConfiguration.init()
    }()
    
    /// 没有资源时展示的相关配置
    lazy var emptyView : HXPHEmptyViewConfiguration = {
        return HXPHEmptyViewConfiguration.init()
    }()
}
// MARK: 照片列表Cell配置类
class HXPHPhotoListCellConfiguration: NSObject {
    
    /// 自定义不带选择框的cell，继承 HXPHPickerViewCell 加以修改
    var customSingleCellClass: HXPHPickerViewCell.Type?
    
    /// 自定义带选择框的cell
    /// 继承 HXPHPickerMultiSelectViewCell 加以修改
    var customMultipleCellClass: HXPHPickerMultiSelectViewCell.Type?
    
    /// 背景颜色
    var backgroundColor: UIColor?
    
    /// 暗黑风格下背景颜色
    var backgroundDarkColor: UIColor?
    
    /// cell在不可选择状态是否显示遮罩
    var showDisableMask: Bool = true
    
    /// 选择框顶部的间距
    var selectBoxTopMargin: CGFloat = 5
    
    /// 选择框右边的间距
    var selectBoxRightMargin: CGFloat = 5
    
    /// 选择框相关配置
    lazy var selectBox: HXPHSelectBoxConfiguration = {
        return HXPHSelectBoxConfiguration.init()
    }()
}
// MARK: 照片列表相机Cell配置类
class HXPHPhotoListCameraCellConfiguration: NSObject {
    /// 允许相机预览
    var allowPreview: Bool = true
    
    /// 背景颜色
    var backgroundColor : UIColor?
    
    /// 暗黑风格下背景颜色
    var backgroundDarkColor : UIColor?
    
    /// 相机图标
    var cameraImageName: String = "hx_picker_photoList_photograph"
    
    /// 暗黑风格下的相机图标
    var cameraDarkImageName: String = "hx_picker_photoList_photograph_white"
}
// MARK: 相机配置类
class HXPHCameraConfiguration: NSObject {
    /// 拍照完成后是否选择
    var takePictureCompletionToSelected: Bool = true
    
    /// 拍照完成后保存到系统相册
    var saveSystemAlbum: Bool = true
    
    /// 保存在自定义相册的名字，为空时则取 BundleName
    var customAlbumName: String?
    
    /// 媒体类型[kUTTypeImage, kUTTypeMovie]，不设置内部会根据selectType配置
    var mediaTypes: [String] = []
    
    /// 视频最大录制时长
    var videoMaximumDuration: TimeInterval = 60
    
    /// 视频质量
    var videoQuality: UIImagePickerController.QualityType = .typeHigh
    
    /// 视频编辑裁剪导出的质量
    var videoEditExportQuality: String = AVAssetExportPresetHighestQuality
    
    /// 默认使用后置相机
    var cameraDevice: UIImagePickerController.CameraDevice = .rear
    
    /// 允许编辑
    var allowsEditing: Bool = true
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
        config.editButtonHidden = false
        config.showSelectedView = true
        return config
    }()
    
    /// 取消按钮的配置只有当是外部预览时才有效，文字和图片颜色通过 navigationTintColor 设置
    /// 取消按钮类型
    var cancelType: HXPHPicker.PhotoList.CancelType = .text
    
    /// 取消按钮位置
    var cancelPosition: HXPHPicker.PhotoList.CancelPosition = .right
    
    /// 取消按钮图片名
    var cancelImageName: String = "hx_picker_photolist_cancel"
    
    /// 暗黑模式下取消按钮图片名
    var cancelDarkImageName: String = "hx_picker_photolist_cancel"
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
    
    /// 暗黑风格下预览按钮禁用下的标题颜色
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
    /// 显示原图文件大小
    var showOriginalFileSize: Bool = true
    
    /// 原图加载菊花类型
    var originalLoadingStyle : UIActivityIndicatorView.Style = .gray
    
    /// 暗黑风格下原图加载菊花类型
    var originalLoadingDarkStyle : UIActivityIndicatorView.Style = .white
    
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
    
    /// 相册权限为选部分时显示提示
    var showPrompt: Bool = true
    
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
    
    /// 显示已选资源
    var showSelectedView: Bool = false
    
    /// 自定义cell，继承 HXPHPreviewSelectedViewCell 加以修改
    var customSelectedViewCellClass: HXPHPreviewSelectedViewCell.Type?
    
    /// 已选资源选中的勾勾颜色
    lazy var selectedViewTickColor: UIColor = {
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
    var tickWidth: CGFloat = 1.5
    
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
// MARK: 照片列表空资源时展示的视图
class HXPHEmptyViewConfiguration: NSObject {
    
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
