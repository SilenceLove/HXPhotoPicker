//
//  HXPHPickerController.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2020/11/9.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit
import Photos


@objc protocol HXPHPickerControllerDelegate: NSObjectProtocol {
    
    /// 选择完成之后调用，单选模式下不会走此回调
    /// - Parameters:
    ///   - pickerController: 对应的 HXPHPickerController
    ///   - selectedAssetArray: 选择的资源对应的 HXPHAsset 数据
    ///   - isOriginal: 是否选中的原图
    @objc optional func pickerContollerDidFinish(_ pickerController: HXPHPickerController, with selectedAssetArray:[HXPHAsset], with isOriginal: Bool)
    
    /// 单选完成之后调用
    /// - Parameters:
    ///   - pickerController: 对应的 HXPHPickerController
    ///   - asset: 对应的 HXPHAsset 数据
    ///   - isOriginal: 是否选中的原图
    @objc optional func pickerContollerSingleSelectFinish(_ pickerController: HXPHPickerController, with asset:HXPHAsset, with isOriginal: Bool)
    
    /// 点击了原图按钮
    /// - Parameters:
    ///   - pickerController: 对应的 HXPHPickerController
    ///   - isOriginal: 是否选中的原图
    @objc optional func pickerContollerDidOriginal(_ pickerController: HXPHPickerController, with isOriginal: Bool)
    
    /// 是否能够选择cell 不能选择时需要自己手动弹出提示框
    @objc optional func pickerControllerShouldSelectedAsset(_ pickerController: HXPHPickerController, asset: HXPHAsset, atIndex: Int) -> Bool

    /// 即将选择 cell 时调用
    @objc optional func pickerControllerWillSelectAsset(_ pickerController: HXPHPickerController, asset: HXPHAsset, atIndex: Int)

    /// 选择了 cell 之后调用
    @objc optional func pickerControllerDidSelectAsset(_ pickerController: HXPHPickerController, asset: HXPHAsset, atIndex: Int)

    /// 即将取消了选择 cell
    @objc optional func pickerControllerWillUnselectAsset(_ pickerController: HXPHPickerController, asset: HXPHAsset, atIndex: Int)

    /// 取消了选择 cell
    @objc optional func pickerControllerDidUnselectAsset(_ pickerController: HXPHPickerController, asset: HXPHAsset, atIndex: Int)
    
    
    /// 取消时调用
    /// - Parameter pickerController: 对应的 HXPHPickerController
    @objc optional func pickerContollerDidCancel(_ pickerController: HXPHPickerController)
}

class HXPHPickerController: UINavigationController, PHPhotoLibraryChangeObserver {
    
    weak var pickerContollerDelegate : HXPHPickerControllerDelegate?
    
    /// 相关配置
    lazy var config : HXPHConfiguration = {
        return HXPHConfiguration.init()
    }()
    
    /// 当前被选择的资源对应的 HXPHAsset 对象数组
    var selectedAssetArray: [HXPHAsset] = [] {
        didSet {
            if config.selectMode == .single {
                return
            }
            if !canAddedAsset {
                canAddedAsset = true
                return
            }
            for photoAsset in selectedAssetArray {
                if photoAsset.mediaType == .photo {
                    selectedPhotoAssetArray.append(photoAsset)
                }else if photoAsset.mediaType == .video {
                    selectedVideoAssetArray.append(photoAsset)
                }
            }
        }
    }
    
    /// 是否选中了原图
    var isOriginal: Bool = false
    
    /// 刷新数据
    /// 可以在传入 selectedPhotoAssetArray 之后重新加载数据将重新设置的被选择的 HXPHAsset 选中
    /// - Parameter assetCollection: 可以切换显示其他资源集合
    public func reloadData(assetCollection: HXPHAssetCollection?) {
        let pickerVC = pickerViewController()
        if pickerVC != nil {
            pickerVC!.showLoading = true
            if assetCollection == nil {
                pickerVC!.fetchPhotoAssets()
            }else {
                pickerVC!.assetCollection = assetCollection
                pickerVC!.updateTitle()
                pickerVC!.fetchPhotoAssets()
            }
        }
        reloadAlbumData()
    }
    
