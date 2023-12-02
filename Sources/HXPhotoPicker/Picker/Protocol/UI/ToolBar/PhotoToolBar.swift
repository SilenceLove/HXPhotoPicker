//
//  PhotoToolBar.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/15.
//  Copyright © 2023 Silence. All rights reserved.
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

public protocol PhotoToolBarDelegate: AnyObject {
    func photoToolbar(didPreviewClick toolbar: PhotoToolBar)
    func photoToolbar(_ toolbar: PhotoToolBar, didOriginalClick isSelected: Bool)
    
    #if HXPICKER_ENABLE_EDITOR
    func photoToolbar(didEditClick toolbar: PhotoToolBar)
    #endif
    
    func photoToolbar(didFinishClick toolbar: PhotoToolBar)
    
    func photoToolbar(_ toolbar: PhotoToolBar, didSelectedAsset asset: PhotoAsset)
    func photoToolbar(_ toolbar: PhotoToolBar, didMoveAsset fromIndex: Int, with toIndex: Int)
    func photoToolbar(_ toolbar: PhotoToolBar, didDeleteAsset asset: PhotoAsset)
    func photoToolbar(_ toolbar: PhotoToolBar, previewMoveTo asset: PhotoAsset)
}

public extension PhotoToolBarDelegate {
    func photoToolbar(didPreviewClick toolbar: PhotoToolBar) { }
    #if HXPICKER_ENABLE_EDITOR
    func photoToolbar(didEditClick toolbar: PhotoToolBar) { }
    #endif
    func photoToolbar(_ toolbar: PhotoToolBar, didSelectedAsset asset: PhotoAsset) { }
    func photoToolbar(_ toolbar: PhotoToolBar, didMoveAsset fromIndex: Int, with toIndex: Int) { }
    func photoToolbar(_ toolbar: PhotoToolBar, didDeleteAsset asset: PhotoAsset) { }
    func photoToolbar(_ toolbar: PhotoToolBar, previewMoveTo asset: PhotoAsset) { }
}

/// 具体实现可参考`PhotoToolbarView`
public protocol PhotoToolBar: UIView, PhotoPickerDataStatus {
    
    /// 是否显示toolbar
    static func isShow(_ config: PickerConfiguration,  type: PhotoToolBarType) -> Bool
    
    var toolbarDelegate: PhotoToolBarDelegate? { get set }
    
    /// toolbar（预览、原图、完成按钮这一栏）的高度
    var toolbarHeight: CGFloat { get }
    
    /// 视图整体高度
    var viewHeight: CGFloat { get }
    
    var selectViewOffset: CGPoint? { get set }
    
    init(_ config: PickerConfiguration, type: PhotoToolBarType)
    
    #if HXPICKER_ENABLE_EDITOR
    /// 更新编辑按钮的状态
    func updateEditState(_ isEnabled: Bool)
    #endif
    
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
    /// toolbarDelegate?.photoToolbar(self, didOriginalClick: true)
    /// /// 然后在 originalAssetBytes(_ bytes: Int, bytesString: String) 的回调里更新原图按钮
    /// ```
    func requestOriginalAssetBtyes()
    
    /// 请求原图大小的结果回调
    func originalAssetBytes(_ bytes: Int, bytesString: String)
    
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
    
    func configPreviewList(_ assets: [PhotoAsset], page: Int)
    
    func previewListInsert(_ asset: PhotoAsset, at index: Int)
    
    func previewListRemove(_ assets: [PhotoAsset])
    
    func previewListReload(_ assets: [PhotoAsset])
    
    func previewListDidScroll(_ scrollView: UIScrollView)
    
    /// 屏幕旋转后的回调
    func deviceOrientationDidChanged()
    
    func viewWillAppear(_ viewController: UIViewController)
    func viewDidAppear(_ viewController: UIViewController)
    func viewWillDisappear(_ viewController: UIViewController)
    func viewDidDisappear(_ viewController: UIViewController)
}

public extension PhotoToolBar {
    
    static func isShow(_ config: PickerConfiguration,  type: PhotoToolBarType) -> Bool {
        if type == .picker, config.selectMode == .single {
            return config.photoList.bottomView.isShowPrompt &&
                   config.allowLoadPhotoLibrary &&
                   AssetManager.authorizationStatusIsLimited()
        }
        return true
    }
    
    var selectViewOffset: CGPoint? { get { nil } set { } }
    
    #if HXPICKER_ENABLE_EDITOR
    func updateEditState(_ isEnabled: Bool) { }
    #endif
    
    func updateOriginalState(_ isSelected: Bool) { }
    
    func requestOriginalAssetBtyes() { }
    
    func originalAssetBytes(_ bytes: Int, bytesString: String) { }
    
    func selectedAssetDidChanged(_ photoAssets: [PhotoAsset]) { }
    
    func insertSelectedAsset(_ photoAsset: PhotoAsset) { }
    
    func removeSelectedAssets(_ photoAssets: [PhotoAsset]) { }
    
    func reloadSelectedAsset(_ photoAsset: PhotoAsset) { }
    
    func updateSelectedAssets(_ photoAssets: [PhotoAsset]) { }
    
    func selectedViewScrollTo(_ photoAsset: PhotoAsset?, animated: Bool) { }
    
    func configPreviewList(_ assets: [PhotoAsset], page: Int) { }
    
    func previewListInsert(_ asset: PhotoAsset, at index: Int) { }
    
    func previewListRemove(_ assets: [PhotoAsset]) { }
    
    func previewListReload(_ assets: [PhotoAsset]) { }
    
    func previewListDidScroll(_ scrollView: UIScrollView) { }
    
    func deviceOrientationDidChanged() { }
    
    func viewWillAppear(_ viewController: UIViewController) { }
    func viewDidAppear(_ viewController: UIViewController) { }
    func viewWillDisappear(_ viewController: UIViewController) { }
    func viewDidDisappear(_ viewController: UIViewController) { }
}
