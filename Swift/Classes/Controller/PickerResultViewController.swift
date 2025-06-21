//
//  PickerResultViewController.swift
//  HXPhotoPicker
//
//  Created by Silence on 2020/12/18.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos
import HXPhotoPicker
#if canImport(Kingfisher)
import Kingfisher
#endif
#if canImport(SDWebImage)
import SDWebImage
#endif

class PickerResultViewController: UIViewController,
                                  UICollectionViewDataSource,
                                  UICollectionViewDelegate,
                                  UICollectionViewDragDelegate,
                                  UICollectionViewDropDelegate,
                                  ResultViewCellDelegate {
     
    @IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pickerStyleControl: UISegmentedControl!
    @IBOutlet weak var previewStyleControl: UISegmentedControl!
    
    var row_Count: Int = UIDevice.current.userInterfaceIdiom == .pad ? 5 : 3
    
    var addCell: ResultAddViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ResultAddViewCellID",
            for: IndexPath(item: selectedAssets.count, section: 0)
        ) as! ResultAddViewCell
        return cell
    }
    var canSetAddCell: Bool {
        if selectedAssets.count == config.maximumSelectedCount &&
            config.maximumSelectedCount > 0 {
            return false
        }
        return true
    }
    var beforeRowCount: Int = 0
    
    /// 当前已选资源
    var selectedAssets: [PhotoAsset] = []
    /// 是否选中的原图
    var isOriginal: Bool = false
    /// 相机拍摄的本地资源
    var localCameraAssetArray: [PhotoAsset] = []
    /// 相关配置
    var config: PickerConfiguration = PhotoTools.getWXPickerConfig(isMoment: true)
    
    var localAssetArray: [PhotoAsset] = []
    
    var preselect: Bool = false
    var isPublish: Bool = false
    var isSplit: Bool = false
    
    var localCachePath: String {
        var cachePath = FileManager.cachesPath
        cachePath.append(contentsOf: "/com.silence.WeChat_Moment")
        return cachePath
    }
    var localURL: URL {
        var cachePath = localCachePath
        cachePath.append(contentsOf: "/PhotoAssets")
        return URL.init(fileURLWithPath: cachePath)
    }
    
    init() {
        super.init(
            nibName: "PickerResultViewController",
            bundle: nil
        )
    }
    
    #if OCEXAMPLE
    @objc
    init(assets: [SwiftPhotoAsset]) {
        var selectedAssets: [PhotoAsset] = []
        for asset in assets {
            selectedAssets.append(asset.photoAsset)
        }
        self.selectedAssets = selectedAssets
        super.init(
            nibName: "PickerResultViewController",
            bundle: nil
        )
    }
    #endif
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !selectedAssets.isEmpty, !isPublish {
            config.photoList.cameraCell.cameraImageName = "hx_picker_photoList_photograph"
        }
//        let bundle = Bundle(path: Bundle.main.path(forResource: "custom", ofType: "lproj")!)!
//        PhotoManager.shared.customLanguages = [.init(language: "en", bundle: bundle)]
//        config.languageType = .custom()
        loadFonts()