    /// 所有资源集合
    private(set) var assetCollectionsArray : [HXPHAssetCollection] = []
    var fetchAssetCollectionsCompletion : (([HXPHAssetCollection])->())?
    
    /// 相机胶卷资源集合
    private(set) var cameraAssetCollection : HXPHAssetCollection?
    var fetchCameraAssetCollectionCompletion : ((HXPHAssetCollection?)->())?
    
    // MARK: 私有
    private var selectType : HXPHPicker.SelectType?
    private var canAddedAsset: Bool = true
    private var selectedPhotoAssetArray: [HXPHAsset] = []
    private var selectedVideoAssetArray: [HXPHAsset] = []
    private lazy var options : PHFetchOptions = {
        let options = PHFetchOptions.init()
        return options
    }()
    private lazy var deniedView: HXPHDeniedAuthorizationView = {
        let deniedView = HXPHDeniedAuthorizationView.init(config: config.notAuthorized)
        deniedView.frame = view.bounds
        return deniedView
    }()
    
    init(config : HXPHConfiguration) {
        HXPHManager.shared.appearanceStyle = config.appearanceStyle
        _ = HXPHManager.shared.createLanguageBundle(languageType: config.languageType)
        var photoVC : UIViewController? = nil
        if config.albumShowMode == .normal {
            photoVC = HXAlbumViewController.init()
        }else if config.albumShowMode == .popup {
            photoVC = HXPHPickerViewController.init()
        }
        super.init(rootViewController: photoVC!)
        self.config = config
        configColor()
        self.navigationBar.isTranslucent = config.navigationBarIsTranslucent
        self.selectType = config.selectType
        self.setOptions()
        self.requestAuthorization()
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setOptions() {
        if selectType == .photo {
            options.predicate = NSPredicate.init(format: "mediaType == %ld", argumentArray: [PHAssetMediaType.image.rawValue])
        }else if selectType == .video {
            options.predicate = NSPredicate.init(format: "mediaType == %ld", argumentArray: [PHAssetMediaType.video.rawValue])
        }else {
            options.predicate = nil
        }
    }
    func configColor() {
        if config.appearanceStyle == .normal {
            if #available(iOS 13.0, *) {
                overrideUserInterfaceStyle = .light
            }
        }
        view.backgroundColor = HXPHManager.shared.isDark ? config.navigationViewBackgroudDarkColor : config.navigationViewBackgroudColor
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : HXPHManager.shared.isDark ? config.navigationTitleDarkColor : config.navigationTitleColor]
        navigationBar.tintColor = HXPHManager.shared.isDark ? config.navigationDarkTintColor : config.navigationTintColor
        navigationBar.barStyle = HXPHManager.shared.isDark ? config.navigationBarDarkStyle : config.navigationBarStyle
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    private func requestAuthorization() {
        let status = HXPHAssetManager.authorizationStatus()
        if status.rawValue >= 3 {
            // 有权限
            fetchData(status: status)
        }else if status.rawValue >= 1 {
            // 无权限
            view.addSubview(deniedView)
        }else {
            // 用户还没做出选择，请求权限
            HXPHAssetManager.requestAuthorization { (status) in
                self.fetchData(status: status)
            }
        }
    }
    private func fetchData(status: PHAuthorizationStatus) {
        if status.rawValue >= 3 {
            PHPhotoLibrary.shared().register(self)
            // 有权限
            HXPHProgressHUD.showLoadingHUD(addedTo: view, afterDelay: 0.15, animated: true)
            fetchCameraAssetCollection()
        }else if status.rawValue >= 1 {
            // 无权限
            view.addSubview(deniedView)
        }
    }
    // MARK: 暴露给子控制器的方法
    func finishCallback() {
        pickerContollerDelegate?.pickerContollerDidFinish?(self, with: selectedAssetArray, with: isOriginal)
        dismiss(animated: true, completion: nil)
    }
    func singleFinishCallback(for photoAsset: HXPHAsset) {
        pickerContollerDelegate?.pickerContollerSingleSelectFinish?(self, with: photoAsset, with: isOriginal)
        dismiss(animated: true, completion: nil)
    }
    func cancelCallback() {
        pickerContollerDelegate?.pickerContollerDidCancel?(self)
        dismiss(animated: true, completion: nil)
    }
    func originalButtonCallback() {
        pickerContollerDelegate?.pickerContollerDidOriginal?(self, with: isOriginal)
    }
    /// 获取相机胶卷资源集合
    func fetchCameraAssetCollection() {
        if config.creationDate {
            options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: config.creationDate)]
        }
        HXPHManager.shared.fetchCameraAssetCollection(for: selectType ?? .any, options: options) { (assetCollection) in
            if assetCollection.count == 0 {
                self.cameraAssetCollection = HXPHAssetCollection.init(albumName: self.config.albumList.emptyAlbumName, coverImage: self.config.albumList.emptyCoverImageName.hx_image)
            }else {
                // 获取封面
                assetCollection.fetchCoverAsset(reverse: self.config.reverseOrder)
                self.cameraAssetCollection = assetCollection
            }
            self.fetchCameraAssetCollectionCompletion?(self.cameraAssetCollection)
        }
    }
    
    /// 获取相册集合
    func fetchAssetCollections() {
        DispatchQueue.global().async {
            if self.config.creationDate {
                self.options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: self.config.creationDate)]
            }
            HXPHManager.shared.fetchAssetCollections(for: self.options, showEmptyCollection: false) { (assetCollection, isCameraRoll) in
                if assetCollection != nil {
                    // 获取封面
                    assetCollection!.fetchCoverAsset(reverse: self.config.reverseOrder)
                    if isCameraRoll {
                        self.assetCollectionsArray.insert(assetCollection!, at: 0);
                    }else {
                        self.assetCollectionsArray.append(assetCollection!)
                    }
                }else {
                    if !self.assetCollectionsArray.isEmpty && self.cameraAssetCollection != nil {
                        self.assetCollectionsArray[0] = self.cameraAssetCollection!
                    }
                    DispatchQueue.main.async {
                        self.fetchAssetCollectionsCompletion?(self.assetCollectionsArray)
                    }
                }
            }
        }
    }
    /// 获取相册里的资源
    /// - Parameters:
    ///   - assetCollection: 相册
    ///   - completion: 完成回调
    func fetchPhotoAssets(assetCollection: HXPHAssetCollection?, completion: @escaping ([HXPHAsset], HXPHAsset?) -> Void) {
        DispatchQueue.global().async {
            var selectedAssets = [PHAsset]()
            var selectedPhotoAssets = [HXPHAsset]()
            for phAsset in self.selectedAssetArray {
                if phAsset.asset != nil {
                    selectedAssets.append(phAsset.asset!)
                    selectedPhotoAssets.append(phAsset)
                }
            }
            var photoAssets = [HXPHAsset]()
            photoAssets.reserveCapacity(assetCollection?.count ?? 0)
            var lastAsset: HXPHAsset?
            assetCollection?.enumerateAssets(usingBlock: { (photoAsset) in
                if photoAsset.mediaType == .photo {
                    if self.selectType == .video {
                        return
                    }
                    if self.config.showImageAnimated == true {
                        if HXPHAssetManager.assetIsAnimated(asset: photoAsset.asset!) {
                            photoAsset.mediaSubType = .imageAnimated
                        }
                    }
                    if self.config.showLivePhoto == true {
                        if HXPHAssetManager.assetIsLivePhoto(asset: photoAsset.asset!) {
                            photoAsset.mediaSubType = .livePhoto
                        }
                    }
                }else if photoAsset.mediaType == .video {
                    if self.selectType == .photo {
                        return
                    }
                }
                var asset = photoAsset
                if selectedAssets.contains(asset.asset!) {
                    let index = selectedAssets.firstIndex(of: asset.asset!)!
                    let phAsset: HXPHAsset = selectedPhotoAssets[index]
                    asset = phAsset
                    lastAsset = phAsset
                }
                if self.config.reverseOrder == true {
                    photoAssets.insert(asset, at: 0)
                }else {
                    photoAssets.append(asset)
                }
            })
            DispatchQueue.main.async {
                completion(photoAssets, lastAsset)
            }
        }
    }
    func addedPhotoAsset(photoAsset: HXPHAsset) -> Bool {
        let canSelect = canSelectAsset(for: photoAsset)
        if canSelect {
            pickerContollerDelegate?.pickerControllerWillSelectAsset?(self, asset: photoAsset, atIndex: selectedAssetArray.count)
            canAddedAsset = false
            photoAsset.selected = true
            photoAsset.selectIndex = selectedAssetArray.count
            if photoAsset.mediaType == .photo {
                selectedPhotoAssetArray.append(photoAsset)
            }else if photoAsset.mediaType == .video {
                selectedVideoAssetArray.append(photoAsset)
            }
            selectedAssetArray.append(photoAsset)
            pickerContollerDelegate?.pickerControllerDidSelectAsset?(self, asset: photoAsset, atIndex: selectedAssetArray.count - 1)
        }
        return canSelect
    }
    func removePhotoAsset(photoAsset: HXPHAsset) -> Bool {
        if selectedAssetArray.isEmpty {
            return false
        }
        pickerContollerDelegate?.pickerControllerWillUnselectAsset?(self, asset: photoAsset, atIndex: selectedAssetArray.count)
        photoAsset.selected = false
        if photoAsset.mediaType == .photo {
            selectedPhotoAssetArray.remove(at: selectedPhotoAssetArray.firstIndex(of: photoAsset)!)
        }else if photoAsset.mediaType == .video {
            selectedVideoAssetArray.remove(at: selectedVideoAssetArray.firstIndex(of: photoAsset)!)
        }
        selectedAssetArray.remove(at: selectedAssetArray.firstIndex(of: photoAsset)!)
        for (index, asset) in selectedAssetArray.enumerated() {
            asset.selectIndex = index
        }
        pickerContollerDelegate?.pickerControllerDidUnselectAsset?(self, asset: photoAsset, atIndex: selectedAssetArray.count)
        return true
    }
    func canSelectAsset(for photoAsset: HXPHAsset) -> Bool {
        var canSelect = true
        var text: String?
        if photoAsset.mediaType == .photo {
            if !config.photosAndVideosCanBeSelectedTogether {
                if selectedVideoAssetArray.count > 0 {
                    text = "照片和视频不能同时选择".hx_localized
                    canSelect = false
                }
            }
            if config.maximumSelectPhotoCount > 0 {
                if selectedPhotoAssetArray.count >= config.maximumSelectPhotoCount {
                    text = String.init(format: "最多只能选择%d张照片".hx_localized, arguments: [config.maximumSelectPhotoCount])
                    canSelect = false
                }
            }else {
                if selectedAssetArray.count >= config.maximumSelectCount && config.maximumSelectCount > 0 {
                    text = String.init(format: "已达到最大选择数".hx_localized, arguments: [config.maximumSelectPhotoCount])
                    canSelect = false
                }
            }
        }else if photoAsset.mediaType == .video {
            if config.videoMaximumSelectDuration > 0 {
                if round(photoAsset.videoDuration) > Double(config.videoMaximumSelectDuration) {
                    text = String.init(format: "视频最大时长为%d秒，无法选择".hx_localized, arguments: [config.videoMaximumSelectDuration])
                    canSelect = false
                }
            }
            if config.videoMinimumSelectDuration > 0 {
                if photoAsset.videoDuration < Double(config.videoMinimumSelectDuration) {
                    text = String.init(format: "视频最小时长为%d秒，无法选择".hx_localized, arguments: [config.videoMinimumSelectDuration])
                    canSelect = false
                }
            }
            if !config.photosAndVideosCanBeSelectedTogether {
                if selectedPhotoAssetArray.count > 0 {
                    text = "视频和照片不能同时选择".hx_localized
                    canSelect = false
                }
            }
            if config.maximumSelectVideoCount > 0 {
                if selectedVideoAssetArray.count >= config.maximumSelectVideoCount {
                    text = String.init(format: "最多只能选择%d个视频".hx_localized, arguments: [config.maximumSelectPhotoCount])
                    canSelect = false
                }
            }else {
                if selectedAssetArray.count >= config.maximumSelectCount && config.maximumSelectCount > 0 {
                    text = String.init(format: "已达到最大选择数".hx_localized, arguments: [config.maximumSelectPhotoCount])
                    canSelect = false
                }
            }
        }
        if pickerContollerDelegate?.pickerControllerShouldSelectedAsset != nil {
            if canSelect {
                canSelect = pickerContollerDelegate!.pickerControllerShouldSelectedAsset!(self, asset: photoAsset, atIndex: selectedAssetArray.count)
            }
        }
        if !canSelect && text != nil {
            HXPHProgressHUD.showWarningHUD(addedTo: view, text: text!, animated: true, delay: 2)
        }
        return canSelect
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let status = HXPHAssetManager.authorizationStatus()
        if status.rawValue >= 1 && status.rawValue < 3 {
            deniedView.frame = view.bounds
        }
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return config.statusBarStyle
    }
    override var prefersStatusBarHidden: Bool {
        return topViewController?.prefersStatusBarHidden ?? false
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return topViewController?.preferredStatusBarUpdateAnimation ?? UIStatusBarAnimation.fade
    }
    
    // MARK: PHPhotoLibraryChangeObserver
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if !HXPHAssetManager.authorizationStatusIsLimited() {
            return
        }
        var needReload = false
        if assetCollectionsArray.isEmpty {
            if cameraAssetCollection != nil {
                needReload = resultHasChanges(for: changeInstance, assetCollection: cameraAssetCollection!)
            }else {
                needReload = true
            }
        }else {
            let collectionArray = assetCollectionsArray
            for assetCollection in collectionArray {
                let hasChanges = resultHasChanges(for: changeInstance, assetCollection: assetCollection)
                if !needReload {
                    needReload = hasChanges;
                    if assetCollection.count == 0 {
                        assetCollectionsArray.remove(at: assetCollectionsArray.firstIndex(of: assetCollection)!)
                    }
                }
            }
        }
        if needReload {
            DispatchQueue.main.async {
                self.reloadData(assetCollection: nil)
            }
        }
    }
    private func resultHasChanges(for changeInstance:PHChange, assetCollection: HXPHAssetCollection) -> Bool {
        if assetCollection.result == nil {
            return false
        }
        let changeResult : PHFetchResultChangeDetails? = changeInstance.changeDetails(for: assetCollection.result!)
        if changeResult != nil {
            if !changeResult!.hasIncrementalChanges {
                let result = changeResult!.fetchResultAfterChanges
                assetCollection.changeResult(for: result)
                assetCollection.fetchCoverAsset(reverse: self.config.reverseOrder)
                return true
            }
        }
        return false
    }
    private func reloadAlbumData() {
        let albumVC = albumViewController()
        if albumVC != nil {
            albumVC!.tableView.reloadData()
        }else {
            
        }
    }
    private func albumViewController() -> HXAlbumViewController? {
        for viewController in viewControllers {
            if viewController is HXAlbumViewController {
                return viewController as? HXAlbumViewController
            }
        }
        return nil
    }
    private func pickerViewController() -> HXPHPickerViewController? {
        for viewController in viewControllers {
            if viewController is HXPHPickerViewController {
                return viewController as? HXPHPickerViewController
            }
        }
        return nil
    }
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        print("\(self) deinit")
    }
}

