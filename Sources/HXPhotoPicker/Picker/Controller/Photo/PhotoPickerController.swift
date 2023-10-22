//
//  PhotoPickerController.swift
//  照片选择器-Swift
//
//  Created by Silence on 2020/11/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

open class PhotoPickerController: UINavigationController {
    
    public typealias FinishHandler = (PickerResult, PhotoPickerController) -> Void
    public typealias CancelHandler = (PhotoPickerController) -> Void
    
    public weak var pickerDelegate: PhotoPickerControllerDelegate?
    
    public var finishHandler: FinishHandler?
    public var cancelHandler: CancelHandler?
    
    /// 相关配置
    public var config: PickerConfiguration
    
    /// 当前被选择的资源对应的 PhotoAsset 对象数组
    /// 外部预览时的资源数据
    public var selectedAssetArray: [PhotoAsset] {
        get { pickerData.selectedAssets }
        set {
            if previewType == .browser {
                for photoAsset in newValue {
                    photoAsset.isSelected = true
                }
                previewViewController?.previewAssets = newValue
                return
            }
            pickerData.setSelectedAssets(newValue)
        }
    }
    
    public var selectedPhotoAssets: [PhotoAsset] { pickerData.selectedPhotoAssets }
    public var selectedVideoAssets: [PhotoAsset] { pickerData.selectedVideoAssets }
    
    /// 是否选中了原图，配置不显示原图按钮时，内部也是根据此属性来判断是否获取原图数据
    public var isOriginal: Bool = false
    
    /// fetch Assets 时的选项配置
    public var options: PHFetchOptions {
        get { fetchData.options }
        set { fetchData.options = newValue }
    }
    
    /// 完成/取消时自动 dismiss ,为false需要自己在代理回调里手动 dismiss
    public var autoDismiss: Bool = true
    
    /// 本地资源数组
    /// 创建本地资源的PhotoAsset然后赋值即可添加到照片列表，如需选中也要添加到selectedAssetArray中
    public var localAssetArray: [PhotoAsset] {
        get { pickerData.localAssets }
        set { pickerData.localAssets = newValue }
    }
    
    /// 相机拍摄存在本地的资源数组（通过相机拍摄的但是没有保存到系统相册）
    /// 可以通过 pickerControllerDidDismiss 得到上一次相机拍摄的资源，然后赋值即可显示上一次相机拍摄的资源
    public var localCameraAssetArray: [PhotoAsset] {
        get { pickerData.localCameraAssets }
        set { pickerData.localCameraAssets = newValue }
    }
    
    /// 刷新数据
    /// 可以在传入 selectedAssetArray 之后重新加载数据将重新设置的被选择的 PhotoAsset 选中
    /// - Parameter assetCollection: 切换显示其他资源集合
    public func reloadData(assetCollection: PhotoAssetCollection?) {
        pickerViewController?.updateAssetCollection(assetCollection)
        reloadAlbumData()
    }
    
    /// 刷新相册数据，只对单独控制器展示的有效
    public func reloadAlbumData() {
        if splitType.isSplit {
            albumViewController?.listView.reloadData()
        }else {
            if config.albumShowMode.isPopView {
                pickerViewController?.reloadAlbumData()
            }else {
                photoAlbumViewController?.reloadData()
            }
        }
    }
    
    /// 使用其他相机拍摄完之后调用此方法添加
    /// - Parameter photoAsset: 对应的 PhotoAsset 数据
    public func addedCameraPhotoAsset(_ photoAsset: PhotoAsset) {
        pickerViewController?.addedCameraPhotoAsset(photoAsset)
        previewViewController?.addedCameraPhotoAsset(photoAsset)
    }
    
    /// 删除当前预览的 Asset
    public func deleteCurrentPreviewPhotoAsset() {
        previewViewController?.deleteCurrentPhotoAsset()
    }
    
    /// 预览界面添加本地资源
    /// - Parameter photoAsset: 对应的 PhotoAsset 数据
    public func previewAddedCameraPhotoAsset(_ photoAsset: PhotoAsset) {
        previewViewController?.addedCameraPhotoAsset(photoAsset)
    }
    
