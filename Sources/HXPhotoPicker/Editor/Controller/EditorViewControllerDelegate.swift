//
//  EditorViewControllerDelegate.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/24.
//

import UIKit
import Photos

public protocol EditorViewControllerDelegate: AnyObject {
    
    /// 完成编辑
    /// - Parameters:
    ///   - editorViewController: 对应的`EditorViewController`
    ///   - asset: 当前编辑对象，asset.result 为空则没有编辑
    func editorViewController(
        _ editorViewController: EditorViewController,
        didFinish asset: EditorAsset
    )
    
    /// 取消编辑
    /// - Parameter editorViewController: 对应的`EditorViewController`
    func editorViewController(
        didCancel editorViewController: EditorViewController
    )
    
    /// 获取上一次图片滤镜
    /// - Parameters:
    ///   - editorViewController: 对应的`EditorViewController`
    ///   - info: 滤镜参数
    /// - Returns: 对应的滤镜效果
    func editorViewcOntroller(
        _ editorViewController: EditorViewController,
        fetchLastImageFilterInfo info: PhotoEditorFilter
    ) -> PhotoEditorFilterInfo?
    
    /// 获取上一次视频滤镜
    /// - Parameters:
    ///   - editorViewController: 对应的`EditorViewController`
    ///   - info: 滤镜参数
    /// - Returns: 对应的滤镜效果
    func editorViewcOntroller(
        _ editorViewController: EditorViewController,
        fetchLastVideoFilterInfo info: VideoEditorFilter
    ) -> PhotoEditorFilterInfo?
    
    /// 加载贴图标题资源
    /// - Parameters:
    ///   - editorViewController: 对应的`EditorViewController`
    ///   - loadTitleChartlet: 传入标题数组
    func editorViewController(
        _ editorViewController: EditorViewController,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse
    )
    
    /// 加载贴图资源
    /// - Parameters:
    ///   - editorViewController: 对应的`EditorViewController`
    ///   - titleChartlet: 对应配置的 title
    ///   - titleIndex: 对应配置的 title 的位置索引
    ///   - response: 传入 title索引 和 贴图数据
    func editorViewController(
        _ editorViewController: EditorViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping EditorChartletListResponse
    )
    
    /// 将要点击工具栏音乐按钮
    /// - Parameter editorViewController: 对应的`EditorViewController`
    func editorViewController(
        shouldClickMusicTool editorViewController: EditorViewController
    ) -> Bool
    
    /// 加载配乐信息，当music.infos为空时触发
    /// 返回 true 内部会显示加载状态，调用 completionHandler 后恢复
    /// - Parameters:
    ///   - editorViewController: 对应的`EditorViewController`
    ///   - completionHandler: 传入配乐信息
    func editorViewController(
        _ editorViewController: EditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void
    ) -> Bool
    
    /// 重置了配乐搜索（SearchText 为 nil 时 Return）
    /// - Parameter editorViewController: 对应的`EditorViewController`
    func editorViewController(
        didClearSearch editorViewController: EditorViewController
    )
    
    /// 搜索配乐信息
    /// - Parameters:
    ///   - editorViewController: 对应的`EditorViewController`
    ///   - text: 搜索的文字内容，为 nil 时则为列表加载
    ///   - completion: 传入配乐信息，是否需要加载更多
    func editorViewController(
        _ editorViewController: EditorViewController,
        didSearchMusic text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    )
    
    /// 加载更多配乐信息
    /// - Parameters:
    ///   - editorViewController: 对应的`EditorViewController` 
    ///   - text: 搜索的文字内容
    ///   - completion: 传入配乐信息，是否还有更多数据
    func editorViewController(
        _ editorViewController: EditorViewController,
        loadMoreMusic text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    )
    
    /*
    /// 完成编辑
    /// - Parameters:
    ///   - editorViewController: 对应的`EditorViewController`
    ///   - result: 编辑后的数据，未编辑数据为空
    func editorViewController(
        _ editorViewController: EditorViewController,
        didFinish results: [EditedResult]
    )
     */
    
    // MARK: 只支持 push/pop ，跳转之前需要 navigationController?.delegate = editorViewController
    /// 转场动画时长
    func editorViewController(
        _ editorViewController: EditorViewController,
        transitionDuration mode: EditorTransitionMode
    ) -> TimeInterval
    