class HXPHDeniedAuthorizationView: UIView {
    
    var config: HXPHNotAuthorizedConfiguration?
    
    lazy var closeBtn: UIButton = {
        let closeBtn = UIButton.init(type: .custom)
        closeBtn.addTarget(self, action: #selector(didCloseClick), for: .touchUpInside)
        closeBtn.contentVerticalAlignment = .top
        return closeBtn
    }()
    
    lazy var titleLb: UILabel = {
        let titleLb = UILabel.init()
        titleLb.textAlignment = .center
        titleLb.numberOfLines = 0
        return titleLb
    }()
    
    lazy var subTitleLb: UILabel = {
        let subTitleLb = UILabel.init()
        subTitleLb.textAlignment = .center
        subTitleLb.numberOfLines = 0
        return subTitleLb
    }()
    
    lazy var jumpBtn: UIButton = {
        let jumpBtn = UIButton.init(type: .custom)
        jumpBtn.layer.cornerRadius = 5
        jumpBtn.addTarget(self, action: #selector(jumpSetting), for: .touchUpInside)
        return jumpBtn
    }()
    
    init(config: HXPHNotAuthorizedConfiguration?) {
        super.init(frame: CGRect.zero)
        self.config = config
        configView()
    }
    
    func configView() {
        addSubview(closeBtn)
        addSubview(titleLb)
        addSubview(subTitleLb)
        addSubview(jumpBtn)
        closeBtn.setImage(UIImage.hx_named(named: config?.closeButtonImageName ?? "hx_picker_notAuthorized_close"), for: .normal)
        
        titleLb.text = "无法访问相册中照片".hx_localized
        titleLb.font = UIFont.hx_semiboldPingFang(size: 20)
        
        subTitleLb.text = "当前无照片访问权限，建议前往系统设置，\n允许访问「照片」中的「所有照片」。".hx_localized
        subTitleLb.font = UIFont.hx_regularPingFang(size: 17)
        
        jumpBtn.setTitle("前往系统设置".hx_localized, for: .normal)
        jumpBtn.titleLabel?.font = UIFont.hx_mediumPingFang(size: 16)
        
        configColor()
    }
    func configColor() {
        backgroundColor = HXPHManager.shared.isDark ? config?.darkBackgroudColor : config?.backgroudColor
        titleLb.textColor = HXPHManager.shared.isDark ? config?.darkTitleColor : config?.titleColor
        subTitleLb.textColor = HXPHManager.shared.isDark ? config?.darkSubTitleColor : config?.subTitleColor
        jumpBtn.backgroundColor = HXPHManager.shared.isDark ? config?.jumpButtonDarkBackgroudColor : config?.jumpButtonBackgroudColor
        jumpBtn.setTitleColor(HXPHManager.shared.isDark ? config?.jumpButtonDarkTitleColor : config?.jumpButtonTitleColor, for: .normal)
    }
    @objc func didCloseClick() {
        self.hx_viewController()?.dismiss(animated: true, completion: nil)
    }
    @objc func jumpSetting() {
        HXPHTools.openSettingsURL()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        closeBtn.frame = CGRect(x: 20, y: UIDevice.current.hx_statusBarHeight + 5, width: 50, height: 50)
        
        let titleHeight = titleLb.text?.hx_stringHeight(ofFont: titleLb.font, maxWidth: hx_width) ?? 0
        titleLb.frame = CGRect(x: 0, y: 0, width: hx_width, height: titleHeight)
        
        let subTitleHeight = subTitleLb.text?.hx_stringHeight(ofFont: subTitleLb.font, maxWidth: hx_width - 40) ?? 0
        subTitleLb.frame = CGRect(x: 20, y: hx_height / 2 - subTitleHeight - 30 - UIDevice.current.hx_topMargin, width: hx_width - 40, height: subTitleHeight)
        titleLb.hx_y = subTitleLb.hx_y - 15 - titleHeight
        
        let jumpBtnBottomMargin : CGFloat = UIDevice.isProxy() ? 120 : 50
        jumpBtn.frame = CGRect(x: 0, y: hx_height - UIDevice.current.hx_bottomMargin - 40 - jumpBtnBottomMargin, width: 150, height: 40)
        jumpBtn.hx_centerX = hx_width * 0.5
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