    /// 获取预览界面当前显示的 image 视图
    /// - Returns: 对应的 UIImageView
    public func getCurrentPreviewImageView() -> UIImageView? {
        if let previewVC = previewViewController,
           let cell = previewVC.getCell(for: previewVC.currentPreviewIndex) {
            return cell.scrollContentView.imageView.imageView
        }
        return nil
    }
    
    /// 预览界面的数据
    public var previewAssets: [PhotoAsset] {
        if let assets = previewViewController?.previewAssets {
            return assets
        }
        return []
    }
    
    /// 预览界面当前显示的页数
    public var currentPreviewIndex: Int {
        if let index = previewViewController?.currentPreviewIndex {
            return index
        }
        return 0
    }
    
    /// 获取预览界面当前显示的 image 视图
    /// - Returns: 对应的 UIImageView
    public var currentPreviewImageView: UIImageView? {
        getCurrentPreviewImageView()
    }
    
    /// UISplitViewController 中的相册列表控制器
    public var albumViewController: AlbumViewController? {
        getViewController(
            for: AlbumViewController.self
        ) as? AlbumViewController
    }
    
    public var photoAlbumViewController: PhotoAlbumController? {
        for case let vc as PhotoAlbumController in viewControllers {
            return vc
        }
        return nil
    }
    
    /// 照片选择控制器
    public var pickerViewController: PhotoPickerViewController? {
        getViewController(
            for: PhotoPickerViewController.self
        ) as? PhotoPickerViewController
    }
    /// 照片预览控制器
    public var previewViewController: PhotoPreviewViewController? {
        getViewController(
            for: PhotoPreviewViewController.self
        ) as? PhotoPreviewViewController
    }
    
    /// 当前处于的外部预览
    public let previewType: PhotoPreviewType
    
    /// 选择资源初始化
    /// - Parameter config: 相关配置
    public convenience init(
        picker config: PickerConfiguration,
        delegate: PhotoPickerControllerDelegate? = nil
    ) {
        self.init(
            config: config,
            delegate: delegate
        )
    }
    
    /// 选择资源初始化
    /// - Parameter config: 相关配置
    public init(
        config: PickerConfiguration,
        delegate: PhotoPickerControllerDelegate? = nil
    ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        self.config = config
        previewType = .none
        pickerData = config.pickerData.init(config: config)
        fetchData = config.fetchdata.init(config: config, pickerData: pickerData)
        splitType = .none
        super.init(nibName: nil, bundle: nil)
        pickerData.delegate = self
        fetchData.delegate = self
        isOriginal = config.isSelectedOriginal
        autoDismiss = config.isAutoBack
        modalPresentationStyle = config.modalPresentationStyle
        pickerDelegate = delegate
        var photoVC: UIViewController
        switch config.albumShowMode {
        case .normal:
            let vc = config.albumController.albumController.init(config: config)
            vc.delegate = self
            photoVC = vc
        default:
            photoVC = PhotoPickerViewController(config: config)
        }
        self.viewControllers = [photoVC]
    }
    
    /// 选择资源初始化
    /// - Parameter config: 相关配置
    public convenience init(
        config: PickerConfiguration,
        finish: FinishHandler? = nil,
        cancel: CancelHandler? = nil
    ) {
        self.init(config: config)
        self.finishHandler = finish
        self.cancelHandler = cancel
    }
    
    /// 外部预览资源初始化
    /// - Parameters:
    ///   - config: 相关配置
    ///   - currentIndex: 当前预览的下标
    ///   - modalPresentationStyle: 默认 custom 样式，框架自带动画效果
    public init(
        preview config: PickerConfiguration,
        previewAssets: [PhotoAsset],
        currentIndex: Int,
        selectedAssets: [PhotoAsset] = [],
        previewType: PhotoPreviewType = .browser,
        modalPresentationStyle: UIModalPresentationStyle = .custom,
        delegate: PhotoPickerControllerDelegate? = nil
    ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        self.config = config
        self.previewType = previewType
        pickerData = config.pickerData.init(config: config)
        fetchData = config.fetchdata.init(config: config, pickerData: pickerData)
        splitType = .none
        super.init(nibName: nil, bundle: nil)
        pickerData.delegate = self
        fetchData.delegate = self
        isOriginal = config.isSelectedOriginal
        autoDismiss = config.isAutoBack
        pickerDelegate = delegate
        selectedAssetArray = selectedAssets
        let vc = PhotoPreviewViewController(config: self.config)
        vc.previewType = previewType
        vc.previewAssets = previewAssets
        vc.currentPreviewIndex = currentIndex
        self.viewControllers = [vc]
        self.modalPresentationStyle = modalPresentationStyle
        if modalPresentationStyle == .custom {
            transitioningDelegate = self
            modalPresentationCapturesStatusBarAppearance = true
        }
    }
    