//        config.editor.buttonType = .top
        collectionViewTopConstraint.constant = 20
        collectionView.register(ResultViewCell.self, forCellWithReuseIdentifier: "ResultViewCellID")
        collectionView.register(ResultAddViewCell.self, forCellWithReuseIdentifier: "ResultAddViewCellID")
        if #available(iOS 11.0, *) {
            collectionView.dragDelegate = self
            collectionView.dropDelegate = self
            collectionView.dragInteractionEnabled = true
        }else {
            let longGestureRecognizer = UILongPressGestureRecognizer(
                target: self,
                action: #selector(
                    longGestureRecognizerClick(longGestureRecognizer:)
                )
            )
            collectionView.addGestureRecognizer(longGestureRecognizer)
        }
        view.backgroundColor = UIColor.white
        if isPublish {
            title = "Moment"
            let publishBtn = UIBarButtonItem(
                title: "发布",
                style: .done,
                target: self,
                action: #selector(didPublishBtnClick)
            )
            navigationItem.rightBarButtonItems = [publishBtn]
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "取消",
                style: .done,
                target: self,
                action: #selector(didCancelButtonClick)
            )
            
            if let localData = FileManager.default.contents(atPath: localURL.path),
               let datas = try? JSONDecoder().decode([Data].self, from: localData),
               let photoAssets = try? [PhotoAsset].decode(datas) {
                selectedAssets = photoAssets
            }
        }else {
            let settingBtn = UIBarButtonItem.init(
                title: "设置",
                style: .done,
                target: self,
                action: #selector(didSettingButtonClick)
            )
            let clearBtn = UIBarButtonItem.init(
                title: "清空缓存",
                style: .done,
                target: self,
                action: #selector(didClearButtonClick)
            )
            navigationItem.rightBarButtonItems = [settingBtn, clearBtn]
        }
        
        // swiftlint:disable line_length
        if preselect {
            config.pickerPresentStyle = .push(rightSwipe: .init(50))
            config.previewView.loadNetworkVideoMode = .play
            config.maximumSelectedVideoDuration = 0
            config.maximumSelectedVideoCount = 0
            let networkVideoURL = URL(
                string:
                    "https://vd4.bdstatic.com/mda-niumk6kecunfhcqw/sc/cae_h264/1664464908581666807/mda-niumk6kecunfhcqw.mp4?v_from_s=hkapp-haokan-nanjing&auth_key=1671876955-0-0-d5348c926143621c0bab7727cb920cb7&bcevod_channel=searchbox_feed&pd=1&cd=0&pt=3&logid=2755343050&vid=4949060647341250402&abtest=106570_1-106693_2&klogid=2755343050"
            )!
            let networkVideoAsset = PhotoAsset.init(networkVideoAsset: .init(videoURL: networkVideoURL))
            selectedAssets.append(networkVideoAsset)
            localAssetArray.append(networkVideoAsset)
            
            let networkImageURL = URL(string: "https://wx4.sinaimg.cn/large/a6a681ebgy1gojng2qw07g208c093qv6.gif")!
            let networkImageAsset = PhotoAsset(
                networkImageAsset: NetworkImageAsset(
                    thumbnailURL: networkImageURL,
                    originalURL: networkImageURL
                )
            )
            selectedAssets.append(networkImageAsset)
            localAssetArray.append(networkImageAsset)
            
            if let filePath = Bundle.main.path(forResource: "IMG_0168", ofType: "GIF") {
                let gifAsset = PhotoAsset.init(localImageAsset: .init(imageURL: URL.init(fileURLWithPath: filePath)))
                selectedAssets.append(gifAsset)
                localAssetArray.append(gifAsset)
            }
            if let filePath = Bundle.main.path(forResource: "videoeditormatter", ofType: "MP4") {
                let videoAsset = PhotoAsset.init(localVideoAsset: .init(videoURL: URL.init(fileURLWithPath: filePath)))
                selectedAssets.append(videoAsset)
                localAssetArray.append(videoAsset)
            }
            
            let networkVideoURL1 = URL(
                string:
                    "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/395826883-1-208.mp4"
            )!
            let networkVideoAsset1 = PhotoAsset.init(networkVideoAsset: .init(videoURL: networkVideoURL1))
            selectedAssets.append(networkVideoAsset1)
            localAssetArray.append(networkVideoAsset1)
            
            let livePhoto_image = Bundle.main.path(forResource: "livephoto_image", ofType: "jpeg")!
            let livePhoto_video = Bundle.main.path(forResource: "c81", ofType: "mp4")!
            let localLivePhotoAsset = PhotoAsset(
                localLivePhoto: .init(
                    imageURL: .init(fileURLWithPath: livePhoto_image),
                    videoURL: .init(fileURLWithPath: livePhoto_video),
                    imageIdentifier: "local_livePhoto_image_jpeg",
                    videoIdentifier: "local_livePhoto_video_mp4"
                )
            )
            selectedAssets.append(localLivePhotoAsset)
            localAssetArray.append(localLivePhotoAsset)
             
            let localLivePhotoAsset1 = PhotoAsset(
                localLivePhoto: .init(
                    imageURL: URL(string: "https://f7.baidu.com/it/u=500783997,1623136713&fm=222&app=108&f=PNG@s_0,w_800,h_1000,q_80,f_auto")!,
                    videoURL: URL(string: "https://vd3.bdstatic.com/mda-nadbjpk0hnxwyndu/720p/h264_delogo/1642148105214867253/mda-nadbjpk0hnxwyndu.mp4?v_from_s=hkapp-haokan-nanjing&auth_key=1671854745-0-0-fa941c9ac0a6fe5e56d7c6fd5739ff92&bcevod_channel=searchbox_feed&pd=1&cd=0&pt=3&logid=2145586357&vid=5423681428712102654&abtest=106570_1-106693_2&klogid=2145586357")!
                )
            )
            selectedAssets.append(localLivePhotoAsset1)
            localAssetArray.append(localLivePhotoAsset1)
            
            let networkImageAsset3 = PhotoAsset(NetworkImageAsset(
                thumbnailURL: URL(string: "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fup.enterdesk.com%2Fedpic%2Fc9%2F08%2F4a%2Fc9084a6750e3293e6aeaf981f653b734.jpg&refer=http%3A%2F%2Fup.enterdesk.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1674462223&t=22adb67d04d85fa543daeb2f49de3671")!,
                originalURL: URL(string: "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fup.enterdesk.com%2Fedpic_source%2F3d%2F42%2F3e%2F3d423e3cb05d7edc35c38e3173af2a0d.jpg&refer=http%3A%2F%2Fup.enterdesk.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1674462223&t=5ccb00c0328b8ba0d522ac2e17e3a7bd")!,
                thumbnailLoadMode: .alwaysThumbnail,
                originalLoadMode: .alwaysThumbnail
            ))
            selectedAssets.append(networkImageAsset3)
            localAssetArray.append(networkImageAsset3)
        }
        // swiftlint:enable line_length
    }
    
    func loadFonts() {
        var masks: [EditorConfiguration.CropSize.MaskType] = []
        if let path = Bundle.main.path(forResource: "love", ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            masks.append(.image(image))
        }
        if let path = Bundle.main.path(forResource: "love_text", ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            masks.append(.image(image))
        }
        if let path = Bundle.main.path(forResource: "stars", ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            masks.append(.image(image))
        }
        if let path = Bundle.main.path(forResource: "text", ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            masks.append(.image(image))
        }
        if let path = Bundle.main.path(forResource: "qiy", ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            masks.append(.image(image))
        }
        if let path = Bundle.main.path(forResource: "portrait", ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            masks.append(.image(image))
        }
        for family in UIFont.familyNames {
            if UIFont.fontNames(forFamilyName: family).contains("AppleSymbols") {
                masks.append(.text("🀚", .init(name: "AppleSymbols", size: 55)!))
                masks.append(.text("�", .init(name: "AppleSymbols", size: 55)!))
                masks.append(.text("🜯", .init(name: "AppleSymbols", size: 55)!))
                masks.append(.text("♚", .init(name: "AppleSymbols", size: 55)!))
                masks.append(.text("‬‬♞", .init(name: "AppleSymbols", size: 55)!))
                masks.append(.text("‬‬‬♜", .init(name: "AppleSymbols", size: 55)!))
                masks.append(.text("‬‬‬♨", .init(name: "AppleSymbols", size: 55)!))
                masks.append(.text("‬‬‬☚", .init(name: "AppleSymbols", size: 55)!))
                masks.append(.text("‬‬‬☛", .init(name: "AppleSymbols", size: 55)!))
                masks.append(.text("‬‬‬☁", .init(name: "AppleSymbols", size: 55)!))
                masks.append(.text("‬‬‬▚", .init(name: "AppleSymbols", size: 55)!))
                break
            }
        }
        masks.append(.text("‬‬‬Swift", UIFont.boldSystemFont(ofSize: 50)))
        masks.append(.text("‬‬‬HXPhotoPicker", UIFont.boldSystemFont(ofSize: 50)))
        config.editor.cropSize.maskList = masks
    }
    
    @objc func longGestureRecognizerClick(longGestureRecognizer: UILongPressGestureRecognizer) {
        let touchPoint = longGestureRecognizer.location(in: collectionView)
        let touchIndexPath = collectionView.indexPathForItem(at: touchPoint)
        switch longGestureRecognizer.state {
        case .began:
            if let selectedIndexPath = touchIndexPath {
                if canSetAddCell && selectedIndexPath.item == selectedAssets.count {
                    return
                }
                collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
            }
        case .changed:
            if let selectedIndexPath = touchIndexPath {
                if canSetAddCell && selectedIndexPath.item == selectedAssets.count {
                    return
                }
            }
            collectionView.updateInteractiveMovementTargetPosition(touchPoint)
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let flowLayout: UICollectionViewFlowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let itemWidth = Int((view.width - 24 - CGFloat(row_Count - 1))) / row_Count
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        configCollectionViewHeight()
    }
    func getCollectionViewrowCount() -> Int {
        let assetCount = canSetAddCell ? selectedAssets.count + 1 : selectedAssets.count
        var rowCount = assetCount / row_Count + 1
        if assetCount % row_Count == 0 {
            rowCount -= 1
        }
        return rowCount
    }
    func configCollectionViewHeight() {
        let rowCount = getCollectionViewrowCount()
        beforeRowCount = rowCount
        let itemWidth = Int((view.width - 24 - CGFloat(row_Count - 1))) / row_Count
        var heightConstraint = CGFloat(rowCount * itemWidth + rowCount)
        if heightConstraint > view.height - UIDevice.navigationBarHeight - 20 - 150 {
            heightConstraint = view.height - UIDevice.navigationBarHeight - 20 - 150
        }
        collectionViewHeightConstraint.constant = heightConstraint
    }
    func updateCollectionViewHeight() {
        let rowCount = getCollectionViewrowCount()
        if beforeRowCount == rowCount {
            return
        }
        UIView.animate(withDuration: 0.25) {
            self.configCollectionViewHeight()
            self.view.layoutIfNeeded()
        }
    }
    @objc func didSettingButtonClick() {
        let pickerConfigVC: PickerConfigurationViewController
        if #available(iOS 13.0, *) {
            pickerConfigVC = PickerConfigurationViewController(style: .insetGrouped)
        } else {
            pickerConfigVC = PickerConfigurationViewController(style: .grouped)
        }
        pickerConfigVC.showOpenPickerButton = false
        pickerConfigVC.config = config
        pickerConfigVC.isSplitAction = isSplit
        pickerConfigVC.didDoneHandler = { [weak self] in
            self?.config = $0
            self?.isSplit = $1
        }
        present(UINavigationController.init(rootViewController: pickerConfigVC), animated: true, completion: nil)
    }
    @objc func didClearButtonClick() {
        PhotoTools.removeCache()
        #if canImport(Kingfisher)
        ImageCache.default.clearCache()
        #endif
        #if canImport(SDWebImage)
        SDImageCache.shared.clear(with: .all)
        #endif
    }
    func removeLocalPhotoAssetFile() {
        if FileManager.default.fileExists(atPath: localURL.path) {
            try? FileManager.default.removeItem(at: localURL)
        }
    }
    @objc func didPublishBtnClick() {
        removeLocalPhotoAssetFile()
        dismiss(animated: true, completion: nil)
    }
    @objc func didCancelButtonClick() {
        if selectedAssets.isEmpty {
            removeLocalPhotoAssetFile()
            dismiss(animated: true, completion: nil)
            return
        }
        PhotoTools.showAlert(
            viewController: self,
            title: "是否将此次编辑保留?",
            message: nil,
            leftActionTitle: "不保留",
            leftHandler: { _ in
            self.removeLocalPhotoAssetFile()
            self.dismiss(animated: true, completion: nil)
        }, rightActionTitle: "保留") { _ in
            do {
                let datas = try self.selectedAssets.encode()
                if !FileManager.default.fileExists(atPath: self.localCachePath) {
                    try FileManager.default.createDirectory(
                        atPath: self.localCachePath,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
                if FileManager.default.fileExists(atPath: self.localURL.path) {
                    try FileManager.default.removeItem(at: self.localURL)
                }
                let data = try JSONEncoder().encode(datas)
                try data.write(to: self.localURL)
            } catch {
                print(error)
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    /// 跳转选择资源界面
    @IBAction func selectButtonClick(_ sender: UIButton) {
        presentPickerController()
    }
    func presentPickerController() {
        switch pickerStyleControl.selectedSegmentIndex {
        case 0:
            config.modalPresentationStyle = .fullScreen
            config.pickerPresentStyle = .present()
        case 1:
            config.modalPresentationStyle = .fullScreen
            config.pickerPresentStyle = .push()
        default:
            config.pickerPresentStyle = .present()
            if #available(iOS 13.0, *) {
                config.modalPresentationStyle = .automatic
            }
        }
        if UIDevice.isPad || isSplit {
            let picker = PhotoPickerController(splitPicker: config)
            picker.pickerDelegate = self
            picker.selectedAssetArray = selectedAssets
            picker.localCameraAssetArray = localCameraAssetArray
            picker.isOriginal = isOriginal
            picker.localAssetArray = localAssetArray
            picker.autoDismiss = false
            let split = PhotoSplitViewController(picker: picker)
            present(split, animated: true, completion: nil)
        }else {
            let pickerController = PhotoPickerController(picker: config)
            pickerController.pickerDelegate = self
            pickerController.selectedAssetArray = selectedAssets
            pickerController.localCameraAssetArray = localCameraAssetArray
            pickerController.isOriginal = isOriginal
            pickerController.localAssetArray = localAssetArray
            pickerController.autoDismiss = false
            present(pickerController, animated: true, completion: nil)
        }
    }
    /// 获取已选资源的地址
    @IBAction func didRequestSelectedAssetURL(_ sender: Any) {
        let total = selectedAssets.count
        if total == 0 {
            view.hx.showWarning(
                text: "请先选择资源",
                delayHide: 1.5,
                animated: true
            )
            return
        }
        view.hx.show(animated: true)
//        let compression = PhotoAsset.Compression(
//            imageCompressionQuality: 0.5,
//            videoExportParameter: .init(
//                preset: .ratio_960x540,
//                quality: 6
//            )
//        )
        if #available(iOS 13.0, *) {
            Task {
                for (index, selectedAsset) in selectedAssets.enumerated() {
                    do {
                        print("第" + String(index + 1) + "个")
                        let result: AssetURLResult = try await selectedAsset.object(nil)
                        if let livePhoto = result.livePhoto {
                            print("LivePhoto里的图片地址：", livePhoto.imageURL)
                            print("LivePhoto里的视频地址：", livePhoto.videoURL)
                        }else {
                            print(
                                result.urlType == .network ?
                                result.mediaType == .photo ?
                                "网络图片地址：" : "网络视频地址：" :
                                    result.mediaType == .photo ?
                                "本地图片地址" : "本地视频地址",
                                result.url
                            )
                        }
                    } catch {
                        print("地址获取失败: ", error)
                    }
                }
                view.hx.hide(animated: false)
                view.hx.showSuccess(text: "获取完成", delayHide: 1.5, animated: true)
            }
        } else {
            selectedAssets.getURLs(
                compression: nil,
                toFile: nil
            ) { result, photoAsset, index in
                print("第" + String(index + 1) + "个")
                switch result {
                case .success(let response):
                    if let livePhoto = response.livePhoto {
                        print("LivePhoto里的图片地址：", livePhoto.imageURL)
                        print("LivePhoto里的视频地址：", livePhoto.videoURL)
                        return
                    }
                    print(response.urlType == .network ?
                            response.mediaType == .photo ?
                                "网络图片地址：" : "网络视频地址：" :
                            response.mediaType == .photo ?
                                "本地图片地址" : "本地视频地址",
                          response.url)
                case .failure(let error):
                    print("地址获取失败", error)
                }
            } completionHandler: { urls in
                self.view.hx.hide(animated: false)
                self.view.hx.showSuccess(text: "获取完成", delayHide: 1.5, animated: true)
            }
        }
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
        return canSetAddCell ? selectedAssets.count + 1 : selectedAssets.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if canSetAddCell && indexPath.item == selectedAssets.count {
            return addCell
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ResultViewCellID",
            for: indexPath
        ) as! ResultViewCell
        cell.resultDelegate = self
        cell.photoAsset = selectedAssets[indexPath.item]
        return cell
    }
    // MARK: ResultViewCellDelegate
    func cell(didDeleteButton cell: ResultViewCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            let isFull = selectedAssets.count == config.maximumSelectedCount
            selectedAssets.remove(at: indexPath.item)
            if isFull {
                collectionView.reloadData()
            }else {
                collectionView.deleteItems(at: [indexPath])
            }
            updateCollectionViewHeight()
        }
    }
    // MARK: UICollectionViewDelegate
    /// 跳转单独预览界面
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if canSetAddCell && indexPath.item == selectedAssets.count {
            presentPickerController()
            return
        }
        if selectedAssets.isEmpty {
            return
        }
        var style: UIModalPresentationStyle = .custom
        if previewStyleControl.selectedSegmentIndex == 1 {
            if #available(iOS 13.0, *) {
                style = .automatic
            }
        }
        var config = HXPhotoPicker.PhotoBrowser.Configuration()
        config.showDelete = true
        config.modalPresentationStyle = style
        let cell = collectionView.cellForItem(at: indexPath) as? ResultViewCell
        HXPhotoPicker.PhotoBrowser.show(
            // 预览的资源数组
            selectedAssets,
            // 当前预览的位置
            pageIndex: indexPath.item,
            // 预览相关配置
            config: config,
            // 转场动画初始的 UIImage
            transitionalImage: cell?.photoView.image
        ) { index, _ in
            // 转场过渡时起始/结束时 对应的 UIView
            self.collectionView.cellForItem(
                at: IndexPath(
                    item: index,
                    section: 0
                )
            ) as? ResultViewCell
        } deleteAssetHandler: { index, photoAsset, photoBrowser in
            // 点击了删除按钮
            PhotoTools.showAlert(
                viewController: photoBrowser,
                title: "是否删除当前资源",
                leftActionTitle: "确定",
                leftHandler: { (alertAction) in
                    photoBrowser.deleteCurrentPreviewPhotoAsset()
                    self.previewDidDeleteAsset(
                        index: index
                    )
                }, rightActionTitle: "取消") { (alertAction) in }
        } longPressHandler: { index, photoAsset, photoBrowser in
            if photoAsset.mediaSubType.isLivePhoto {
                return
            }
            // 长按事件
            self.previewLongPressClick(
                photoAsset: photoAsset,
                photoBrowser: photoBrowser
            )
        }
    }
    
    func previewLongPressClick(photoAsset: PhotoAsset, photoBrowser: HXPhotoPicker.PhotoBrowser) {
        let alert = UIAlertController(title: "长按事件", message: nil, preferredStyle: .actionSheet)
        alert.addAction(
            .init(
                title: "保存",
                style: .default,
                handler: { alertAction in
            photoBrowser.view.hx.show(animated: true)
            photoAsset.saveToSystemAlbum { result in
                photoBrowser.view.hx.hide(animated: true)
                switch result {
                case .success:
                    photoBrowser.view.hx.showSuccess(text: "保存成功", delayHide: 1.5, animated: true)
                case .failure:
                    photoBrowser.view.hx.showWarning(text: "保存失败", delayHide: 1.5, animated: true)
                }
            }
        }))
        alert.addAction(
            .init(
                title: "删除",
                style: .destructive,
                handler: { [weak self] alertAction in
                    photoBrowser.deleteCurrentPreviewPhotoAsset()
                    if let index = photoBrowser.previewViewController?.currentPreviewIndex {
                        self?.previewDidDeleteAsset(index: index)
                    }
        }))
        alert.addAction(.init(title: "取消", style: .cancel, handler: nil))
        if UIDevice.isPad {
            let pop = alert.popoverPresentationController
            pop?.permittedArrowDirections = .any
            pop?.sourceView = photoBrowser.view
            pop?.sourceRect = CGRect(
                x: photoBrowser.view.width * 0.5,
                y: photoBrowser.view.height,
                width: 0,
                height: 0
            )
        }
        photoBrowser.presendAlert(alert)
    }
    
    func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        if canSetAddCell && indexPath.item == selectedAssets.count {
            return false
        }
        return true
    }
    func collectionView(
        _ collectionView: UICollectionView,
        moveItemAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath) {
        let sourceAsset = selectedAssets[sourceIndexPath.item]
        selectedAssets.remove(at: sourceIndexPath.item)
        selectedAssets.insert(sourceAsset, at: destinationIndexPath.item)
    }
    @available(iOS 11.0, *)
    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath) -> [UIDragItem] {
        let itemProvider = NSItemProvider.init()
        let dragItem = UIDragItem.init(itemProvider: itemProvider)
        dragItem.localObject = indexPath
        return [dragItem]
    }
    @available(iOS 11.0, *)
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        if let sourceIndexPath = session.items.first?.localObject as? IndexPath {
            if canSetAddCell && sourceIndexPath.item == selectedAssets.count {
                return false
            }
        }
        return true
    }
    @available(iOS 11.0, *)
    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath
            destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let sourceIndexPath = session.items.first?.localObject as? IndexPath {
            if canSetAddCell && sourceIndexPath.item == selectedAssets.count {
                return UICollectionViewDropProposal.init(operation: .forbidden, intent: .insertAtDestinationIndexPath)
            }
        }
        if destinationIndexPath != nil && canSetAddCell && destinationIndexPath!.item == selectedAssets.count {
            return UICollectionViewDropProposal.init(operation: .forbidden, intent: .insertAtDestinationIndexPath)
        }
        var dropProposal: UICollectionViewDropProposal
        if session.localDragSession != nil {
            dropProposal = UICollectionViewDropProposal.init(operation: .move, intent: .insertAtDestinationIndexPath)
        }else {
            dropProposal = UICollectionViewDropProposal.init(operation: .copy, intent: .insertAtDestinationIndexPath)
        }
        return dropProposal
    }
    
    @available(iOS 11.0, *)
    func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: UICollectionViewDropCoordinator) {
        if let destinationIndexPath = coordinator.destinationIndexPath,
           let sourceIndexPath = coordinator.items.first?.sourceIndexPath {
            collectionView.isUserInteractionEnabled = false
            collectionView.performBatchUpdates {
                let sourceAsset = selectedAssets[sourceIndexPath.item]
                selectedAssets.remove(at: sourceIndexPath.item)
                selectedAssets.insert(sourceAsset, at: destinationIndexPath.item)
                collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
            } completion: { (isFinish) in
                collectionView.isUserInteractionEnabled = true
            }
            if let dragItem = coordinator.items.first?.dragItem {
                coordinator.drop(dragItem, toItemAt: destinationIndexPath)
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}

// MARK: PhotoPickerControllerDelegate
extension PickerResultViewController: PhotoPickerControllerDelegate {
    
    func createEditorDocumentPath() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last! + "/hxphotopicker_editor"
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        shouldEditPhotoAsset photoAsset: PhotoAsset,
        editorConfig: EditorConfiguration,
        atIndex: Int
    ) -> EditorConfiguration? {
        if isPublish {
            var config = editorConfig
            createEditorDocumentPath()
            var fileName = "hxphotopicker_editor/"
            fileName += String.fileName(suffix: photoAsset.isGifAsset ? "gif" : "png")
            config.urlConfig = .init(fileName: fileName, type: .document)
            return config
        }
        return editorConfig
    }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        shouldEditVideoAsset videoAsset: PhotoAsset,
        editorConfig: EditorConfiguration,
        atIndex: Int
    ) -> EditorConfiguration? {
        if isPublish {
            var config = editorConfig
            createEditorDocumentPath()
            let fileName = "hxphotopicker_editor/" + String.fileName(suffix: "mp4")
            config.urlConfig = .init(fileName: fileName, type: .document)
            return config
        }
        return editorConfig
    }
    
    func pickerController(_ pickerController: PhotoPickerController, didFinishSelection result: PickerResult) {
        selectedAssets = result.photoAssets
        isOriginal = result.isOriginal
        collectionView.reloadData()
        updateCollectionViewHeight()
        
//        result.getURLs { urls in
//            print(urls)
//        }

//        result.getImage { (image, photoAsset, index) in
//            if let image = image {
//                print("success", image)
//            }else {
//                print("failed")
//            }
//        } completionHandler: { (images) in
//            print(images)
//        }
        pickerController.dismiss(true)
    }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        didEditAsset photoAsset: PhotoAsset, atIndex: Int
    ) {
        if pickerController.previewType == .picker {
            selectedAssets[atIndex] = photoAsset
            collectionView.reloadItems(at: [IndexPath.init(item: atIndex, section: 0)])
        }
    }
    func pickerController(didCancel pickerController: PhotoPickerController) {
        pickerController.dismiss(true)
    }
    func pickerController(
        _ pickerController: PhotoPickerController,
        didDismissComplete localCameraAssetArray: [PhotoAsset]) {
        setNeedsStatusBarAppearanceUpdate()
        self.localCameraAssetArray = localCameraAssetArray
    }
    func pickerController(
        _ pickerController: PhotoPickerController,
        viewControllersWillAppear viewController: UIViewController
    ) {
        if pickerController.previewType == .picker {
            let navHeight = viewController.navigationController?.navigationBar.height ?? 0
            viewController.navigationController?.navigationBar.setBackgroundImage(
                UIImage.gradualShadowImage(
                    CGSize(
                        width: view.width,
                        height: UIDevice.isAllIPhoneX ? navHeight + 54 : navHeight + 30
                    )
                ),
                for: .default
            )
        }
    }
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewDidDeleteAssets photoAssets: [PhotoAsset], at indexs: [Int]
    ) {
        guard let index = indexs.first else {
            return
        }
        previewDidDeleteAsset(index: index)
    }
    func previewDidDeleteAsset(index: Int) {
        let isFull = selectedAssets.count == config.maximumSelectedCount
        selectedAssets.remove(at: index)
        if isFull {
            collectionView.reloadData()
        }else {
            collectionView.deleteItems(at: [IndexPath.init(item: index, section: 0)])
        }
        updateCollectionViewHeight()
    }
    func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewViewForIndexAt index: Int) -> UIView? {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
        return cell
    }
    func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewImageForIndexAt index: Int) -> UIImage? {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ResultViewCell
        return cell?.photoView.image
    }
    func pickerController(
        _ pickerController: PhotoPickerController,
        dismissPreviewViewForIndexAt index: Int) -> UIView? {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
        return cell
    }
    
    func pickerController(
        _ pickerController: PhotoPickerController,
        previewNetworkImageDownloadSuccess photoAsset: PhotoAsset,
        atIndex: Int
    ) {
        if pickerController.previewType == .picker {
            let cell = collectionView.cellForItem(at: IndexPath(item: atIndex, section: 0)) as! ResultViewCell
            if cell.downloadStatus == .failed {
                cell.requestThumbnailImage()
            }
        }
    }
    func pickerController(
        _ pickerController: PhotoPickerController,
        loadTitleChartlet editorViewController: EditorViewController,
        response: @escaping ([EditorChartlet]) -> Void) {
        // 模仿延迟加加载数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            response(self.getChartletTitles())
        }
    }
    func getChartletTitles() -> [EditorChartlet] {
        var titles = PhotoTools.defaultTitleChartlet()
        let localTitleChartlet = EditorChartlet(image: UIImage(named: "hx_sticker_cover"))
        titles.append(localTitleChartlet)
        let gifTitleChartlet = EditorChartlet(
            url: URL(
                string:
                    "https://gifimage.net/wp-content/uploads/2017/11/gif-button-2.gif"
            )
        )
        titles.append(gifTitleChartlet)
        return titles
    }
    func pickerController(
        _ pickerController: PhotoPickerController,
        loadChartletList editorViewController: EditorViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        response: @escaping (Int, [EditorChartlet]) -> Void) {
        response(titleIndex, getChartletList(index: titleIndex))
    }
    func getChartletList(index: Int) -> [EditorChartlet] {
        if index == 0 {
            return PhotoTools.defaultNetworkChartlet()
        }else if index == 1 {
            let imageNameds = [
                "hx_sticker_haoxinqing",
                "hx_sticker_housailei",
                "hx_sticker_jintianfenkeai",
                "hx_sticker_keaibiaoq",
                "hx_sticker_kehaixing",
                "hx_sticker_saihong",
                "hx_sticker_wow",
                "hx_sticker_woxiangfazipai",
                "hx_sticker_xiaochuzhujiao",
                "hx_sticker_yuanqimanman",
                "hx_sticker_yuanqishaonv",
                "hx_sticker_zaizaijia"
            ]
            var list: [EditorChartlet] = []
            for imageNamed in imageNameds {
                let chartlet = EditorChartlet(
                    image: UIImage(
                        contentsOfFile: Bundle.main.path(
                            forResource: imageNamed,
                            ofType: "png"
                        )!
                    )
                )
                list.append(chartlet)
            }
            return list
        }else {
            return gifChartlet()
        }
    }
    func pickerController(
        _ pickerController: PhotoPickerController,
        videoEditor editorViewController: EditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void
    ) -> Bool {
        completionHandler(Tools.musicInfos)
        return false
    }
    
    func gifChartlet() -> [EditorChartlet] {
        var gifs: [EditorChartlet] = []
        gifs.append(.init(url: URL(string: "https://img95.699pic.com/photo/40112/1849.gif_wh860.gif")))
        gifs.append(.init(url: URL(string: "https://img95.699pic.com/photo/40112/1680.gif_wh860.gif")))
        gifs.append(.init(url: URL(string: "https://img95.699pic.com/photo/40110/3660.gif_wh860.gif")))
        gifs.append(.init(url: URL(string: "https://pic.qqtn.com/up/2017-10/2017102615224886590.gif")))
        gifs.append(.init(url: URL(string: "https://img.99danji.com/uploadfile/2021/0220/20210220103405450.gif")))
        gifs.append(.init(url: URL(string: "https://imgo.youxihezi.net/img2021/2/20/11/2021022051733236.gif")))
        gifs.append(
            .init(
                url: URL(
                    string:
                        "https://qqpublic.qpic.cn/qq_public/0/0-2868806511-17879434A38D4DCC1A378F9528C76152/0?fmt=gif&size=136&h=431&w=480&ppv=1.gif" // swiftlint:disable:this line_length
                )
            )
        )
        gifs.append(
            .init(
                url: URL(
                    string:
                        "http://qqpublic.qpic.cn/qq_public/0/0-464434317-3A491192B7B04D124C793264F3E7DAE4/0?fmt=gif&size=335&h=361&w=450&ppv=1.gif" // swiftlint:disable:this line_length
                )
            )
        )
        gifs.append(.init(url: URL(string: "http://pic.qqtn.com/up/2017-5/2017053118074857711.gif")))
        gifs.append(.init(url: URL(string: "https://pic.diydoutu.com/bq/1493.gif")))
        return gifs
    }
}

