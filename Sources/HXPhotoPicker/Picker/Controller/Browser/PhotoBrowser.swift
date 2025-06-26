//
//  PhotoBrowser.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit

open class PhotoBrowser: PhotoPickerController {
    
    public var collectionView: UICollectionView {
        previewViewController!.collectionView
    }
    
    /// 当前页面
    public var pageIndex: Int {
        get { currentPreviewIndex }
        set { setPageIndex(newValue, animated: false) }
    }
    
    public func setPageIndex(_ page: Int, animated: Bool) {
        previewViewController?.scrollToItem(page, animated: animated)
    }
    
    /// 页面数
    public var pageCount: Int {
        if previewAssets.isEmpty {
            if let pages = numberOfPages?() {
                return pages
            }
            return 0
        }else {
            return previewAssets.count
        }
    }
    
    /// 当前页面对应的 PhotoAsset 对象
    public var currentAsset: PhotoAsset? {
        if previewAssets.isEmpty {
            return assetForIndex?(pageIndex)
        }else {
            if pageIndex >= previewAssets.count || pageIndex < 0 {
                return nil
            }
            return previewAssets[pageIndex]
        }
    }
    
    /// 初始转场动画中显示的 image
    public var transitionalImage: UIImage?
    
    /// 转场动画时触发
    public var transitionAnimator: TransitionAnimator?
    
    /// 转场动画结束时触发
    public var transitionCompletion: TransitionCompletion?
    
    /// 删除预览资源时触发
    public var deleteAssetHandler: AssetHandler?
    
    /// 长按时触发
    public var longPressHandler: AssetHandler?
    
    /// 页面指示器布局的位置
    public var pageIndicatorType: PageIndicatorType = .bottom
    
    /// 页面指示器，nil则不显示
    public var pageIndicator: PhotoBrowserPageIndicator? = PhotoBrowserPageControlIndicator(frame: .init(x: 0, y: 0, width: 0, height: 30))
    
    /// 获取页数
    /// 动态设置数据时必须实现（assets.isEmpty）
    public var numberOfPages: NumberOfPagesHandler? {
        didSet { previewViewController?.numberOfPages = numberOfPages }
    }
    
    /// 当内部需要用到 PhotoAsset 对象时触发
    /// 动态设置数据时必须实现（assets.isEmpty）
    public var assetForIndex: RequiredAsset? {
        didSet { previewViewController?.assetForIndex = assetForIndex }
    }
    
    /// Cell刷新显示
    /// `func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath ) -> UICollectionViewCell` 调用时触发
    public var cellForIndex: CellReloadContext? {
        didSet { previewViewController?.cellForIndex = cellForIndex }
    }
    
    /// cell即将展示
    public var cellWillDisplay: ContextUpdate?
    
    /// cell已经消失
    public var cellDidEndDisplaying: ContextUpdate?
    
    /// cell准备点击
    public var cellShouldSingleClick: SingleClickHandler?
    
    /// cell点击事件
    public var cellSingleClick: SingleClickHandler?
    
    /// 界面发生滚动时触发
    public var viewDidScroll: ContextUpdate?
    
    /// 界面停止滚动时触发
    public var viewDidEndDecelerating: ContextUpdate?
    
    public var viewWillAppear: ViewLifeCycleHandler?
    public var viewDidAppear: ViewLifeCycleHandler?
    public var viewWillDisappear: ViewLifeCycleHandler?
    public var viewDidDisappear: ViewLifeCycleHandler?
    
    /// 初始化浏览器
    /// - Parameters:
    ///   - config: 浏览器配置
    ///   - pageIndex: 当前预览的页面
    ///   - assets: 预览的数据，如果为空则会通过 `numberOfPages、assetForIndex` 闭包动态获取
    ///   - transitionalImage: 初始转场动画显示的image
    public init(
        _ config: Configuration = .init(),
        pageIndex: Int = 0,
        assets: [PhotoAsset] = [],
        transitionalImage: UIImage? = nil
    ) {
        let previewConfig = PhotoBrowser.transformConfig(config)
        hideSourceView = config.hideSourceView
        self.transitionalImage = transitionalImage
        super.init(
            preview: previewConfig,
            previewAssets: assets,
            currentIndex: pageIndex,
            modalPresentationStyle: config.modalPresentationStyle
        )
        isShowDelete = config.showDelete
        pickerDelegate = self
    }
    
