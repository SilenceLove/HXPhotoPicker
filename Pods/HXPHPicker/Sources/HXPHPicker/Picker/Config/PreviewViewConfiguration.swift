//
//  PreviewViewConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: 预览界面配置类
public struct PreviewViewConfiguration {
    
    /// 自定义视频Cell
    public var customVideoCellClass: PreviewVideoViewCell.Type?
    
    /// 网络视频加载方式
    public var loadNetworkVideoMode: PhotoAsset.LoadNetworkVideoMode = .download {
        didSet { PhotoManager.shared.loadNetworkVideoMode = loadNetworkVideoMode }
    }
    
    /// 背景颜色
    public var backgroundColor: UIColor = .white
    
    /// 暗黑风格下背景颜色
    public var backgroundDarkColor: UIColor = .black
    
    /// 选择框配置
    public var selectBox: SelectBoxConfiguration = .init()
    
    /// 视频播放类型
    public var videoPlayType: PhotoPreviewViewController.PlayType = .normal
    
    /// LivePhoto播放类型
    public var livePhotoPlayType: PhotoPreviewViewController.PlayType = .once
    
    /// 单击cell隐藏/显示导航栏时是否播放/暂停视频
    public var singleClickCellAutoPlayVideo: Bool = true
    
    /// 显示底部视图
    public var showBottomView: Bool = true
    
    /// 底部视图相关配置
    public var bottomView: PickerBottomViewConfiguration
    
    /// 取消按钮的配置只有当是外部预览时才有效，文字和图片颜色通过 navigationTintColor 设置
    /// 取消按钮类型
    public var cancelType: PhotoPickerViewController.CancelType = .text
    
    /// 取消按钮位置
    public var cancelPosition: PhotoPickerViewController.CancelPosition = .right
    
    /// 取消按钮图片名
    public var cancelImageName: String = "hx_picker_photolist_cancel"
    
    /// 暗黑模式下取消按钮图片名
    public var cancelDarkImageName: String = "hx_picker_photolist_cancel"
    
    public init() {
        PhotoManager.shared.loadNetworkVideoMode = loadNetworkVideoMode
        var bottomConfig = PickerBottomViewConfiguration.init()
        bottomConfig.previewButtonHidden = true
        bottomConfig.disableFinishButtonWhenNotSelected = false
        #if HXPICKER_ENABLE_EDITOR
        bottomConfig.editButtonHidden = false
        #endif
        bottomConfig.showSelectedView = true
        self.bottomView = bottomConfig
    }
}
