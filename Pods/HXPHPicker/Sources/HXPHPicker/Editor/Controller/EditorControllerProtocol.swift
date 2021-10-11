//
//  EditorControllerProtocol.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/1.
//

import UIKit
import Photos
#if canImport(Kingfisher)
import Kingfisher
#endif

public protocol PhotoEditorViewControllerDelegate: AnyObject {
    
    /// 编辑完成
    /// - Parameters:
    ///   - photoEditorViewController: 对应的 PhotoEditorViewController
    ///   - result: 编辑后的数据
    func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        didFinish result: PhotoEditResult
    )
    
    /// 点击完成按钮，但是照片未编辑
    /// - Parameters:
    ///   - photoEditorViewController: 对应的 PhotoEditorViewController
    func photoEditorViewController(
        didFinishWithUnedited photoEditorViewController: PhotoEditorViewController
    )
    
    /// 加载贴图标题资源
    /// - Parameters:
    ///   - photoEditorViewController: 对应的 PhotoEditorViewController
    ///   - loadTitleChartlet: 传入标题数组
    func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse
    )
    /// 加载贴图资源
    /// - Parameters:
    ///   - photoEditorViewController: 对应的 PhotoEditorViewController
    ///   - titleChartlet: 对应配置的 title
    ///   - titleIndex: 对应配置的 title 的位置索引
    ///   - response: 传入 title索引 和 贴图数据
    func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping EditorChartletListResponse
    )
    
    /// 取消编辑
    /// - Parameter photoEditorViewController: 对应的 PhotoEditorViewController
    func photoEditorViewController(
        didCancel photoEditorViewController: PhotoEditorViewController
    )
}
public extension PhotoEditorViewControllerDelegate {
    func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        didFinish result: PhotoEditResult
    ) {
        back(photoEditorViewController)
    }
    func photoEditorViewController(
        didFinishWithUnedited photoEditorViewController: PhotoEditorViewController
    ) {
        back(photoEditorViewController)
    }
    func photoEditorViewController(
        didCancel photoEditorViewController: PhotoEditorViewController
    ) {
        back(photoEditorViewController)
    }
    func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse
    ) {
        #if canImport(Kingfisher)
        let titles = PhotoTools.defaultTitleChartlet()
        response(titles)
        #else
        response([])
        #endif
    }
    func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping EditorChartletListResponse
    ) {
        /// 默认加载这些贴图
        #if canImport(Kingfisher)
        let chartletList = PhotoTools.defaultNetworkChartlet()
        response(titleIndex, chartletList)
        #else
        response(titleIndex, [])
        #endif
    }
    
    private func back(
        _ photoEditorViewController: PhotoEditorViewController
    ) {
        if !photoEditorViewController.autoBack {
            if let navigationController = photoEditorViewController.navigationController,
               navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            }else {
                photoEditorViewController.dismiss(animated: true)
            }
        }
    }
}

public protocol VideoEditorViewControllerDelegate: AnyObject {
    
    /// 编辑完成
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - result: 编辑后的数据
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        didFinish result: VideoEditResult
    )
    
    /// 点击完成按钮，但是视频未编辑
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    func videoEditorViewController(
        didFinishWithUnedited videoEditorViewController: VideoEditorViewController
    )
    
    /// 加载贴图标题资源
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - loadTitleChartlet: 传入标题数组
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse
    )
    
    /// 加载贴图资源
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - titleChartlet: 对应配置的 title
    ///   - titleIndex: 对应配置的 title 的位置索引
    ///   - response: 传入 title索引 和 贴图数据
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping EditorChartletListResponse
    )
    
    /// 将要点击工具栏音乐按钮
    /// - Parameter videoEditorViewController: 对应的 VideoEditorViewController
    func videoEditorViewController(
        shouldClickMusicTool videoEditorViewController: VideoEditorViewController
    ) -> Bool
    
    /// 加载配乐信息，当musicConfig.infos为空时触发
    /// 返回 true 内部会显示加载状态，调用 completionHandler 后恢复
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - completionHandler: 传入配乐信息
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void
    ) -> Bool
    
    /// 搜索配乐信息
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - text: 搜索的文字内容
    ///   - completion: 传入配乐信息，是否需要加载更多
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        didSearch text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    )
    
    /// 加载更多配乐信息
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - text: 搜索的文字内容
    ///   - completion: 传入配乐信息，是否还有更多数据
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadMore text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    )
    
    /// 取消编辑
    /// - Parameter videoEditorViewController: 对应的 VideoEditorViewController
    func videoEditorViewController(
        didCancel videoEditorViewController: VideoEditorViewController
    )
}

public extension VideoEditorViewControllerDelegate {
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        didFinish result: VideoEditResult
    ) {
        back(videoEditorViewController)
    }
    func videoEditorViewController(
        didFinishWithUnedited videoEditorViewController: VideoEditorViewController
    ) {
        back(videoEditorViewController)
    }
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse
    ) {
        #if canImport(Kingfisher)
        let titles = PhotoTools.defaultTitleChartlet()
        response(titles)
        #else
        response([])
        #endif
    }
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping EditorChartletListResponse
    ) {
        /// 默认加载这些贴图
        #if canImport(Kingfisher)
        let chartletList = PhotoTools.defaultNetworkChartlet()
        response(titleIndex, chartletList)
        #else
        response(titleIndex, [])
        #endif
    }
    
    func videoEditorViewController(
        shouldClickMusicTool videoEditorViewController: VideoEditorViewController
    ) -> Bool { true }
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void
    ) -> Bool {
        completionHandler(PhotoTools.defaultMusicInfos())
        return false
    }
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        didSearch text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool
        ) -> Void) {
        completionHandler([], false)
    }
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadMore text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        completionHandler([], false)
    }
    func videoEditorViewController(
        didCancel videoEditorViewController: VideoEditorViewController
    ) {
        back(videoEditorViewController)
    }
    
    private func back(
        _ videoEditorViewController: VideoEditorViewController) {
        if !videoEditorViewController.autoBack {
            if let navigationController = videoEditorViewController.navigationController,
               navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            }else {
                videoEditorViewController.dismiss(animated: true)
            }
        }
    }
}
