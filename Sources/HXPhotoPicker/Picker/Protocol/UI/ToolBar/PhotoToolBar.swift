//
//  PhotoToolBar.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/15.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit

public enum PhotoToolBarType {
    
    /// 照片列表
    case picker
    
    /// 预览界面
    case preview
    
    /// 照片浏览器，如果没有使用可忽略
    case browser
}

/// 具体实现可参考`PhotoToolbarView`
public protocol PhotoToolBar: UIView {
    
    init(_ config: PickerConfiguration, type: PhotoToolBarType)
    
    /// toolbar（预览、原图、完成按钮这一栏）的高度
    func toolbarHeight() -> CGFloat
    
    /// 视图整体高度
    func viewHeight() -> CGFloat
    
    /// 预览事件
    var previewHandler: (() -> Void)? { get set }
    
    /// 原图事件
    var originalHandler: ((Bool) -> Void)? { get set }
    
    #if HXPICKER_ENABLE_EDITOR
    /// 编辑事件
    var editHandler: (() -> Void)? { get set }
    
    /// 更新编辑按钮的状态
    func updateEditState(_ isEnabled: Bool)
    #endif
    
    /// 完成事件
    var finishHandler: (() -> Void)? { get set }
    
    /// 更新原图选中状态
    func updateOriginalState(_ isSelected: Bool)
    
    /// 内部主动请求原图大小
    /// ```
    /// if !originalButton.isSelected {
    ///     return
    /// }
    /// if 是否显示loading {
    ///     startOriginalLoading()
    /// }
    /// originalHandler?(true)
    /// /// 然后在 originalAssetBytes(_ bytes: Int, bytesString: String) 的回调里更新原图按钮
    /// ```
    func requestOriginalAssetBtyes()
    
    /// 请求原图大小的结果回调
    func originalAssetBytes(_ bytes: Int, bytesString: String)
    
    /// 选中的资源发生改变，主要用于更新 预览/完成按钮的数量/状态
    func selectedAssetDidChanged(_ photoAssets: [PhotoAsset])
    
    /// 选中照片的预览视图选中Asset
    var selectedAssetHandler: ((PhotoAsset) -> Void)? { get set }
    
    /// 选中照片的预览视图移动Asset (fromIndex, toIndex)
    var moveAssetHandler: ((Int, Int) -> Void)? { get set }
    
    /// 选中照片的预览视图添加 `PhotoAsset` 对象
    func insertSelectedAsset(_ photoAsset: PhotoAsset)
    
    /// 选中照片的预览视图移除`PhotoAsset` 对象
    func removeSelectedAssets(_ photoAssets: [PhotoAsset])
    
    /// 选中照片的预览视图更新`PhotoAsset` 对象
    func updateSelectedAssets(_ photoAssets: [PhotoAsset])
    
    /// 选中照片的预览视图刷新`PhotoAsset` 对象
    func reloadSelectedAsset(_ photoAsset: PhotoAsset)
    
    /// 选中照片的预览视图滚动到指定 `PhotoAsset` 对象
    func selectedViewScrollTo(_ photoAsset: PhotoAsset?, animated: Bool)
    
    /// 屏幕旋转之后的回调
    func deviceOrientationDidChanged()
}

public extension PhotoToolBar {
    
    var previewHandler: (() -> Void)? { get { nil } set { } }
    
    var originalHandler: ((Bool) -> Void)? { get { nil } set { } }
    
    #if HXPICKER_ENABLE_EDITOR
    var editHandler: (() -> Void)? { get { nil } set { } }
    
    func updateEditState(_ isEnabled: Bool) { }
    #endif
    
    var finishHandler: (() -> Void)? { get { nil } set { } }
    
    func updateOriginalState(_ isSelected: Bool) { }
    
    func requestOriginalAssetBtyes() { }
    
    func originalAssetBytes(_ bytes: Int, bytesString: String) { }
    
    func selectedAssetDidChanged(_ photoAssets: [PhotoAsset]) { }
    
    var selectedAssetHandler: ((PhotoAsset) -> Void)? { get { nil } set { } }
    
    var moveAssetHandler: ((Int, Int) -> Void)? { get { nil } set { } }
    
    func insertSelectedAsset(_ photoAsset: PhotoAsset) { }
    
    func removeSelectedAssets(_ photoAssets: [PhotoAsset]) { }
    
    func reloadSelectedAsset(_ photoAsset: PhotoAsset) { }
    
    func updateSelectedAssets(_ photoAssets: [PhotoAsset]) { }
    
    func selectedViewScrollTo(_ photoAsset: PhotoAsset?, animated: Bool) { }
    
    func deviceOrientationDidChanged() { }
}