    public init(
        splitPicker config: PickerConfiguration,
        delegate: PhotoPickerControllerDelegate? = nil
    ) {
        var tmpConfig = config
        tmpConfig.albumShowMode = .popup
        if tmpConfig.modalPresentationStyle == .fullScreen {
            tmpConfig.photoList.previewStyle = .present
            #if HXPICKER_ENABLE_EDITOR
            tmpConfig.editorJumpStyle = .present(.custom)
            #endif
        }
        self.config = tmpConfig
        PhotoManager.shared.appearanceStyle = self.config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: self.config.languageType)
        splitType = .picker
        previewType = .none
        pickerData = self.config.pickerData.init(config: self.config)
        fetchData = self.config.fetchdata.init(config: self.config, pickerData: pickerData)
        super.init(nibName: nil, bundle: nil)
        pickerData.delegate = self
        fetchData.delegate = self
        isOriginal = self.config.isSelectedOriginal
        autoDismiss = self.config.isAutoBack
        pickerDelegate = delegate
        modalPresentationStyle = config.modalPresentationStyle
        let vc = PhotoPickerViewController(config: self.config)
        self.viewControllers = [vc]
    }
    
    public init(
        splitAlbum config: PickerConfiguration
    ) {
        splitType = .album
        self.config = config
        previewType = .none
        pickerData = config.pickerData.init(config: config)
        fetchData = config.fetchdata.init(config: config, pickerData: pickerData)
        super.init(nibName: nil, bundle: nil)
        fetchData.delegate = self
        modalPresentationStyle = config.modalPresentationStyle
        let vc = AlbumViewController(config: config)
        self.viewControllers = [vc]
    }
    
    init() {
        self.config = .init()
        previewType = .none
        pickerData = config.pickerData.init(config: config)
        fetchData = config.fetchdata.init(config: config, pickerData: pickerData)
        splitType = .none
        super.init(nibName: nil, bundle: nil)
    }
    
    let splitType: SplitContentType
    let fetchData: PhotoFetchData
    let pickerData: PhotoPickerData
    var deniedView: PhotoDeniedAuthorization!
    var disablesCustomDismiss = false
    var interactiveTransition: PickerInteractiveTransition?
    var dismissInteractiveTransition: PickerControllerInteractiveTransition?
    var isDismissed: Bool = false
    private var pickerTask: Any?
    private var isFirstAuthorization: Bool = false
    var isFetchAssetCollection: Bool = false
    
    public override var modalPresentationStyle: UIModalPresentationStyle {
        didSet {
            if previewType != .none && modalPresentationStyle == .custom && !splitType.isSplit {
                transitioningDelegate = self
                modalPresentationCapturesStatusBarAppearance = true
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        PhotoManager.shared.indicatorType = config.indicatorType
        PhotoManager.shared.loadNetworkVideoMode = config.previewView.loadNetworkVideoMode
        PhotoManager.shared.thumbnailLoadMode = .complete
        initViews()
        if splitType.isSplit {
            if splitType == .picker {
                requestAuthorization()
            }
            return
        }
        if previewType == .none {
            requestAuthorization()
            if modalPresentationStyle == .fullScreen &&
                config.albumShowMode.isPop &&
                config.allowCustomTransitionAnimation {
                modalPresentationCapturesStatusBarAppearance = true
                switch config.pickerPresentStyle {
                case .present(let rightSwipe):
                    transitioningDelegate = self
                    if let rightSwipe = rightSwipe {
                        dismissInteractiveTransition = .init(
                            panGestureRecognizerFor: self,
                            type: .dismiss,
                            triggerRange: rightSwipe.triggerRange
                        )
                    }
                case .push(let rightSwipe):
                    transitioningDelegate = self
                    if let rightSwipe = rightSwipe {
                        dismissInteractiveTransition = .init(
                            panGestureRecognizerFor: self,
                            type: .pop,
                            triggerRange: rightSwipe.triggerRange
                        )
                    }
                default:
                    break
                }
            }
        }else {
            if modalPresentationStyle == .custom && config.allowCustomTransitionAnimation {
                interactiveTransition = .init(panGestureRecognizerFor: self, type: .dismiss)
            }
        }
    }
    
    private func initViews() {
        configColor()
        navigationBar.isTranslucent = config.navigationBarIsTranslucent
        deniedView = config.notAuthorizedView.init(config: config)
        if let view = splitViewController?.view {
            deniedView.frame = view.bounds
        }else {
            deniedView.frame = view.bounds
        }
    }
    
    public override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        if isFirstAuthorization &&
            viewControllerToPresent is UIImagePickerController {
            viewControllerToPresent.modalPresentationStyle = .fullScreen
            isFirstAuthorization = false
        }
        super.present(
            viewControllerToPresent,
            animated: flag,
            completion: completion
        )
    }
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let status = AssetManager.authorizationStatus()
        if status.rawValue >= 1 && status.rawValue < 3 {
            if let view = splitViewController?.view {
                deniedView.frame = view.bounds
            }else {
                deniedView.frame = view.bounds
            }
        }
    }
    
    public func dismiss(_ animated: Bool, completion: (() -> Void)? = nil) {
        dismiss(animated: animated, completion: completion)
    }
    
    open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if let viewController = presentedViewController as? PhotoPickerController, config.photoList.previewStyle == .present {
            #if HXPICKER_ENABLE_EDITOR
            if viewController.presentedViewController is EditorViewController {
                if let splitVC = viewController.presentingViewController as? PhotoSplitViewController {
                    splitVC.presentingViewController?.dismiss(animated: flag, completion: completion)
                }else {
                    viewController.presentingViewController?.dismiss(animated: flag, completion: completion)
                }
            }else {
                presentingViewController?.dismiss(animated: flag, completion: completion)
            }
            #else
            presentingViewController?.dismiss(animated: flag, completion: completion)
            #endif
            return
        }
        #if HXPICKER_ENABLE_EDITOR
        if presentedViewController is EditorViewController {
            presentingViewController?.dismiss(animated: flag, completion: completion)
            return
        }
        #endif
        super.dismiss(animated: flag, completion: completion)
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if PhotoManager.isDark {
            return .lightContent
        }
        return config.statusBarStyle
    }
    public override var prefersStatusBarHidden: Bool {
        if config.prefersStatusBarHidden {
            return true
        }else {
            if let prefersStatusBarHidden = topViewController?.prefersStatusBarHidden {
                return prefersStatusBarHidden
            }
            return false
        }
    }
    open override var shouldAutorotate: Bool {
        config.shouldAutorotate
    }
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        config.supportedInterfaceOrientations
    }
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        if let animation = topViewController?.preferredStatusBarUpdateAnimation {
            return animation
        }
        return .fade
    }
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if previewType == .none && presentingViewController == nil {
            didDismiss()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        PhotoManager.shared.thumbnailLoadMode = .complete
        PhotoManager.shared.firstLoadAssets = false
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    enum SplitContentType {
        case none
        case album
        case picker
        
        var isSplit: Bool {
            self != .none
        }
    }
}