    /// 转场过渡动画时展示的image
    /// - Parameters:
    ///   - photoEditorViewController: 对应的 PhotoEditorViewController
    func editorViewController(
        transitionPreviewImage editorViewController: EditorViewController
    ) -> UIImage?
    
    /// 跳转界面时起始的视图，用于获取位置大小。与 transitioBegenPreviewFrame 一样
    func editorViewController(
        transitioStartPreviewView editorViewController: EditorViewController
    ) -> UIView?
    
    /// 界面返回时对应的视图，用于获取位置大小。与 transitioEndPreviewFrame 一样
    func editorViewController(
        transitioEndPreviewView editorViewController: EditorViewController
    ) -> UIView?
    
    /// 跳转界面时对应的起始位置大小
    func editorViewController(
        transitioStartPreviewFrame editorViewController: EditorViewController
    ) -> CGRect?
    
    /// 界面返回时对应的位置大小
    func editorViewController(
        transitioEndPreviewFrame editorViewController: EditorViewController
    ) -> CGRect?
    
}
    
public extension EditorViewControllerDelegate {
    
    func editorViewController(
        _ editorViewController: EditorViewController,
        didFinish asset: EditorAsset
    ) {
        back(editorViewController)
    }
    
    /*
    func editorViewController(
        _ editorViewController: EditorViewController,
        didFinish results: [EditedResult]
    ) {
        back(editorViewController)
    }
     */
    
    func editorViewController(
        didCancel editorViewController: EditorViewController
    ) {
        back(editorViewController)
    }
    
    func editorViewcOntroller(
        _ editorViewController: EditorViewController,
        fetchLastImageFilterInfo info: PhotoEditorFilter
    ) -> PhotoEditorFilterInfo? {
        nil
    }
    
    func editorViewcOntroller(
        _ editorViewController: EditorViewController,
        fetchLastVideoFilterInfo info: VideoEditorFilter
    ) -> PhotoEditorFilterInfo? {
        nil
    }

    func editorViewController(
        _ editorViewController: EditorViewController,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse
    ) {
        let titles = PhotoTools.defaultTitleChartlet()
        response(titles)
    }
    
    func editorViewController(
        _ editorViewController: EditorViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping EditorChartletListResponse
    ) {
        /// 默认加载这些贴图
        let chartletList = PhotoTools.defaultNetworkChartlet()
        response(titleIndex, chartletList)
    }
    
    func editorViewController(
        shouldClickMusicTool editorViewController: EditorViewController
    ) -> Bool {
        true
    }
    
    func editorViewController(
        _ editorViewController: EditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void
    ) -> Bool {
        completionHandler(PhotoTools.defaultMusicInfos())
        return false
    }
    
    func editorViewController(
        didClearSearch editorViewController: EditorViewController
    ) { }
    
    func editorViewController(
        _ editorViewController: EditorViewController,
        didSearchMusic text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        completionHandler([], false)
    }
    
    func editorViewController(
        _ editorViewController: EditorViewController,
        loadMoreMusic text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        completionHandler([], false)
    }
    
    func editorViewController(
        _ editorViewController: EditorViewController,
        transitionDuration mode: EditorTransitionMode
    ) -> TimeInterval { 0.55 }
    
    func editorViewController(
        transitionPreviewImage editorViewController: EditorViewController
    ) -> UIImage? { nil }
    
    func editorViewController(
        transitioStartPreviewView editorViewController: EditorViewController
    ) -> UIView? { nil }
    
    func editorViewController(
        transitioEndPreviewView editorViewController: EditorViewController
    ) -> UIView? { nil }
    
    func editorViewController(
        transitioStartPreviewFrame editorViewController: EditorViewController
    ) -> CGRect? { nil }
    
    func editorViewController(
        transitioEndPreviewFrame editorViewController: EditorViewController
    ) -> CGRect? { nil }
    
    private func back(
        _ editorViewController: EditorViewController
    ) {
        if !editorViewController.config.isAutoBack {
            if let navigationController = editorViewController.navigationController,
               navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            }else {
                editorViewController.dismiss(animated: true)
            }
        }
    }
}
 
