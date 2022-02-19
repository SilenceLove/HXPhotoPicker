//
//  PhotoPickerControllerProtocol.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/9.
//

import UIKit
import Photos

public protocol PhotoPickerControllerDelegate: AnyObject {
    
    /// 选择完成之后调用
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - result: 选择的结果
    ///     result.photoAssets  选择的资源数组
    ///     result.isOriginal   是否选中原图
    func pickerController(
        _ pickerController: PhotoPickerController,
        didFinishSelection result: PickerResult
    )
    
    /// 点击取消时调用
    /// - Parameter pickerController: 对应的 PhotoPickerController
    func pickerController(
        didCancel pickerController: PhotoPickerController
    )
    
    /// 获取所有相册时调用
    /// - Parameter
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - collection: 对应的每个 PHAssetCollection 对象
    /// - Returns: 是否添加到列表显示
    func pickerController(
        _ pickerController: PhotoPickerController,
        didFetchAssetCollections collection: PHAssetCollection
    ) -> Bool
    
    /// 获取相册集合里的 PHAsset 时调用
    /// - Parameter
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - asset: 对应的每个 PHAsset 对象
    /// - Returns: 是否添加到列表显示
    func pickerController(
        _ pickerController: PhotoPickerController,
        didFetchAssets asset: PHAsset
    ) -> Bool
    
    /// 点击了原图按钮
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - isOriginal: 是否选中的原图
    func pickerController(
        _ pickerController: PhotoPickerController,
        didOriginalButton isOriginal: Bool
    )
    
    /// 将要点击cell，允许的话点击之后会根据配置的动作进行操作
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - photoAsset: 对应的 PhotoAsset 数据
    ///   - atIndex: indexPath.item
    func pickerController(
        _ pickerController: PhotoPickerController,
        shouldClickCell photoAsset: PhotoAsset,
        atIndex: Int
    ) -> Bool
    
    /// 将要选择cell 不能选择时需要自己手动弹出提示框
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - photoAsset: 对应的 PhotoAsset 数据
    ///   - atIndex: 将要添加的索引
    func pickerController(
        _ pickerController: PhotoPickerController,
        shouldSelectedAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) -> Bool

    /// 即将选择 cell 时调用
    func pickerController(
        _ pickerController: PhotoPickerController,
        willSelectAsset photoAsset: PhotoAsset,
        atIndex: Int
    )

    /// 选择了 cell 之后调用
    func pickerController(
        _ pickerController: PhotoPickerController,
        didSelectAsset photoAsset: PhotoAsset,
        atIndex: Int
    )

    /// 即将取消选择 cell
    func pickerController(
        _ pickerController: PhotoPickerController,
        willUnselectAsset photoAsset: PhotoAsset,
        atIndex: Int
    )

    /// 取消选择 cell
    func pickerController(
        _ pickerController: PhotoPickerController,
        didUnselectAsset photoAsset: PhotoAsset,
        atIndex: Int
    )
    
    /// 是否能够推出相机界面，点击相机cell时调用
    /// 可以跳转其他相机界面然后调用 addedCameraPhotoAsset
    func pickerController(
        shouldPresentCamera pickerController: PhotoPickerController
    ) -> Bool
    
    /// 将要编辑 Asset，不允许的话可以自己跳转其他编辑界面
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - photoAsset: 对应的 PhotoAsset 数据
    func pickerController(
        _ pickerController: PhotoPickerController,
        shouldEditAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) -> Bool
    
    #if HXPICKER_ENABLE_EDITOR
    
    /// 照片/视频编辑器加载贴图标题资源
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - editorViewController: 对应的 PhotoEditorViewController / VideoEditorViewController
    ///   - loadTitleChartlet: 传入标题数组
    func pickerController(
        _ pickerController: PhotoPickerController,
        loadTitleChartlet editorViewController: UIViewController,
        response: @escaping EditorTitleChartletResponse
    )
    
    /// 照片/视频编辑器加载贴图资源
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - editorViewController: 对应的 PhotoEditorViewController / VideoEditorViewController
    ///   - titleChartlet: 对应配置的 title
    ///   - titleIndex: 对应配置的 title 的位置索引
    ///   - response: 传入 title索引 和 贴图数据
    func pickerController(
        _ pickerController: PhotoPickerController,
        loadChartletList editorViewController: UIViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        response: @escaping EditorChartletListResponse
    )
    
    /// 视频编辑器，将要点击工具栏音乐按钮
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    func pickerController(
        _ pickerController: PhotoPickerController,
        videoEditorShouldClickMusicTool videoEditorViewController: VideoEditorViewController
    ) -> Bool
    
    /// 视频编辑器加载配乐信息，当music.infos为空时触发
    /// 返回 true 内部会显示加载状态，调用 completionHandler 后恢复
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - completionHandler: 传入配乐信息
    func pickerController(
        _ pickerController: PhotoPickerController,
        videoEditor videoEditorViewController: VideoEditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void
    ) -> Bool
    
