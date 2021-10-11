//
//  PhotoBrowser.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit

open class PhotoBrowser: PhotoPickerController {
    
    public struct Configuration {
        /// 导航栏 标题、删除、取消 按钮颜色
        public var tintColor: UIColor = .white
        /// 网络视频加载方式
        public var loadNetworkVideoMode: PhotoAsset.LoadNetworkVideoMode = .play
        /// 自定义视频Cell，默认带有滑动条
        public var customVideoCellClass: PreviewVideoViewCell.Type? = PreviewVideoControlViewCell.self
        /// 视频播放类型
        public var videoPlayType: PhotoPreviewViewController.PlayType = .normal
        /// LivePhoto播放类型
        public var livePhotoPlayType: PhotoPreviewViewController.PlayType = .once
        /// 背景颜色
        public var backgroundColor: UIColor = .black
        /// 显示删除按钮
        public var showDelete: Bool = false
        /// 跳转样式
        public var modalPresentationStyle: UIModalPresentationStyle = .custom
        
        public init() { }
    }
    
    /// 显示图片浏览器
    /// - Parameters:
    ///   - previewAssets: 对应 PhotoAsset 的数组
    ///   - pageIndex: 当前预览的位置
    ///   - config: 相关配置
    ///   - fromVC: 来源控制器
    ///   - transitionalImage: 初始转场动画时展示的 UIImage
    ///   - transitionHandler: 转场过渡
    ///   - deleteAssetHandler: 删除资源
    ///   - longPressHandler: 长按事件
    /// - Returns: 对应的 PhotoBrowser
    @discardableResult
    public class func show(
        _ previewAssets: [PhotoAsset],
        pageIndex: Int = 0,
        config: Configuration? = nil,
        fromVC: UIViewController? = nil,
        transitionalImage: UIImage? = nil,
        transitionHandler: TransitionHandler? = nil,
        deleteAssetHandler: AssetHandler? = nil,
        longPressHandler: AssetHandler? = nil
    ) -> PhotoBrowser {
        let previewConfig = PickerConfiguration()
        previewConfig.prefersStatusBarHidden = true
        previewConfig.statusBarStyle = .lightContent
        
        var pConfig = PreviewViewConfiguration()
        pConfig.singleClickCellAutoPlayVideo = false
        pConfig.showBottomView = false
        pConfig.cancelType = .image
        pConfig.cancelPosition = .left
        
        let browserConfig: Configuration = config ?? .init()
        pConfig.loadNetworkVideoMode = browserConfig.loadNetworkVideoMode
        pConfig.customVideoCellClass = browserConfig.customVideoCellClass
        pConfig.backgroundColor = browserConfig.backgroundColor
        pConfig.livePhotoPlayType = browserConfig.livePhotoPlayType
        pConfig.videoPlayType = browserConfig.videoPlayType
        
        previewConfig.previewView = pConfig
        previewConfig.navigationTintColor = browserConfig.tintColor
        let browser = PhotoBrowser(
            config: previewConfig,
            style: browserConfig.modalPresentationStyle,
            showDelete: browserConfig.showDelete,
            previewIndex: pageIndex,
            transitionalImage: transitionalImage,
            transitionHandler: transitionHandler,
            deleteAssetHandler: deleteAssetHandler,
            longPressHandler: longPressHandler
        )
        browser.selectedAssetArray = previewAssets
        browser.titleLabel.textColor = browserConfig.tintColor
        browser.titleLabel.text = String(pageIndex + 1) + "/" + String(previewAssets.count)
        (fromVC ?? UIViewController.topViewController)?.present(browser, animated: true, completion: nil)
        return browser
    }
    
    private init(
        config: PickerConfiguration,
        style: UIModalPresentationStyle,
        showDelete: Bool,
        previewIndex: Int,
        transitionalImage: UIImage?,
        transitionHandler: TransitionHandler?,
        deleteAssetHandler: AssetHandler?,
        longPressHandler: AssetHandler?
    ) {
        self.transitionalImage = transitionalImage
        self.transitionHandler = transitionHandler
        self.deleteAssetHandler = deleteAssetHandler
        self.longPressHandler = longPressHandler
        super.init(
            preview: config,
            currentIndex: previewIndex,
            modalPresentationStyle: style
        )
        pickerDelegate = self
        navigationBar.shadowImage = UIImage.image(
            for: UIColor.clear,
            havingSize: .zero
        )
        navigationBar.barTintColor = .clear
        navigationBar.backgroundColor = .clear
        previewViewController()?.navigationItem.titleView = titleLabel
        if showDelete {
            previewViewController()?.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "删除".localized,
                style: .done,
                target: self,
                action: #selector(deletePreviewAsset)
            )
        }
    }
    
    public typealias TransitionHandler = (Int) -> UIView?
    public typealias AssetHandler = (Int, PhotoAsset, PhotoBrowser) -> Void
    
    private let transitionHandler: TransitionHandler?
    private let deleteAssetHandler: AssetHandler?
    private let longPressHandler: AssetHandler?
    private let transitionalImage: UIImage?
    
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel.init()
        titleLabel.size = CGSize(width: 100, height: 30)
        titleLabel.textColor = .white
        titleLabel.font = UIFont.semiboldPingFang(ofSize: 17)
        titleLabel.textAlignment = .center
        return titleLabel
    }()
    
    @objc func deletePreviewAsset() {
        guard let preview = previewViewController(),
              !preview.previewAssets.isEmpty else {
            return
        }
        deleteAssetHandler?(
            preview.currentPreviewIndex,
            preview.previewAssets[preview.currentPreviewIndex],
            self
        )
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PhotoBrowser: PhotoPickerControllerDelegate {
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        previewSingleClick photoAsset: PhotoAsset,
        atIndex: Int
    ) {
        if photoAsset.mediaType == .photo {
            pickerController.dismiss(animated: true, completion: nil)
        }
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        previewUpdateCurrentlyDisplayedAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) {
        if let preview = previewViewController() {
            titleLabel.text = String(atIndex + 1) + "/" + String(preview.previewAssets.count)
        }
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersWillAppear viewController: UIViewController
    ) {
        let navHeight = viewController.navigationController?.navigationBar.height ?? 0
        viewController.navigationController?.navigationBar.setBackgroundImage(
            UIImage.gradualShadowImage(
                CGSize(
                    width: pickerController.view.width,
                    height: UIDevice.isAllIPhoneX ? navHeight + 54 : navHeight + 30
                )
            ),
            for: .default
        )
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        previewLongPressClick photoAsset: PhotoAsset,
        atIndex: Int
    ) {
        longPressHandler?(atIndex, photoAsset, self)
    }
    
    // MARK: 单独预览时的自定义转场动画
    /// present预览时展示的image
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - index: 预览资源对应的位置
    public func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewImageForIndexAt index: Int
    ) -> UIImage? {
        transitionalImage
    }
    
    /// present 预览时起始的视图，用于获取位置大小。与 presentPreviewFrameForIndexAt 一样
    public func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewViewForIndexAt index: Int
    ) -> UIView? {
        transitionHandler?(index)
    }
    
    /// dismiss 结束时对应的视图，用于获取位置大小。与 dismissPreviewFrameForIndexAt 一样
    public func pickerController(
        _ pickerController: PhotoPickerController,
        dismissPreviewViewForIndexAt index: Int
    ) -> UIView? {
        transitionHandler?(index)
    }
}