// MARK: Private function
extension PhotoPickerController {
    func configBackgroundColor() {
        view.backgroundColor = PhotoManager.isDark ?
            config.navigationViewBackgroudDarkColor :
            config.navigationViewBackgroundColor
    }
    private func configColor() {
        if config.appearanceStyle == .normal {
            if #available(iOS 13.0, *) {
                overrideUserInterfaceStyle = .light
            }
        }
        
        if modalPresentationStyle != .custom {
            configBackgroundColor()
        }
        let isDark = PhotoManager.isDark
        let titleTextAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor:
                isDark ? config.navigationTitleDarkColor : config.navigationTitleColor
        ]
        navigationBar.titleTextAttributes = titleTextAttributes
        let tintColor = isDark ? config.navigationDarkTintColor : config.navigationTintColor
        navigationBar.tintColor = tintColor
        let barStyle = isDark ? config.navigationBarDarkStyle : config.navigationBarStyle
        navigationBar.barStyle = barStyle
        
        if !config.adaptiveBarAppearance {
            return
        }
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.titleTextAttributes = titleTextAttributes
            switch barStyle {
            case .`default`:
                appearance.backgroundEffect = UIBlurEffect(style: .extraLight)
            default:
                appearance.backgroundEffect = UIBlurEffect(style: .dark)
            }
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        }
    }
    private func requestAuthorization() {
        if splitType == .album {
            return
        }
        if !config.allowLoadPhotoLibrary {
            fetchData.fetchCameraAssetCollection()
            return
        }
        let status = AssetManager.authorizationStatus()
        if status.rawValue >= 3 {
            // 有权限
            PHPhotoLibrary.shared().register(self)
            if !PhotoManager.shared.didRegisterObserver {
                ProgressHUD.showLoading(addedTo: view, animated: true)
            }else {
                ProgressHUD.showLoading(addedTo: view, afterDelay: 0.15, animated: true)
            }
            fetchData.fetchCameraAssetCollection()
            if config.albumShowMode.isPop {
                fetchData.fetchAssetCollections()
            }
        }else if status.rawValue >= 1 {
            // 无权限
            if splitType.isSplit {
                splitViewController?.view.addSubview(deniedView)
            }else {
                view.addSubview(deniedView)
            }
        }else {
            // 用户还没做出选择，请求权限
            isFirstAuthorization = true
            AssetManager.requestAuthorization { _ in
                self.requestAuthorization()
                self.albumViewController?.reloadData()
                self.pickerViewController?.reloadAlbumData()
                PhotoManager.shared.registerPhotoChangeObserver()
            }
        }
    }
    private func getViewController(for viewControllerClass: UIViewController.Type) -> UIViewController? {
        for vc in viewControllers where vc.isMember(of: viewControllerClass) {
            return vc
        }
        return nil
    }
    private func didDismiss() {
        if #available(iOS 13.0, *) {
            if let task = pickerTask as? Task<(), Never> {
                task.cancel()
                pickerTask = nil
            }
        }
        #if HXPICKER_ENABLE_EDITOR
        pickerData.removeAllEditedPhotoAsset()
        #endif
        var cameraAssetArray: [PhotoAsset] = []
        for photoAsset in localCameraAssetArray {
            if let cameraAsset = photoAsset.cameraAsset {
                cameraAssetArray.append(cameraAsset)
            }
        }
        PhotoManager.shared.saveCameraPreview()
        pickerDelegate?.pickerController(self, didDismissComplete: cameraAssetArray)
        if !isDismissed {
            cancelHandler?(self)
        }
    }
}