    /// 视频编辑器搜索配乐信息
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - text: 搜索的文字内容
    ///   - completion: 传入配乐信息，是否需要加载更多
    func pickerController(
        _ pickerController: PhotoPickerController,
        videoEditor videoEditorViewController: VideoEditorViewController,
        didSearch text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    )
    
    /// 视频编辑器加载更多配乐信息
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - text: 搜索的文字内容
    ///   - completion: 传入配乐信息，是否还有更多数据
    func pickerController(
        _ pickerController: PhotoPickerController,
        videoEditor videoEditorViewController: VideoEditorViewController,
        loadMore text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    )
    #endif
    
    /// Asset 编辑完后调用
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - photoAsset: 对应的 PhotoAsset 数据
    ///   - atIndex: 对应的下标
    func pickerController(
        _ pickerController: PhotoPickerController,
        didEditAsset photoAsset: PhotoAsset,
        atIndex: Int
    )
    
    /// 预览界面更新当前显示的资源，collectionView滑动了就会调用
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - photoAsset: 对应显示的 PhotoAsset 数据
    ///   - index: 对应显示的位置
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewUpdateCurrentlyDisplayedAsset photoAsset: PhotoAsset,
        atIndex: Int
    )
    
    /// 预览界面单击操作
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - photoAsset: 对应显示的 PhotoAsset 数据
    ///   - atIndex: 对应显示的位置
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewSingleClick photoAsset: PhotoAsset,
        atIndex: Int
    )
    
    /// 预览界面长按操作
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - photoAsset: 对应显示的 PhotoAsset 数据
    ///   - atIndex: 对应显示的位置
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewLongPressClick photoAsset: PhotoAsset,
        atIndex: Int
    )
    
    /// 预览界面将要删除 Asset
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - photoAsset: 对应被删除的 PhotoAsset 数据
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewShouldDeleteAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) -> Bool
    
    /// 预览界面已经删除了 Asset
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - photoAsset: 对应被删除的 PhotoAsset 数据
    ///   - atIndex: 资源对应的位置索引
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewDidDeleteAsset photoAsset: PhotoAsset,
        atIndex: Int
    )
    
    #if canImport(Kingfisher)
    /// 预览界面网络图片下载成功
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewNetworkImageDownloadSuccess photoAsset: PhotoAsset,
        atIndex: Int
    )
    
    /// 预览界面网络图片下载失败
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewNetworkImageDownloadFailed photoAsset: PhotoAsset,
        atIndex: Int
    )
    #endif
    
    /// 视图控制器即将显示
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - viewController: 对应的控制器 [AlbumViewController, PhotoPickerViewController, PhotoPreviewViewController]
    func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersWillAppear viewController: UIViewController
    )
    
    /// 视图控制器已经显示
    func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersDidAppear viewController: UIViewController
    )
    
    /// 视图控制器即将消失
    func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersWillDisappear viewController: UIViewController
    )
    
    /// 视图控制器已经消失
    func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersDidDisappear viewController: UIViewController
    )
    
    /// dismiss后调用
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - localCameraAssetArray: 相机拍摄存在本地的 PhotoAsset 数据
    ///     可以在下次进入选择时赋值给localCameraAssetArray，列表则会显示
    func pickerController(
        _ pickerController: PhotoPickerController,
        didDismissComplete localCameraAssetArray: [PhotoAsset]
    )
    
    // MARK: 单独预览时的自定义转场动画
    /// present预览时展示的image
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - index: 预览资源对应的位置
    func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewImageForIndexAt index: Int
    ) -> UIImage?
    
    /// present 预览时起始的视图，用于获取位置大小。与 presentPreviewFrameForIndexAt 一样
    func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewViewForIndexAt index: Int
    ) -> UIView?
    
    /// dismiss 结束时对应的视图，用于获取位置大小。与 dismissPreviewFrameForIndexAt 一样
    func pickerController(
        _ pickerController: PhotoPickerController,
        dismissPreviewViewForIndexAt index: Int
    ) -> UIView?
    
    /// present 预览时对应的起始位置大小
    func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewFrameForIndexAt index: Int
    ) -> CGRect
    
    /// dismiss 结束时对应的位置大小
    func pickerController(
        _ pickerController: PhotoPickerController,
        dismissPreviewFrameForIndexAt index: Int
    ) -> CGRect
    
    /// 转场动画
    func pickerController(
        _ pickerController: PhotoPickerController,
        animateTransition type: PickerTransitionType
    )
    
    /// 手势返回的进度
    func pickerController(
        _ pickerController: PhotoPickerController,
        interPercentUpdate scale: CGFloat,
        type: PickerInteractiveTransitionType
    )
    
    /// 手势返回完成动画
    func pickerController(
        _ pickerController: PhotoPickerController,
        interPercentDidFinishAnimation type: PickerInteractiveTransitionType
    )
    
    /// 手势返回取消动画
    func pickerController(
        _ pickerController: PhotoPickerController,
        interPercentDidCancelAnimation type: PickerInteractiveTransitionType
    )
    
    /// 外部预览自定义 present 完成
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewPresentComplete atIndex: Int
    )
    
    /// 外部预览自定义 dismiss 完成
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewDismissComplete atIndex: Int
    )
}