    @discardableResult
    open class func show(
        _ config: Configuration = .init(),
        pageIndex: Int = 0,
        fromVC: UIViewController? = nil,
        transitionalImage: UIImage? = nil,
        numberOfPages: @escaping NumberOfPagesHandler,
        assetForIndex: @escaping RequiredAsset,
        transitionAnimator: TransitionAnimator? = nil,
        transitionCompletion: TransitionCompletion? = nil,
        cellForIndex: CellReloadContext? = nil,
        cellWillDisplay: ContextUpdate? = nil,
        cellDidEndDisplaying: ContextUpdate? = nil,
        viewDidScroll: ContextUpdate? = nil,
        deleteAssetHandler: AssetHandler? = nil,
        longPressHandler: AssetHandler? = nil
    ) -> PhotoBrowser {
        let browser = PhotoBrowser(
            config,
            pageIndex: pageIndex,
            transitionalImage: transitionalImage
        )
        browser.transitionAnimator = transitionAnimator
        browser.transitionCompletion = transitionCompletion
        browser.numberOfPages = numberOfPages
        browser.assetForIndex = assetForIndex
        browser.cellWillDisplay = cellWillDisplay
        browser.cellDidEndDisplaying = cellDidEndDisplaying
        browser.viewDidScroll = viewDidScroll
        browser.deleteAssetHandler = deleteAssetHandler
        browser.longPressHandler = longPressHandler
        browser.show(fromVC)
        return browser
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
    open class func show(
        _ previewAssets: [PhotoAsset],
        pageIndex: Int = 0,
        config: Configuration = .init(),
        fromVC: UIViewController? = nil,
        transitionalImage: UIImage? = nil,
        transitionHandler: TransitionAnimator? = nil,
        transitionCompletion: TransitionCompletion? = nil,
        deleteAssetHandler: AssetHandler? = nil,
        longPressHandler: AssetHandler? = nil
    ) -> PhotoBrowser {
        let browser = PhotoBrowser(
            config,
            pageIndex: pageIndex,
            assets: previewAssets,
            transitionalImage: transitionalImage
        )
        browser.transitionAnimator = transitionHandler
        browser.transitionCompletion = transitionCompletion
        browser.deleteAssetHandler = deleteAssetHandler
        browser.longPressHandler = longPressHandler
        browser.show(fromVC)
        return browser
    }
    
    /// UICollectionView insertItems
    public func insertIndex(_ index: Int) {
        previewViewController?.insert(at: index)
    }
    public func insertAsset(_ asset: PhotoAsset, at index: Int) {
        previewViewController?.insert(asset, at: index)
    }
    
    /// UICollectionView deleteItems
    public func deleteIndexs(_ indexs: [Int]) {
        previewViewController?.deleteItems(at: indexs)
    }
    
    /// 获取对应 index 的 cell 对象
    public func getCell(for index: Int) -> PhotoPreviewViewCell? {
        previewViewController?.getCell(for: index)
    }
    
    /// UICollectionView reloadData
    public func reloadData() {
        previewViewController?.collectionView.reloadData()
    }
    public func reloadData(for index: Int) {
        previewViewController?.reloadCell(for: index)
    }
    
    public func show(
        _ fromVC: UIViewController? = nil,
        animated flag: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let vc: UIViewController?
        if let fromVC = fromVC {
            vc = fromVC
        }else {
            vc = UIViewController.topViewController
        }
        vc?.present(
            self,
            animated: flag,
            completion: completion
        )
    }
    
    var rightItemHandler: ((PhotoBrowser) -> Void)?
    
    public func addRightItem(
        title: String?,
        style: UIBarButtonItem.Style = .plain,
        handler: @escaping (PhotoBrowser) -> Void
    ) {
        rightItemHandler = handler
        previewViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: title,
            style: style,
            target: self,
            action: #selector(didRightItemClick)
        )
    }
    