class ResultAddViewCell: PhotoPickerBaseViewCell {
    override func initView() {
        super.initView()
        isHidden = false
        photoView.placeholder = UIImage.image(for: "hx_picker_add_img")
    }
}

@objc protocol ResultViewCellDelegate: AnyObject {
    @objc optional func cell(didDeleteButton cell: ResultViewCell)
}

class ResultViewCell: PhotoPickerViewCell {
    weak var resultDelegate: ResultViewCellDelegate?
    lazy var deleteButton: UIButton = {
        let deleteButton = UIButton.init(type: .custom)
        deleteButton.setImage(UIImage.init(named: "hx_compose_delete"), for: .normal)
        deleteButton.size = deleteButton.currentImage?.size ?? .zero
        deleteButton.addTarget(self, action: #selector(didDeleteButtonClick), for: .touchUpInside)
        return deleteButton
    }()
    override var photoAsset: PhotoAsset! {
        didSet {
            if photoAsset.mediaType == .photo {
                if let photoEdit = photoAsset.photoEditedResult {
                    // 隐藏被编辑过的标示
                    assetEditMarkIcon.isHidden = true
                    assetTypeMaskView.isHidden = photoEdit.imageType != .gif
                }
            }
        }
    }
    override func requestThumbnailImage() {
        // 因为这里的cell不会很多，重新设置 targetWidth，使图片更加清晰
        super.requestThumbnailImage(targetWidth: width * UIScreen.main.scale)
    }
    @objc func didDeleteButtonClick() {
        resultDelegate?.cell?(didDeleteButton: self)
    }
    override func initView() {
        super.initView()
        contentView.addSubview(deleteButton)
    }
    
    override func setupState() {
        super.setupState()
        if photoAsset.mediaSubType.isLivePhoto {
            assetTypeLb.text = (photoAsset.isDisableLivePhoto || photoAsset.isEdited) ? nil : "Live"
        }
    }
    
    override func layoutView() {
        super.layoutView()
        deleteButton.x = width - deleteButton.width
    }
}