public extension PhotoPickerControllerDelegate {
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        didFinishSelection result: PickerResult
    ) {
        if !pickerController.autoDismiss {
            pickerController.dismiss(animated: true)
        }
    }
    
    func pickerController(
        didCancel pickerController: PhotoPickerController
    ) {
        if !pickerController.autoDismiss {
            pickerController.dismiss(animated: true)
        }
    }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        didFetchAssetCollections collection: PHAssetCollection
    ) -> Bool { true }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        didFetchAssets asset: PHAsset
    ) -> Bool { true }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        didOriginalButton isOriginal: Bool
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        shouldClickCell photoAsset: PhotoAsset,
        atIndex: Int
    ) -> Bool { true }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        shouldSelectedAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) -> Bool { true }

    func pickerController(
        _ pickerController: PhotoPickerController,
        willSelectAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) { }

    func pickerController(
        _ pickerController: PhotoPickerController,
        didSelectAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) { }

    func pickerController(
        _ pickerController: PhotoPickerController,
        willUnselectAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) { }

    func pickerController(
        _ pickerController: PhotoPickerController,
        didUnselectAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) { }
    
    func pickerController(
        shouldPresentCamera pickerController: PhotoPickerController
    ) -> Bool { true }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        shouldEditAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) -> Bool { true }
    
    #if HXPICKER_ENABLE_EDITOR
    func pickerController(
        _ pickerController: PhotoPickerController,
        loadTitleChartlet editorViewController: UIViewController,
        response: @escaping EditorTitleChartletResponse
    ) {
        #if canImport(Kingfisher)
        let titles = PhotoTools.defaultTitleChartlet()
        response(titles)
        #else
        response([])
        #endif
    }
    func pickerController(
        _ pickerController: PhotoPickerController,
        loadChartletList editorViewController: UIViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        response: @escaping EditorChartletListResponse
    ) {
        /// 默认加载这些贴图
        #if canImport(Kingfisher)
        let chartletList = PhotoTools.defaultNetworkChartlet()
        response(titleIndex, chartletList)
        #else
        response(titleIndex, [])
        #endif
    }
    func pickerController(
        _ pickerController: PhotoPickerController,
        videoEditorShouldClickMusicTool
            videoEditorViewController: VideoEditorViewController
    ) -> Bool { true }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        videoEditor videoEditorViewController: VideoEditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void
    ) -> Bool {
        completionHandler(PhotoTools.defaultMusicInfos())
        return false
    }
    func pickerController(
        _ pickerController: PhotoPickerController,
        videoEditor videoEditorViewController: VideoEditorViewController,
        didSearch text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        completionHandler([], false)
    }
    func pickerController(
        _ pickerController: PhotoPickerController,
        videoEditor videoEditorViewController: VideoEditorViewController,
        loadMore text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        completionHandler([], false)
    }
    #endif
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        didEditAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewUpdateCurrentlyDisplayedAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewSingleClick photoAsset: PhotoAsset,
        atIndex: Int
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewLongPressClick photoAsset: PhotoAsset,
        atIndex: Int
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewShouldDeleteAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) -> Bool { true }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewDidDeleteAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) { }
    
    #if canImport(Kingfisher)
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewNetworkImageDownloadSuccess photoAsset: PhotoAsset,
        atIndex: Int
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewNetworkImageDownloadFailed photoAsset: PhotoAsset,
        atIndex: Int
    ) { }
    #endif
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersWillAppear viewController: UIViewController
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersDidAppear viewController: UIViewController
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersWillDisappear viewController: UIViewController
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersDidDisappear viewController: UIViewController
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        didDismissComplete localCameraAssetArray: [PhotoAsset]
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewImageForIndexAt index: Int
    ) -> UIImage? { nil }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewViewForIndexAt index: Int
    ) -> UIView? { nil }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        dismissPreviewViewForIndexAt index: Int
    ) -> UIView? { nil }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewFrameForIndexAt index: Int
    ) -> CGRect { .zero }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        dismissPreviewFrameForIndexAt index: Int
    ) -> CGRect { .zero }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        animateTransition type: PickerTransitionType
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        interPercentDidFinishAnimation type: PickerInteractiveTransitionType
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        interPercentDidCancelAnimation type: PickerInteractiveTransitionType
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        interPercentUpdate scale: CGFloat,
        type: PickerInteractiveTransitionType
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewPresentComplete atIndex: Int
    ) { }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewDismissComplete atIndex: Int
    ) { }
}