    public func addRightItem(
        image: UIImage?,
        style: UIBarButtonItem.Style = .plain,
        handler: @escaping (PhotoBrowser) -> Void
    ) {
        rightItemHandler = handler
        previewViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: image,
            style: style,
            target: self,
            action: #selector(didRightItemClick)
        )
    }
    
    public func addRightItem(customView: UIView) {
        previewViewController?.navigationItem.rightBarButtonItem = .initCustomView(customView: customView)
    }
    
    @objc
    func didRightItemClick() {
        rightItemHandler?(self)
    }
    
    private static func transformConfig(_ config: Configuration) -> PickerConfiguration {
        var previewConfig = PickerConfiguration()
        previewConfig.prefersStatusBarHidden = true
        previewConfig.statusBarStyle = .lightContent
        previewConfig.adaptiveBarAppearance = false
        previewConfig.browserTransitionAnimator = config.transitionAnimator
        previewConfig.browserInteractiveTransitionAnimator = config.interactiveTransitionAnimator
        
        var pConfig = PreviewViewConfiguration()
        pConfig.singleClickCellAutoPlayVideo = false
        pConfig.isShowBottomView = false
        pConfig.bottomView.isShowPreviewList = false
        pConfig.cancelType = .image
        pConfig.cancelPosition = .left
        pConfig.livePhotoMark.blurStyle = .dark
        pConfig.livePhotoMark.imageColor = "#ffffff".color
        pConfig.livePhotoMark.textColor = "#ffffff".color
        pConfig.livePhotoMark.mutedImageColor = "#ffffff".color
        pConfig.HDRMark.blurStyle = .dark
        pConfig.HDRMark.imageColor = "#ffffff".color
        
        pConfig.loadNetworkVideoMode = config.loadNetworkVideoMode
        pConfig.customVideoCellClass = config.customVideoCellClass
        pConfig.backgroundColor = config.backgroundColor
        pConfig.livePhotoPlayType = config.livePhotoPlayType
        pConfig.videoPlayType = config.videoPlayType
        
        previewConfig.previewView = pConfig
        previewConfig.languageType = config.languageType
        previewConfig.customLanguages = config.customLanguages
        previewConfig.navigationTintColor = config.tintColor
        previewConfig.modalPresentationStyle = config.modalPresentationStyle
        
        return previewConfig
    }
    
    public let hideSourceView: Bool
    
    /// 导航栏阴影背景
    public var gradualShadowImageView: UIImageView!
    
    /// 点击 cell 之后导航栏、页面指示器是否隐藏
    public var didHidden: Bool = false
    
    @objc func deletePreviewAsset() {
        if pageCount == 0 {
            return
        }
        guard let asset = currentAsset else {
            return
        }
        deleteAssetHandler?(
            pageIndex,
            asset,
            self
        )
    }
    
    private var isShowDelete: Bool = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        if previewAssets.isEmpty {
            assert(
                numberOfPages != nil &&
                assetForIndex != nil,
                "previewAssets为空时，numberOfPages、assetForIndex 必须实现"
            )
        }
        if isShowDelete {
            previewViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: .textManager.picker.browserDeleteTitle.text,
                style: .done,
                target: self,
                action: #selector(deletePreviewAsset)
            )
        }
        navigationBar.shadowImage = UIImage.image(
            for: UIColor.clear,
            havingSize: .zero
        )
        navigationBar.barTintColor = .clear
        navigationBar.backgroundColor = .clear
        view.insertSubview(gradualShadowImageView, belowSubview: navigationBar)
        if let pageIndicator = pageIndicator {
            pageIndicator.reloadData(numberOfPages: pageCount, pageIndex: currentPreviewIndex)
            if pageIndicatorType == .titleView {
                previewViewController?.navigationItem.titleView = pageIndicator
            }else if pageIndicatorType == .bottom {
                if config.modalPresentationStyle == .custom {
                    pageIndicator.alpha = 0
                }
                view.addSubview(pageIndicator)
            }
        }
        
        if #available(iOS 13.0, *) {
            return
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChanged(notify:)),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil
        )
    }
    
    func setupViews() {
        pageIndicator?.pageControlChanged = { [weak self] index in
            self?.pageIndex = index
        }
        
        let navHeight = navigationBar.height
        gradualShadowImageView = UIImageView(
            image: UIImage.gradualShadowImage(
                CGSize(
                    width: view.width,
                    height: UIDevice.isAllIPhoneX ? navHeight + 60 : navHeight + 30
                )
            )
        )
        if config.modalPresentationStyle == .custom {
            gradualShadowImageView.alpha = 0
        }
    }
    
    @objc open func deviceOrientationDidChanged(notify: Notification) {
        let imageHeight = navigationBar.frame.maxY + 20
        gradualShadowImageView.image = UIImage.gradualShadowImage(
            CGSize(
                width: view.width,
                height: imageHeight
            )
        )
    }
    
    open override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        guard #available(iOS 13.0, *) else {
            return
        }
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.deviceOrientationDidChanged(
                notify: .init(
                    name: UIApplication.didChangeStatusBarOrientationNotification
                )
            )
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let imageHeight = navigationBar.frame.maxY + 20
        gradualShadowImageView.frame = CGRect(origin: .zero, size: CGSize(width: view.width, height: imageHeight))
        if let pageIndicator = pageIndicator, pageIndicatorType == .bottom {
            pageIndicator.width = view.width
            pageIndicator.y = view.height - UIDevice.bottomMargin - pageIndicator.height
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension PhotoBrowser {
    
    /// Cell刷新显示，`func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath ) -> UICollectionViewCell`调用时触发
    /// (刷新对应的Cell，cell对应的index，当前界面显示的index)
    public typealias CellReloadContext = (PhotoPreviewViewCell, Int, Int) -> Void
    /// 当内部需要用到 PhotoAsset 对象时触发
    /// (对应的index) -> index对应的 PhotoAsset 对象
    public typealias RequiredAsset = (Int) -> PhotoAsset?
    /// 获取总页数 -> 总页数
    public typealias NumberOfPagesHandler = () -> Int
    /// (当前界面显示的Cell，当前界面显示的index)
    public typealias ContextUpdate = (PhotoPreviewViewCell, Int, PhotoBrowser) -> Void
    /// (当前转场动画对应的index，转场类型) -> 动画开始/结束位置对应的View，用于获取坐标
    public typealias TransitionAnimator = (Int, TransitionType) -> UIView?
    public typealias TransitionCompletion = (Int, TransitionType) -> Void
    /// (当前界面显示的index，对应的 PhotoAsset 对象，照片浏览器对象)
    public typealias AssetHandler = (Int, PhotoAsset, PhotoBrowser) -> Void
    /// (当前界面显示的index，对应的 PhotoAsset 对象，照片浏览器对象)  -> true：按照内部逻辑处理，false：内部不做处理
    public typealias SingleClickHandler = (Int, PhotoAsset, PhotoBrowser) -> Bool
    /// (照片浏览器对象)
    public typealias ViewLifeCycleHandler = (PhotoBrowser) -> Void
    
    public struct Configuration: PhotoHUDConfig {
        
        /// If the built-in language is not enough, you can add a custom language text
        /// customLanguages - custom language array
        /// 如果自带的语言不够，可以添加自定义的语言文字
        /// PhotoManager.shared.customLanguages - 自定义语言数组
        public var languageType: LanguageType = .system
        /// 自定义语言
        public var customLanguages: [CustomLanguage] {
            get { PhotoManager.shared.customLanguages }
            set { PhotoManager.shared.customLanguages = newValue }
        }
        /// 导航栏 删除、取消 按钮颜色
        public var tintColor: UIColor = .white
        /// 网络视频加载方式
        public var loadNetworkVideoMode: PhotoAsset.LoadNetworkVideoMode = .play
        /// 自定义视频Cell，默认带有滑动条
        public var customVideoCellClass: PreviewVideoViewCell.Type? = PhotoBrowserVideoCell.self
        /// 视频播放类型
        public var videoPlayType: PhotoPreviewViewController.PlayType = .normal
        /// LivePhoto播放类型
        public var livePhotoPlayType: PhotoPreviewViewController.PlayType = .once
        /// 背景颜色
        public var backgroundColor: UIColor = .black
        /// 显示删除按钮
        public var showDelete: Bool = false
        /// 转场动画过程中是否隐藏原视图
        public var hideSourceView: Bool = true
        /// 跳转样式
        public var modalPresentationStyle: UIModalPresentationStyle = .custom
        /// 自定义转场动画实现
        public var transitionAnimator: PhotoBrowserAnimationTransitioning.Type = PhotoBrowserAnimator.self
        /// 自定义手势转场动画实现
        public var interactiveTransitionAnimator: PhotoBrowserInteractiveTransition.Type = PhotoBrowserInteractiveAnimator.self
        
        public init() { }
    }
    
    public enum PageIndicatorType {
        case titleView
        case bottom
    }
    
    public enum TransitionType {
        case present
        case dismiss
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
        viewWillAppear?(self)
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersDidAppear viewController: UIViewController
    ) {
        viewDidAppear?(self)
        if didHidden { return }
        if let pageIndicator, pageIndicator.alpha != 1 {
            pageIndicator.alpha = 1
        }
        if gradualShadowImageView.alpha != 1 {
            gradualShadowImageView.alpha = 1
        }
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersWillDisappear viewController: UIViewController
    ) {
        viewWillDisappear?(self)
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersDidDisappear viewController: UIViewController
    ) {
        viewDidDisappear?(self)
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        previewShouldSingleClick photoAsset: PhotoAsset,
        at index: Int
    ) -> Bool {
        if let cellShouldSingleClick,
           !cellShouldSingleClick(index, photoAsset, self) {
            return false
        }
        return true
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        previewSingleClick photoAsset: PhotoAsset,
        atIndex: Int
    ) {
        if let cellSingleClick,
           !cellSingleClick(atIndex, photoAsset, self) {
            return
        }
        if photoAsset.mediaType == .photo {
            pickerController.dismiss(animated: true, completion: nil)
        }else {
            didHidden = !didHidden
            UIView.animate(withDuration: 0.25) {
                self.pageIndicator?.alpha =  self.didHidden ? 0 : 1
                self.gradualShadowImageView.alpha = self.didHidden ? 0 : 1
            } completion: { _ in
                self.pageIndicator?.alpha =  self.didHidden ? 0 : 1
                self.gradualShadowImageView.alpha = self.didHidden ? 0 : 1
            }
        }
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        previewUpdateCurrentlyDisplayedAsset photoAsset: PhotoAsset,
        atIndex: Int
    ) {
        if let cell = previewViewController?.getCell(for: atIndex) {
            viewDidScroll?(cell, atIndex, self)
        }
        pageIndicator?.didChanged(pageIndex: atIndex)
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        previewDidDeleteAssets photoAssets: [PhotoAsset],
        at indexs: [Int]
    ) {
        pageIndicator?.reloadData(numberOfPages: pageCount, pageIndex: pageIndex)
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        previewLongPressClick photoAsset: PhotoAsset,
        atIndex: Int
    ) {
        longPressHandler?(atIndex, photoAsset, self)
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        previewCellWillDisplay photoAsset: PhotoAsset,
        at index: Int
    ) {
        if let cell = getCell(for: index) {
            cellWillDisplay?(cell, index, self)
        }
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        previewCellDidEndDisplaying photoAsset: PhotoAsset,
        at index: Int
    ) {
        if let cell = getCell(for: index) {
            cellDidEndDisplaying?(cell, index, self)
        }
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        previewDidEndDecelerating photoAsset: PhotoAsset,
        at index: Int
    ) {
        if let cell = getCell(for: index) {
            viewDidEndDecelerating?(cell, index, self)
        }
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
        transitionAnimator?(index, .present)
    }
    
    /// dismiss 结束时对应的视图，用于获取位置大小。与 dismissPreviewFrameForIndexAt 一样
    public func pickerController(
        _ pickerController: PhotoPickerController,
        dismissPreviewViewForIndexAt index: Int
    ) -> UIView? {
        transitionAnimator?(index, .dismiss)
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        animateTransition type: PickerTransitionType
    ) {
        pageIndicator?.alpha = type == .present ? 1 : 0
        gradualShadowImageView.alpha = type == .present ? 1 : 0
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        interPercentUpdate scale: CGFloat,
        type: PickerInteractiveTransitionType
    ) {
        if didHidden { return }
        pageIndicator?.alpha = scale
        gradualShadowImageView.alpha = scale
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        interPercentDidFinishAnimation type: PickerInteractiveTransitionType
    ) {
        pageIndicator?.alpha = 0
        gradualShadowImageView.alpha = 0
    }
    
    public func pickerController(
        _ pickerController: PhotoPickerController,
        interPercentDidCancelAnimation type: PickerInteractiveTransitionType
    ) {
        if !didHidden {
            pageIndicator?.alpha = 1
            gradualShadowImageView.alpha = 1
        }
    }
    
    public func pickerController(_ pickerController: PhotoPickerController, previewPresentComplete atIndex: Int) {
        transitionCompletion?(atIndex, .present)
    }
    
    public func pickerController(_ pickerController: PhotoPickerController, previewDismissComplete atIndex: Int) {
        transitionCompletion?(atIndex, .dismiss)
    }
}

public protocol PhotoBrowserPageIndicator: UIView {
    
    var pageControlChanged: ((Int) -> Void)? { get set }
    
    /// 刷新指示器
    /// - Parameters:
    ///   - numberOfPages: 页面总数
    ///   - pageIndex: 当前显示的页面下标
    func reloadData(numberOfPages: Int, pageIndex: Int)
    
    /// 当前页面发生改变
    /// - Parameter pageIndex: 当前显示的页面下标
    func didChanged(pageIndex: Int)
    
}

public extension PhotoBrowserPageIndicator {
    var pageControlChanged: ((Int) -> Void)? { get { nil } set { } }
}

open class PhotoBrowserDefaultPageIndicator: UIView, PhotoBrowserPageIndicator {
    
    public var titleLabel: UILabel!
    
    public var numberOfPages: Int = 0
    public var pageIndex: Int = 0 {
        didSet {
            titleLabel.text = String(pageIndex + 1) + "/" + String(numberOfPages)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel = UILabel()
        titleLabel.textColor = .white
        titleLabel.font = UIFont.semiboldPingFang(ofSize: 17)
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func reloadData(numberOfPages: Int, pageIndex: Int) {
        self.numberOfPages = numberOfPages
        self.pageIndex = pageIndex
    }
    
    public func didChanged(pageIndex: Int) {
        self.pageIndex = pageIndex
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = bounds
    }
}

open class PhotoBrowserPageControlIndicator: UIView, PhotoBrowserPageIndicator {
    
    public var maskLayer: CAGradientLayer!
    
    public var pageControl: UIPageControl!
    
    public var pageControlChanged: ((Int) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        maskLayer = PhotoTools.getGradientShadowLayer(false)
        layer.addSublayer(maskLayer)
        pageControl = UIPageControl()
        pageControl.addTarget(self, action: #selector(pageControlDidChanged), for: .valueChanged)
        addSubview(pageControl)
    }
    
    @objc
    private func pageControlDidChanged() {
        pageControlChanged?(pageControl.currentPage)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func reloadData(numberOfPages: Int, pageIndex: Int) {
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = pageIndex
    }
    
    public func didChanged(pageIndex: Int) {
        pageControl.currentPage = pageIndex
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        pageControl.frame = bounds
        maskLayer.frame = CGRect(
            x: 0,
            y: -20,
            width: width,
            height: height + 20 + UIDevice.bottomMargin
        )
    }
}

open class PhotoBrowserVideoCell: PreviewVideoControlViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        maskLayer.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.1).cgColor,
            UIColor.black.withAlphaComponent(0.2).cgColor,
            UIColor.black.withAlphaComponent(0.2).cgColor,
            UIColor.black.withAlphaComponent(0.1).cgColor,
            UIColor.black.withAlphaComponent(0).cgColor
        ]
        maskLayer.locations = [0.1, 0.2, 0.4, 0.5, 0.7, 1]
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        sliderView.frame = CGRect(
            x: 0,
            y: height - 50 - UIDevice.bottomMargin - 30,
            width: width,
            height: 50 + (UIDevice.bottomMargin == 0 ? 20 : UIDevice.bottomMargin)
        )
        maskBackgroundView.frame = sliderView.frame
        maskLayer.frame = maskBackgroundView.bounds
    }
}
