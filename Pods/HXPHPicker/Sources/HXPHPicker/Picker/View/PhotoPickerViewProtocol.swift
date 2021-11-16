//
//  PhotoPickerViewProtocol.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/18.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

public protocol PhotoPickerViewDelegate: AnyObject {
    
    /// 选择完成之后调用
    /// - Parameters:
    ///   - photoPickerView: 对应的 PhotoPickerView
    ///   - result: 选择的结果
    ///     result.photoAssets  选择的资源数组
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        didFinishSelection result: PickerResult
    )
    
    /// 选择完成之后调用，如果是在预览界面点击完成。则会在dismiss完成之后触发
    /// - Parameters:
    ///   - photoPickerView: 对应的 PhotoPickerView
    ///   - result: 选择的结果
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        dismissCompletion result: PickerResult
    )
    
    /// 开始拖动手势
    /// - Parameters:
    ///   - photoPickerView: 对应的 PhotoPickerView
    ///   - gestureRecognizer: 拖动手势识别器
    ///   - photoAsset: 对应的 PhotoAsset 对象
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        gestureRecognizer: UIPanGestureRecognizer,
        beginDrag photoAsset: PhotoAsset,
        dragView: UIView
    )
    
    /// 拖动手势改变中
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        gestureRecognizer: UIPanGestureRecognizer,
        changeDrag photoAsset: PhotoAsset
    )
    
    /// 拖动手势已经结束
    /// return 拖拽的视图是否需要返回动画
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        gestureRecognizer: UIPanGestureRecognizer,
        endDrag photoAsset: PhotoAsset
    ) -> Bool
    
    /// 即将选择 cell 时调用
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        willSelectAsset photoAsset: PhotoAsset,
        at index: Int
    )

    /// 选择了 cell 之后调用
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        didSelectAsset photoAsset: PhotoAsset,
        at index: Int
    )

    /// 即将取消选择 cell
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        willDeselectAsset photoAsset: PhotoAsset,
        at index: Int
    )

    /// 取消选择 cell
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        didDeselectAsset photoAsset: PhotoAsset,
        at index: Int
    )
    
    /// 预览界面点击了原图按钮
    /// - Parameters:
    ///   - photoPickerView: 对应的 PhotoPickerView
    ///   - isSelected: 是否选中
    /// 获取原图大小的方法：manager.requestSelectedAssetFileSize(completion: <#T##(Int, String) -> Void#>)
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        previewDidOriginalButton isSelected: Bool
    )
    
    #if HXPICKER_ENABLE_EDITOR
    /// 照片/视频编辑器加载贴图标题资源
    /// - Parameters:
    ///   - photoPickerView: 对应的 PhotoPickerView
    ///   - editorViewController: 对应的 PhotoEditorViewController / VideoEditorViewController
    ///   - loadTitleChartlet: 传入标题数组
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        loadTitleChartlet editorViewController: UIViewController,
        response: @escaping EditorTitleChartletResponse
    )
    
    /// 照片/视频编辑器加载贴图资源
    /// - Parameters:
    ///   - photoPickerView: 对应的 PhotoPickerView
    ///   - editorViewController: 对应的 PhotoEditorViewController / VideoEditorViewController
    ///   - titleChartlet: 对应配置的 title
    ///   - titleIndex: 对应配置的 title 的位置索引
    ///   - response: 传入 title索引 和 贴图数据
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        loadChartletList editorViewController: UIViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        response: @escaping EditorChartletListResponse
    )
    
    /// 视频编辑器，将要点击工具栏音乐按钮
    /// - Parameters:
    ///   - photoPickerView: 对应的 PhotoPickerView
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        videoEditorShouldClickMusicTool videoEditorViewController: VideoEditorViewController
    ) -> Bool
    
    /// 视频编辑器加载配乐信息，当music.infos为空时触发
    /// 返回 true 内部会显示加载状态，调用 completionHandler 后恢复
    /// - Parameters:
    ///   - photoPickerView: 对应的 PhotoPickerView
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - completionHandler: 传入配乐信息
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        videoEditor videoEditorViewController: VideoEditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void
    ) -> Bool
    
    /// 视频编辑器搜索配乐信息
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - text: 搜索的文字内容
    ///   - completion: 传入配乐信息，是否需要加载更多
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        videoEditor videoEditorViewController: VideoEditorViewController,
        didSearch text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    )
    
    /// 视频编辑器加载更多配乐信息
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - text: 搜索的文字内容
    ///   - completion: 传入配乐信息，是否还有更多数据
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        videoEditor videoEditorViewController: VideoEditorViewController,
        loadMore text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    )
    #endif
}

public extension PhotoPickerViewDelegate {
    
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        didFinishSelection result: PickerResult
    ) { }
    
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        dismissCompletion result: PickerResult
    ) { }
    
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        gestureRecognizer: UIPanGestureRecognizer,
        beginDrag photoAsset: PhotoAsset,
        dragView: UIView
    ) { }
    
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        gestureRecognizer: UIPanGestureRecognizer,
        changeDrag photoAsset: PhotoAsset
    ) { }
    
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        gestureRecognizer: UIPanGestureRecognizer,
        endDrag photoAsset: PhotoAsset
    ) -> Bool { true }
    
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        willSelectAsset photoAsset: PhotoAsset,
        at index: Int
    ) { }

    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        didSelectAsset photoAsset: PhotoAsset,
        at index: Int
    ) { }

    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        willDeselectAsset photoAsset: PhotoAsset,
        at index: Int
    ) { }

    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        didDeselectAsset photoAsset: PhotoAsset,
        at index: Int
    ) { }
    
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        previewDidOriginalButton isSelected: Bool
    ) { }
    
    #if HXPICKER_ENABLE_EDITOR
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
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
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
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
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        videoEditorShouldClickMusicTool
            videoEditorViewController: VideoEditorViewController
    ) -> Bool { true }
    
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        videoEditor videoEditorViewController: VideoEditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void
    ) -> Bool {
        completionHandler(PhotoTools.defaultMusicInfos())
        return false
    }
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        videoEditor videoEditorViewController: VideoEditorViewController,
        didSearch text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        completionHandler([], false)
    }
    func photoPickerView(
        _ photoPickerView: PhotoPickerView,
        videoEditor videoEditorViewController: VideoEditorViewController,
        loadMore text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        completionHandler([], false)
    }
    #endif
}