extension PhotoPickerController: UINavigationControllerDelegate, PhotoAlbumControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is PhotoAlbumController {
            if fetchData.assetCollections.isEmpty, !isFetchAssetCollection {
                isFetchAssetCollection = true
                ProgressHUD.showLoading(addedTo: viewController.view)
                fetchData.fetchAssetCollections()
            }
        }
    }
    
    public func albumController(_ albumController: PhotoAlbumController, didSelectedWith assetCollection: PhotoAssetCollection) {
        let vc = PhotoPickerViewController(config: config)
        vc.assetCollection = assetCollection
        vc.showLoading = true
        pushViewController(vc, animated: true)
    }
    public func albumController(willAppear viewController: PhotoAlbumController) {
        viewControllersWillAppear(viewController)
    }
    public func albumController(didAppear viewController: PhotoAlbumController) {
        viewControllersDidAppear(viewController)
    }
    public func albumController(willDisappear viewController: PhotoAlbumController) {
        viewControllersWillDisappear(viewController)
    }
    public func albumController(didDisappear viewController: PhotoAlbumController) {
        viewControllersDidDisappear(viewController)
    }
}

@available(iOS 13.0.0, *)
public extension PhotoPickerController {
    
    /// 选择资源
    /// - Parameters:
    ///   - config: 选择器配置
    ///   - delegate: 选择器代理回调
    ///   - compression: 压缩参数，不传则根据内部 isOriginal 判断是否压缩
    ///   - fromVC: 来源控制器
    ///   - fileConfig: 指定获取URL的路径
    /// - Returns: 获取对应的对象数组
    static func picker<T: PhotoAssetObject>(
        _ config: PickerConfiguration,
        selectedAssets: [PhotoAsset] = [],
        delegate: PhotoPickerControllerDelegate? = nil,
        compression: PhotoAsset.Compression? = nil,
        fromVC: UIViewController? = nil,
        toFile fileConfig: PickerResult.FileConfigHandler? = nil
    ) async throws -> [T] {
        var config = config
        config.isAutoBack = false
        let vc = show(config, selectedAssets: selectedAssets, delegate: delegate, fromVC: fromVC)
        return try await vc.pickerObject(compression, toFile: fileConfig)
    }
    
