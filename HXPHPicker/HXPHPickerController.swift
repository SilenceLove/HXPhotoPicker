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
    @objc optional func pickerContollerDidFinish(_ pickerController: HXPHPickerController, with selectedAssetArray:[HXPHAsset], isOriginal: Bool)
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
            if !canAddedAsset {
                canAddedAsset = true
                return
            }
            for photoAsset in selectedAssetArray {
                if photoAsset.mediaType == HXPHAssetMediaType.photo {
                    selectedPhotoAssetArray.append(photoAsset)
                }else if photoAsset.mediaType == HXPHAssetMediaType.video {
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
    private var selectType : HXPHSelectType?
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
        _ = HXPHManager.shared.createLanguageBundle(languageType: config.languageType)
        var photoVC : UIViewController? = nil
        if config.albumShowMode == HXAlbumShowMode.normal {
            photoVC = HXAlbumViewController.init()
        }else if config.albumShowMode == HXAlbumShowMode.popup {
            photoVC = HXPHPickerViewController.init()
        }
        super.init(rootViewController: photoVC!)
        self.config = config
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
        if selectType == HXPHSelectType.photo {
            options.predicate = NSPredicate.init(format: "mediaType == %ld", argumentArray: [PHAssetMediaType.image.rawValue])
        }else if selectType == HXPHSelectType.video {
            options.predicate = NSPredicate.init(format: "mediaType == %ld", argumentArray: [PHAssetMediaType.video.rawValue])
        }else {
            options.predicate = nil
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
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
        pickerContollerDelegate?.pickerContollerDidFinish?(self, with: selectedAssetArray, isOriginal: isOriginal)
    }
    func cancelCallback() {
        pickerContollerDelegate?.pickerContollerDidCancel?(self)
    }
    /// 获取相机胶卷资源集合
    func fetchCameraAssetCollection() {
        options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: config.creationDate)]
        HXPHManager.shared.fetchCameraAssetCollection(for: selectType ?? HXPHSelectType.any, options: options) { (assetCollection) in
            if assetCollection.count == 0 {
                self.cameraAssetCollection = HXPHAssetCollection.init(albumName: self.config.albumList.emptyAlbumName, coverImage: UIImage.hx_named(named: self.config.albumList.emptyCoverImageName))
            }else {
                self.cameraAssetCollection = assetCollection
            }
            self.fetchCameraAssetCollectionCompletion?(self.cameraAssetCollection)
        }
    }
    func fetchAssetCollections() {
        options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: config.creationDate)]
        HXPHManager.shared.fetchAssetCollections(for: options, showEmptyCollection: false) { (assetCollectionsArray) in
            self.assetCollectionsArray = assetCollectionsArray
            if !assetCollectionsArray.isEmpty, self.cameraAssetCollection != nil {
                self.assetCollectionsArray[0] = self.cameraAssetCollection!
            }
            self.fetchAssetCollectionsCompletion?(self.assetCollectionsArray)
        }
    }
    func addedPhotoAsset(photoAsset: HXPHAsset) -> Bool {
        let canSelect = canSelectAsset(for: photoAsset)
        if canSelect {
            canAddedAsset = false
            photoAsset.selected = true
            photoAsset.selectIndex = selectedAssetArray.count
            if photoAsset.mediaType == HXPHAssetMediaType.photo {
                selectedPhotoAssetArray.append(photoAsset)
            }else if photoAsset.mediaType == HXPHAssetMediaType.video {
                selectedVideoAssetArray.append(photoAsset)
            }
            selectedAssetArray.append(photoAsset)
        }
        return canSelect
    }
    func removePhotoAsset(photoAsset: HXPHAsset) -> Bool {
        if selectedAssetArray.isEmpty {
            return false
        }
        photoAsset.selected = false
        if photoAsset.mediaType == HXPHAssetMediaType.photo {
            selectedPhotoAssetArray.remove(at: selectedPhotoAssetArray.firstIndex(of: photoAsset)!)
        }else if photoAsset.mediaType == HXPHAssetMediaType.video {
            selectedVideoAssetArray.remove(at: selectedVideoAssetArray.firstIndex(of: photoAsset)!)
        }
        selectedAssetArray.remove(at: selectedAssetArray.firstIndex(of: photoAsset)!)
        for (index, asset) in selectedAssetArray.enumerated() {
            asset.selectIndex = index
        }
        return true
    }
    func canSelectAsset(for photoAsset: HXPHAsset) -> Bool {
        var canSelect = true
        var text: String?
        if photoAsset.mediaType == HXPHAssetMediaType.photo {
            if !config.photosAndVideosCanBeSelectedTogether {
                if selectedVideoAssetArray.count > 0 {
                    text = "照片和视频不能同时选择".hx_localized()
                    canSelect = false
                }
            }
            if config.maximumSelectPhotoCount > 0 {
                if selectedPhotoAssetArray.count >= config.maximumSelectPhotoCount {
                    text = String.init(format: "最多只能选择%d张照片".hx_localized(), arguments: [config.maximumSelectPhotoCount])
                    canSelect = false
                }
            }else {
                if selectedAssetArray.count >= config.maximumSelectCount && config.maximumSelectCount > 0 {
                    text = String.init(format: "已达到最大选择数".hx_localized(), arguments: [config.maximumSelectPhotoCount])
                    canSelect = false
                }
            }
        }else if photoAsset.mediaType == HXPHAssetMediaType.video {
            if config.videoMaximumSelectDuration > 0 {
                if round(photoAsset.videoDuration) > Double(config.videoMaximumSelectDuration) {
                    text = String.init(format: "视频最大时长为%d秒，无法选择".hx_localized(), arguments: [config.videoMaximumSelectDuration])
                    canSelect = false
                }
            }
            if config.videoMinimumSelectDuration > 0 {
                if photoAsset.videoDuration < Double(config.videoMinimumSelectDuration) {
                    text = String.init(format: "视频最小时长为%d秒，无法选择".hx_localized(), arguments: [config.videoMinimumSelectDuration])
                    canSelect = false
                }
            }
            if !config.photosAndVideosCanBeSelectedTogether {
                if selectedPhotoAssetArray.count > 0 {
                    text = "视频和照片不能同时选择".hx_localized()
                    canSelect = false
                }
            }
            if config.maximumSelectVideoCount > 0 {
                if selectedVideoAssetArray.count >= config.maximumSelectVideoCount {
                    text = String.init(format: "最多只能选择%d个视频".hx_localized(), arguments: [config.maximumSelectPhotoCount])
                    canSelect = false
                }
            }else {
                if selectedAssetArray.count >= config.maximumSelectCount && config.maximumSelectCount > 0 {
                    text = String.init(format: "已达到最大选择数".hx_localized(), arguments: [config.maximumSelectPhotoCount])
                    canSelect = false
                }
            }
        }
        if !canSelect {
            HXPHProgressHUD.showWarningHUD(addedTo: view, text: text!, afterDelay: 0, animated: true)
            HXPHProgressHUD.hideHUD(forView: view, animated: true, afterDelay: 2)
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
            }
        }else {
            for assetCollection in assetCollectionsArray {
                let hasChanges = resultHasChanges(for: changeInstance, assetCollection: assetCollection)
                if !needReload {
                    needReload = hasChanges;
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
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        print("\(self) deinit")
    }
}
/// 单独写个扩展，处理/获取数据
extension HXPHPickerController {
    
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
                if photoAsset.mediaType == HXPHAssetMediaType.photo {
                    if self.selectType == HXPHSelectType.video {
                        return
                    }
                    if self.config.showAnimatedAsset == true {
                        if HXPHAssetManager.assetIsAnimated(asset: photoAsset.asset!) {
                            photoAsset.mediaSubType = HXPHAssetMediaSubType.imageAnimated
                        }
                    }
                    if self.config.showLivePhotoAsset == true {
                        if HXPHAssetManager.assetIsLivePhoto(asset: photoAsset.asset!) {
                            photoAsset.mediaSubType = HXPHAssetMediaSubType.livePhoto
                        }
                    }
                }else if photoAsset.mediaType == HXPHAssetMediaType.video {
                    if self.selectType == HXPHSelectType.photo {
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
}

class HXPHDeniedAuthorizationView: UIView {
    
    var config: HXPHNotAuthorizedConfiguration?
    
    lazy var closeBtn: UIButton = {
        let closeBtn = UIButton.init(type: UIButton.ButtonType.custom)
        closeBtn.addTarget(self, action: #selector(didCloseClick), for: UIControl.Event.touchUpInside)
        return closeBtn
    }()
    
    lazy var titleLb: UILabel = {
        let titleLb = UILabel.init()
        titleLb.textAlignment = NSTextAlignment.center
        titleLb.numberOfLines = 0
        return titleLb
    }()
    
    lazy var subTitleLb: UILabel = {
        let subTitleLb = UILabel.init()
        subTitleLb.textAlignment = NSTextAlignment.center
        subTitleLb.numberOfLines = 0
        return subTitleLb
    }()
    
    lazy var jumpBtn: UIButton = {
        let jumpBtn = UIButton.init(type: UIButton.ButtonType.custom)
        jumpBtn.layer.cornerRadius = 5
        jumpBtn.addTarget(self, action: #selector(jumpSetting), for: UIControl.Event.touchUpInside)
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
        backgroundColor = config?.backgroudColor
        closeBtn.setTitle("X", for: UIControl.State.normal)
        closeBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        
        titleLb.text = "无法访问相册中照片".hx_localized()
        titleLb.textColor = config?.titleColor
        titleLb.font = UIFont.hx_semiboldPingFang(size: 20)
        
        subTitleLb.text = "当前无照片访问权限，建议前往系统设置，\n允许访问「照片」中的「所有照片」。".hx_localized()
        subTitleLb.textColor = config?.subTitleColor
        subTitleLb.font = UIFont.hx_regularPingFang(size: 17)
        
        jumpBtn.backgroundColor =  config?.jumpButtonBackgroudColor
        jumpBtn.setTitle("前往系统设置".hx_localized(), for: UIControl.State.normal)
        jumpBtn.setTitleColor(config?.jumpButtonTitleColor, for: UIControl.State.normal)
        jumpBtn.titleLabel?.font = UIFont.hx_mediumPingFang(size: 16)
    }
    @objc func didCloseClick() {
        self.hx_viewController()?.dismiss(animated: true, completion: nil)
    }
    @objc func jumpSetting() {
        HXPHTools.openSettingsURL()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        closeBtn.frame = CGRect(x: 20, y: UIDevice.hx_statusBarHeight() + 5, width: 40, height: 40)
        
        let titleHeight = titleLb.text?.hx_stringHeight(ofFont: titleLb.font, maxWidth: hx_width) ?? 0
        titleLb.frame = CGRect(x: 0, y: 0, width: hx_width, height: titleHeight)
        
        let subTitleHeight = subTitleLb.text?.hx_stringHeight(ofFont: subTitleLb.font, maxWidth: hx_width - 40) ?? 0
        subTitleLb.frame = CGRect(x: 20, y: hx_height / 2 - subTitleHeight - 30 - UIDevice.hx_topMargin(), width: hx_width - 40, height: subTitleHeight)
        titleLb.hx_y = subTitleLb.hx_y - 15 - titleHeight
        
        let jumpBtnBottomMargin : CGFloat = UIDevice.isProxy() ? 120 : 50
        jumpBtn.frame = CGRect(x: 0, y: hx_height - UIDevice.hx_bottomMargin() - 40 - jumpBtnBottomMargin, width: 150, height: 40)
        jumpBtn.hx_centerX = hx_width * 0.5
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
