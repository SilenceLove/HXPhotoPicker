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
        previewConfig.adaptiveBarAppearance = false
        
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
        previewViewController?.navigationItem.titleView = titleLabel
        if showDelete {
            previewViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(
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
    
    fileprivate lazy var titleLabel: UILabel = {
        let titleLabel = UILabel.init()
        titleLabel.size = CGSize(width: 100, height: 30)
        titleLabel.textColor = .white
        titleLabel.font = UIFont.semiboldPingFang(ofSize: 17)
        titleLabel.textAlignment = .center
        return titleLabel
    }()
    
    fileprivate lazy var gradualShadowImageView: UIImageView = {
        let navHeight = navigationBar.height
        let view = UIImageView(
            image: UIImage.gradualShadowImage(
                CGSize(
                    width: view.width,
                    height: UIDevice.isAllIPhoneX ? navHeight + 60 : navHeight + 30
                )
            )
        )
        view.alpha = 0
        return view
    }()
    
    fileprivate var didHidden: Bool = false
    
    @objc func deletePreviewAsset() {
        guard let preview = previewViewController,
              !preview.previewAssets.isEmpty else {
            return
        }
        deleteAssetHandler?(
            preview.currentPreviewIndex,
            preview.previewAssets[preview.currentPreviewIndex],
            self
        )
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.insertSubview(gradualShadowImageView, belowSubview: navigationBar)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let imageHeight = UIDevice.isAllIPhoneX ? navigationBar.height + 54 : navigationBar.height + 30
        gradualShadowImageView.frame = CGRect(origin: .zero, size: CGSize(width: view.width, height: imageHeight))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PhotoBrowser: PhotoPickerControllerDelegate {
    public func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersWillAppear viewController: UIViewController
    ) {
        navigationBar
            .setBackgroundImage(
                UIImage.image(for: UIColor.clear, havingSize: .zero),
                for: .default
            )
    }
    public func pickerController(
        _ pickerController: PhotoPickerController,
        previewSingleClick photoAsset: PhotoAsset,
        atIndex: Int
    ) {
        if photoAsset.mediaType == .photo {
            pickerController.dismiss(animated: true, completion: nil)
        }else {
            didHidden = !didHidden
            UIView.animate(withDuration: 0.25) {
                self.gradualShadowImageView.alpha = self.didHidden ? 0 : 1
            } completion: { _ in
                self.gradualShadowImageView.alpha = self.didHidden ? 0 : 1
            }
        }
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        previewUpdateCurrentlyDisplayedAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) {
        guard let preview = previewViewController else {
            return
        }
        titleLabel.text = String(atIndex + 1) + "/" + String(preview.previewAssets.count)
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
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        animateTransition type: PickerTransitionType
    ) {
        gradualShadowImageView.alpha = type == .present ? 1 : 0
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        interPercentUpdate scale: CGFloat,
        type: PickerInteractiveTransitionType
    ) {
        if didHidden { return }
        gradualShadowImageView.alpha = scale
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        interPercentDidFinishAnimation type: PickerInteractiveTransitionType
    ) {
        gradualShadowImageView.alpha = 0
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        interPercentDidCancelAnimation type: PickerInteractiveTransitionType
    ) {
        if !didHidden {
            gradualShadowImageView.alpha = 1
        }
    }
}