    static func picker(
        _ config: PickerConfiguration,
        selectedAssets: [PhotoAsset] = [],
        delegate: PhotoPickerControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> PickerResult {
        let vc = show(config, selectedAssets: selectedAssets, delegate: delegate, fromVC: fromVC)
        return try await vc.picker()
    }
    
    static func show(
        _ config: PickerConfiguration,
        selectedAssets: [PhotoAsset] = [],
        delegate: PhotoPickerControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) -> PhotoPickerController {
        let topVC: UIViewController?
        if let fromVC = fromVC {
            topVC = fromVC
        }else {
            topVC = UIViewController.topViewController
        }
        let pickerController: PhotoPickerController
        if !UIDevice.isPad {
            pickerController = PhotoPickerController(picker: config, delegate: delegate)
            pickerController.selectedAssetArray = selectedAssets
            topVC?.present(pickerController, animated: true)
        }else {
            pickerController = PhotoPickerController(splitPicker: config, delegate: delegate)
            pickerController.selectedAssetArray = selectedAssets
            let splitController = PhotoSplitViewController(picker: pickerController)
            topVC?.present(splitController, animated: true)
        }
        return pickerController
    }
    
    func picker() async throws -> PickerResult {
        try await withCheckedThrowingContinuation { continuation in
            var isDimissed: Bool = false
            finishHandler = { result, _ in
                if isDimissed { return }
                isDimissed = true
                continuation.resume(with: .success(result))
            }
            cancelHandler = { _ in
                if isDimissed { return }
                isDimissed = true
                continuation.resume(with: .failure(PickerError.canceled))
            }
        }
    }
    
    /// 获取资源
    /// - Parameters:
    ///   - compression: 压缩参数，不传则根据内部 isOriginal 判断是否压缩
    ///   - fileConfig: 指定获取URL的路径
    /// - Returns: 获取对应的对象数组
    func pickerObject<T: PhotoAssetObject>(
       _ compression: PhotoAsset.Compression? = nil,
       toFile fileConfig: PickerResult.FileConfigHandler? = nil
    ) async throws -> [T] {
       try await withCheckedThrowingContinuation { continuation in
           var isDimissed: Bool = false
           finishHandler = { [weak self] result, controller in
               guard let self = self else { return }
               if isDimissed { return }
               isDimissed = true
               ProgressHUD.showLoading(addedTo: self.view)
               self.pickerTask = Task {
                   do {
                       let objects: [T] = try await result.objects(compression, toFile: fileConfig)
                       if !Task.isCancelled {
                           continuation.resume(with: .success(objects))
                       }else {
                           self.pickerTask = nil
                           continuation.resume(with: .failure(PickerError.canceled))
                           return
                       }
                   } catch {
                       continuation.resume(with: .failure(error))
                   }
                   self.pickerTask = nil
                   ProgressHUD.hide(forView: self.view)
                   controller.dismiss(true)
               }
           }
           cancelHandler = { controller in
               if isDimissed { return }
               isDimissed = true
               controller.dismiss(true)
               continuation.resume(with: .failure(PickerError.canceled))
           }
       }
   }
}
