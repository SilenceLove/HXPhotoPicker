//
//  PickerResultViewController.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/12/18.
//  Copyright © 2020 Silence. All rights reserved.
//


import UIKit
import Photos
import HXPHPicker
import Kingfisher

class PickerResultViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDragDelegate, UICollectionViewDropDelegate, ResultViewCellDelegate {
     
    @IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pickerStyleControl: UISegmentedControl!
    @IBOutlet weak var previewStyleControl: UISegmentedControl!
    
    var row_Count: Int = UI_USER_INTERFACE_IDIOM() == .pad ? 5 : 3
    
    var addCell: ResultAddViewCell {
        get {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ResultAddViewCellID", for: IndexPath(item: selectedAssets.count, section: 0)) as! ResultAddViewCell
            return cell
        }
    }
    var canSetAddCell: Bool {
        get {
            if selectedAssets.count == config.maximumSelectedCount && config.maximumSelectedCount > 0 {
                return false
            }
            return true
        }
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
    
    var localCachePath: String {
        var cachePath = PhotoTools.getSystemCacheFolderPath()
        cachePath.append(contentsOf: "/com.silence.WeChat_Moment")
        return cachePath
    }
    var localURL: URL {
        var cachePath = localCachePath
        cachePath.append(contentsOf: "/PhotoAssets")
        return URL.init(fileURLWithPath: cachePath)
    }
    
    weak var previewTitleLabel: UILabel?
    weak var currentPickerController: PhotoPickerController?
    init() {
        super.init(nibName:"PickerResultViewController",bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionViewTopConstraint.constant = 20
        collectionView.register(ResultViewCell.self, forCellWithReuseIdentifier: "ResultViewCellID")
        collectionView.register(ResultAddViewCell.self, forCellWithReuseIdentifier: "ResultAddViewCellID")
        if #available(iOS 11.0, *) {
            collectionView.dragDelegate = self
            collectionView.dropDelegate = self
            collectionView.dragInteractionEnabled = true
        }else {
            let longGestureRecognizer = UILongPressGestureRecognizer.init(target: self, action: #selector(longGestureRecognizerClick(longGestureRecognizer:)))
            collectionView.addGestureRecognizer(longGestureRecognizer)
        }
        view.backgroundColor = UIColor.white
        if isPublish {
            title = "Moment"
            let publishBtn = UIBarButtonItem.init(title: "发布", style:    .done, target: self, action: #selector(didPublishBtnClick))
            
            navigationItem.rightBarButtonItems = [publishBtn]
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .done, target: self, action: #selector(didCancelButtonClick))
            
            if let localData = FileManager.default.contents(atPath: localURL.path),
               let datas = try? JSONDecoder().decode([Data].self, from: localData) {
                var photoAssets: [PhotoAsset] = []
                for data in datas {
                    if let photoAsset = PhotoAsset.decoder(data: data) {
                        photoAssets.append(photoAsset)
                    }
                }
                selectedAssets = photoAssets
            }
        }else {
            let settingBtn = UIBarButtonItem.init(title: "设置", style:    .done, target: self, action: #selector(didSettingButtonClick))
            let clearBtn = UIBarButtonItem.init(title: "清空缓存", style:    .done, target: self, action: #selector(didClearButtonClick))
            
            navigationItem.rightBarButtonItems = [settingBtn, clearBtn]
        }
        
        if preselect {
            config.previewView.loadNetworkVideoMode = .play
            config.maximumSelectedVideoDuration = 0
            config.maximumSelectedVideoCount = 0
            let networkVideoURL = URL.init(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/picker_examle_video.mp4")!
            let networkVideoAsset = PhotoAsset.init(networkVideoAsset: .init(videoURL: networkVideoURL))
            selectedAssets.append(networkVideoAsset)
            localAssetArray.append(networkVideoAsset)
            
            #if canImport(Kingfisher)
            let networkImageURL = URL.init(string: "https://wx4.sinaimg.cn/large/a6a681ebgy1gojng2qw07g208c093qv6.gif")!
            let networkImageAsset = PhotoAsset.init(networkImageAsset: NetworkImageAsset.init(thumbnailURL: networkImageURL, originalURL: networkImageURL))
            selectedAssets.append(networkImageAsset)
            localAssetArray.append(networkImageAsset)
            #endif
            
            if let filePath = Bundle.main.path(forResource: "picker_example_gif_image", ofType: "GIF") {
                let gifAsset = PhotoAsset.init(localImageAsset: .init(imageURL: URL.init(fileURLWithPath: filePath)))
                selectedAssets.append(gifAsset)
                localAssetArray.append(gifAsset)
            }
            if let filePath = Bundle.main.path(forResource: "videoeditormatter", ofType: "MP4") {
                let videoAsset = PhotoAsset.init(localVideoAsset: .init(videoURL: URL.init(fileURLWithPath: filePath)))
                selectedAssets.append(videoAsset)
                localAssetArray.append(videoAsset)
            }
            
            let networkVideoURL1 = URL.init(string: "https://sf1-ttcdn-tos.pstatp.com/obj/tos-cn-v-0004/471d1136b00141f5a9ddf81e461547fd")!
            let networkVideoAsset1 = PhotoAsset.init(networkVideoAsset: .init(videoURL: networkVideoURL1))
            selectedAssets.append(networkVideoAsset1)
            localAssetArray.append(networkVideoAsset1)
        }
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
            break
        case .changed:
            if let selectedIndexPath = touchIndexPath {
                if canSetAddCell && selectedIndexPath.item == selectedAssets.count {
                    return
                }
            }
            collectionView.updateInteractiveMovementTargetPosition(touchPoint)
            break
        case .ended:
            collectionView.endInteractiveMovement()
            break
        default:
            collectionView.cancelInteractiveMovement()
            break
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
        if assetCount % 3 == 0 {
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
        present(UINavigationController.init(rootViewController: pickerConfigVC), animated: true, completion: nil)
    }
    @objc func didClearButtonClick() {
        PhotoTools.removeCache()
        ImageCache.default.clearCache()
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
        PhotoTools.showAlert(viewController: self, title: "是否将此次编辑保留?", message: nil, leftActionTitle: "不保留", leftHandler: { _ in
            self.removeLocalPhotoAssetFile()
            self.dismiss(animated: true, completion: nil)
        }, rightActionTitle: "保留") { _ in
            var datas: [Data] = []
            for photoAsset in self.selectedAssets {
                if let data = photoAsset.encode() {
                    datas.append(data)
                }
            }
            do {
                if !FileManager.default.fileExists(atPath: self.localCachePath) {
                    try FileManager.default.createDirectory(atPath: self.localCachePath, withIntermediateDirectories: true, attributes: nil)
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
        let pickerController = PhotoPickerController.init(picker: config)
        pickerController.pickerDelegate = self
        pickerController.selectedAssetArray = selectedAssets
        pickerController.localCameraAssetArray = localCameraAssetArray
        pickerController.isOriginal = isOriginal
        if pickerStyleControl.selectedSegmentIndex == 0 {
            pickerController.modalPresentationStyle = .fullScreen
        }
        pickerController.localAssetArray = localAssetArray
        pickerController.autoDismiss = false
        present(pickerController, animated: true, completion: nil)
    }
    /// 获取已选资源的地址
    @IBAction func didRequestSelectedAssetURL(_ sender: Any) {
        let total = selectedAssets.count
        if total == 0 {
            ProgressHUD.showWarning(addedTo: self.view, text: "请先选择资源", animated: true, delay: 1.5)
            return
        }
        ProgressHUD.showLoading(addedTo: self.view, animated: true)
        let result = PickerResult(photoAssets: selectedAssets, isOriginal: false)
        result.getURLs { result, photoAsset, index in
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
                break
            }
        } completionHandler: { urls in
            ProgressHUD.hide(forView: self.view, animated: false)
            ProgressHUD.showSuccess(addedTo: self.view, text: "获取完成", animated: true, delay: 1.5)
        }
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return canSetAddCell ? selectedAssets.count + 1 : selectedAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if canSetAddCell && indexPath.item == selectedAssets.count {
            return addCell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ResultViewCellID", for: indexPath) as! ResultViewCell
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
//        let config = VideoEditorConfiguration.init()
//        config.languageType = .english
//        let vc = EditorController.init(photoAsset: selectedAssets.first!, config: config)
////        vc.videoEditorDelegate = self
//        present(vc, animated: true, completion: nil)
//        return
        // modalPresentationStyle = .custom 会使用框架自带的动画效果
        // 预览时可以重新初始化一个config设置单独的颜色或其他配置
        let previewConfig = PhotoTools.getWXPickerConfig()
        if preselect {
            previewConfig.previewView.loadNetworkVideoMode = .play
        }
        // 编辑器配置保持一致
        previewConfig.photoEditor = config.photoEditor
        
        previewConfig.prefersStatusBarHidden = true
        previewConfig.previewView.showBottomView = false
        previewConfig.previewView.singleClickCellAutoPlayVideo = false
        previewConfig.previewView.customVideoCellClass = PreviewVideoControlViewCell.self
        previewConfig.previewView.bottomView.showSelectedView = false
        
        var style: UIModalPresentationStyle = .custom
        if previewStyleControl.selectedSegmentIndex == 1 {
            if #available(iOS 13.0, *) {
                style = .automatic
            }
        }
        let pickerController = PhotoPickerController.init(preview: previewConfig, currentIndex: indexPath.item, modalPresentationStyle: style)
        pickerController.selectedAssetArray = selectedAssets
        pickerController.pickerDelegate = self
        
        config.previewView.cancelImageName = ""
        pickerController.navigationBar.shadowImage = UIImage.image(for: UIColor.clear, havingSize: .zero)
        pickerController.navigationBar.barTintColor = .clear
        pickerController.navigationBar.backgroundColor = .clear
        
        let titleLabel = UILabel.init()
        titleLabel.size = CGSize(width: 100, height: 30)
        titleLabel.textColor = .white
        titleLabel.font = UIFont.semiboldPingFang(ofSize: 17)
        titleLabel.textAlignment = .center
        titleLabel.text = String(indexPath.item + 1) + "/" + String(selectedAssets.count)
        pickerController.previewViewController()?.navigationItem.titleView = titleLabel
        previewTitleLabel = titleLabel
        pickerController.previewViewController()?.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "删除", style: .done, target: self, action: #selector(deletePreviewAsset))
        present(pickerController, animated: true, completion: nil)
        self.currentPickerController = pickerController
    }
    @objc func deletePreviewAsset() {
        PhotoTools.showAlert(viewController: self.currentPickerController, title: "是否删除当前资源", message: nil, leftActionTitle: "确定", leftHandler: { (alertAction) in
            self.currentPickerController?.deleteCurrentPreviewPhotoAsset()
        }, rightActionTitle: "取消") { (alertAction) in
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        if canSetAddCell && indexPath.item == selectedAssets.count {
            return false
        }
        return true
    }
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let sourceAsset = selectedAssets[sourceIndexPath.item]
        selectedAssets.remove(at: sourceIndexPath.item)
        selectedAssets.insert(sourceAsset, at: destinationIndexPath.item)
    }
    @available(iOS 11.0, *)
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
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
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
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
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        if let destinationIndexPath = coordinator.destinationIndexPath, let sourceIndexPath = coordinator.items.first?.sourceIndexPath {
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
    
    func pickerController(_ pickerController: PhotoPickerController, didFinishSelection result: PickerResult) {
        selectedAssets = result.photoAssets
        isOriginal = result.isOriginal
        collectionView.reloadData()
        updateCollectionViewHeight()

//        result.getImage { (image, photoAsset, index) in
//            if let image = image {
//                print("success", image)
//            }else {
//                print("failed")
//            }
//        } completionHandler: { (images) in
//            print(images)
//        }
        pickerController.dismiss(animated: true, completion: nil)
    }
    
    func pickerController(_ pickerController: PhotoPickerController, didEditAsset photoAsset: PhotoAsset, atIndex: Int) {
        if pickerController.isPreviewAsset {
            selectedAssets[atIndex] = photoAsset
            collectionView.reloadItems(at: [IndexPath.init(item: atIndex, section: 0)])
        }
    }
    func pickerController(didCancel pickerController: PhotoPickerController) {
        pickerController.dismiss(animated: true, completion: nil)
    }
    func pickerController(_ pickerController: PhotoPickerController, didDismissComplete localCameraAssetArray: [PhotoAsset]) {
        setNeedsStatusBarAppearanceUpdate()
        self.localCameraAssetArray = localCameraAssetArray
    }
    func pickerController(_ pickerController: PhotoPickerController, viewControllersWillAppear viewController: UIViewController) {
        if pickerController.isPreviewAsset {
            let navHeight = viewController.navigationController?.navigationBar.height ?? 0
            viewController.navigationController?.navigationBar.setBackgroundImage(UIImage.gradualShadowImage(CGSize(width: view.width, height: UIDevice.isAllIPhoneX ? navHeight + 54 : navHeight + 30)), for: .default)
        }
    }
    func pickerController(_ pickerController: PhotoPickerController, previewUpdateCurrentlyDisplayedAsset photoAsset: PhotoAsset, atIndex: Int) {
        if pickerController.isPreviewAsset {
            previewTitleLabel?.text = String(atIndex + 1) + "/" + String(selectedAssets.count)
        }
    }
    func pickerController(_ pickerController: PhotoPickerController, previewSingleClick photoAsset: PhotoAsset, atIndex: Int) {
        if pickerController.isPreviewAsset && photoAsset.mediaType == .photo {
            pickerController.dismiss(animated: true, completion: nil)
        }
    }
    func pickerController(_ pickerController: PhotoPickerController, previewLongPressClick photoAsset: PhotoAsset, atIndex: Int) {
        if pickerController.isPreviewAsset {
            let alert = UIAlertController(title: "长按事件", message: nil, preferredStyle: .actionSheet)
            alert.addAction(.init(title: "保存", style: .default, handler: { alertAction in
                ProgressHUD.showLoading(addedTo: pickerController.view, animated: true)
                func saveImage(_ image: UIImage) {
                    AssetManager.saveSystemAlbum(forImage: image) { phAsset in
                        if phAsset != nil {
                            ProgressHUD.showSuccess(addedTo: pickerController.view, text: "保存成功", animated: true, delay: 1.5)
                        }else {
                            ProgressHUD.showWarning(addedTo: pickerController.view, text: "保存失败", animated: true, delay: 1.5)
                        }
                    }
                }
                func saveVideo(_ videoURL: URL) {
                    AssetManager.saveSystemAlbum(forVideoURL: videoURL) { phAsset in
                        if phAsset != nil {
                            ProgressHUD.showSuccess(addedTo: pickerController.view, text: "保存成功", animated: true, delay: 1.5)
                        }else {
                            ProgressHUD.showWarning(addedTo: pickerController.view, text: "保存失败", animated: true, delay: 1.5)
                        }
                    }
                }
                photoAsset.getAssetURL { result in
                    switch result {
                    case .success(let response):
                        if response.mediaType == .photo {
                            if response.urlType == .network {
                                PhotoTools.downloadNetworkImage(with: response.url, options: [], completionHandler: { image in
                                    ProgressHUD.hide(forView: pickerController.view, animated: true)
                                    if let image = image {
                                        saveImage(image)
                                    }else {
                                        ProgressHUD.showWarning(addedTo: pickerController.view, text: "保存失败", animated: true, delay: 1.5)
                                    }
                                })
                            }else {
                                let image = UIImage(contentsOfFile: response.url.path)!
                                saveImage(image)
                            }
                        }else {
                            if response.urlType == .network {
                                PhotoManager.shared.downloadTask(with: response.url, progress: nil) { videoURL, error, _ in
                                    ProgressHUD.hide(forView: pickerController.view, animated: true)
                                    if let videoURL = videoURL {
                                        saveVideo(videoURL)
                                    }else {
                                        ProgressHUD.showWarning(addedTo: pickerController.view, text: "保存失败", animated: true, delay: 1.5)
                                    }
                                }
                            }else {
                                saveVideo(response.url)
                            }
                        }
                    case .failure(_):
                        ProgressHUD.hide(forView: pickerController.view, animated: true)
                        ProgressHUD.showWarning(addedTo: pickerController.view, text: "保存失败", animated: true, delay: 1.5)
                    }
                }
            }))
            alert.addAction(.init(title: "删除", style: .destructive, handler: { alertAction in
                pickerController.deleteCurrentPreviewPhotoAsset()
            }))
            alert.addAction(.init(title: "取消", style: .cancel, handler: nil))
            pickerController.present(alert, animated: true, completion: nil)
        }
    }
    func pickerController(_ pickerController: PhotoPickerController, previewDidDeleteAsset photoAsset: PhotoAsset, atIndex: Int) {
        let isFull = selectedAssets.count == config.maximumSelectedCount
        selectedAssets.remove(at: atIndex)
        if isFull {
            collectionView.reloadData()
        }else {
            collectionView.deleteItems(at: [IndexPath.init(item: atIndex, section: 0)])
        }
        updateCollectionViewHeight()
    }
    func pickerController(_ pickerController: PhotoPickerController, presentPreviewViewForIndexAt index: Int) -> UIView? {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
        return cell
    }
    func pickerController(_ pickerController: PhotoPickerController, presentPreviewImageForIndexAt index: Int) -> UIImage? {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ResultViewCell
        return cell?.imageView.image
    }
    func pickerController(_ pickerController: PhotoPickerController, dismissPreviewViewForIndexAt index: Int) -> UIView? {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
        return cell
    }
    
    func pickerController(_ pickerController: PhotoPickerController, previewNetworkImageDownloadSuccess photoAsset: PhotoAsset, atIndex: Int) {
        if pickerController.isPreviewAsset {
            let cell = collectionView.cellForItem(at: IndexPath(item: atIndex, section: 0)) as! ResultViewCell
            if cell.downloadStatus == .failed {
                cell.requestThumbnailImage()
            }
        }
    }
    func pickerController(_ pickerController: PhotoPickerController, loadTitleChartlet photoEditorViewController: PhotoEditorViewController, response: @escaping ([EditorChartlet]) -> Void) {
        // 模仿延迟加加载数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            var titles = PhotoTools.defaultTitleChartlet()
            let localTitleChartlet = EditorChartlet(image: UIImage(named: "hx_sticker_cover"))
            titles.append(localTitleChartlet)
            response(titles)
        }
    }
    func pickerController(_ pickerController: PhotoPickerController, loadChartletList photoEditorViewController: PhotoEditorViewController, titleChartlet: EditorChartlet, titleIndex: Int, response: @escaping (Int, [EditorChartlet]) -> Void) {
        if titleIndex == 0 {
            response(titleIndex, PhotoTools.defaultNetworkChartlet())
        }else {
            let chartlet1 = EditorChartlet(image: UIImage(named: "hx_sticker_chongya"))
            let chartlet2 = EditorChartlet(image: UIImage(named: "hx_sticker_haoxinqing"))
            let chartlet3 = EditorChartlet(image: UIImage(named: "hx_sticker_housailei"))
            let chartlet4 = EditorChartlet(image: UIImage(named: "hx_sticker_jintianfenkeai"))
            let chartlet5 = EditorChartlet(image: UIImage(named: "hx_sticker_keaibiaoq"))
            let chartlet6 = EditorChartlet(image: UIImage(named: "hx_sticker_kehaixing"))
            let chartlet7 = EditorChartlet(image: UIImage(named: "hx_sticker_saihong"))
            let chartlet8 = EditorChartlet(image: UIImage(named: "hx_sticker_wow"))
            let chartlet9 = EditorChartlet(image: UIImage(named: "hx_sticker_woxiangfazipai"))
            let chartlet10 = EditorChartlet(image: UIImage(named: "hx_sticker_xiaochuzhujiao"))
            let chartlet11 = EditorChartlet(image: UIImage(named: "hx_sticker_yuanqimanman"))
            let chartlet12 = EditorChartlet(image: UIImage(named: "hx_sticker_yuanqishaonv"))
            let chartlet13 = EditorChartlet(image: UIImage(named: "hx_sticker_zaizaijia"))
            response(titleIndex, [chartlet1, chartlet2, chartlet3, chartlet4, chartlet5, chartlet6, chartlet7, chartlet8, chartlet9, chartlet10, chartlet11, chartlet12, chartlet13])
        }
    }
    func pickerController(_ pickerController: PhotoPickerController, videoEditor videoEditorViewController: VideoEditorViewController, loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void) -> Bool {
        var musics: [VideoEditorMusicInfo] = []
        let audioUrl1 = Bundle.main.url(forResource: "天外来物", withExtension: "mp3")!
        let lyricUrl1 = Bundle.main.url(forResource: "天外来物", withExtension: nil)!
        let lrc1 = try! String(contentsOfFile: lyricUrl1.path)
        let music1 = VideoEditorMusicInfo.init(audioURL: audioUrl1,
                                               lrc: lrc1)
        musics.append(music1)
        let audioUrl2 = Bundle.main.url(forResource: "嘉宾", withExtension: "mp3")!
        let lyricUrl2 = Bundle.main.url(forResource: "嘉宾", withExtension: nil)!
        let lrc2 = try! String(contentsOfFile: lyricUrl2.path)
        let music2 = VideoEditorMusicInfo.init(audioURL: audioUrl2,
                                               lrc: lrc2)
        musics.append(music2)
        let audioUrl3 = Bundle.main.url(forResource: "少女的祈祷", withExtension: "mp3")!
        let lyricUrl3 = Bundle.main.url(forResource: "少女的祈祷", withExtension: nil)!
        let lrc3 = try! String(contentsOfFile: lyricUrl3.path)
        let music3 = VideoEditorMusicInfo.init(audioURL: audioUrl3,
                                               lrc: lrc3)
        musics.append(music3)
        let audioUrl4 = Bundle.main.url(forResource: "野孩子", withExtension: "mp3")!
        let lyricUrl4 = Bundle.main.url(forResource: "野孩子", withExtension: nil)!
        let lrc4 = try! String(contentsOfFile: lyricUrl4.path)
        let music4 = VideoEditorMusicInfo.init(audioURL: audioUrl4,
                                               lrc: lrc4)
        musics.append(music4)
        let audioUrl5 = Bundle.main.url(forResource: "无赖", withExtension: "mp3")!
        let lyricUrl5 = Bundle.main.url(forResource: "无赖", withExtension: nil)!
        let lrc5 = try! String(contentsOfFile: lyricUrl5.path)
        let music5 = VideoEditorMusicInfo.init(audioURL: audioUrl5,
                                               lrc: lrc5)
        musics.append(music5)
        let audioUrl6 = Bundle.main.url(forResource: "时光正好", withExtension: "mp3")!
        let lyricUrl6 = Bundle.main.url(forResource: "时光正好", withExtension: nil)!
        let lrc6 = try! String(contentsOfFile: lyricUrl6.path)
        let music6 = VideoEditorMusicInfo.init(audioURL: audioUrl6,
                                               lrc: lrc6)
        musics.append(music6)
        let audioUrl7 = Bundle.main.url(forResource: "世间美好与你环环相扣", withExtension: "mp3")!
        let lyricUrl7 = Bundle.main.url(forResource: "世间美好与你环环相扣", withExtension: nil)!
        let lrc7 = try! String(contentsOfFile: lyricUrl7.path)
        let music7 = VideoEditorMusicInfo.init(audioURL: audioUrl7,
                                               lrc: lrc7)
        musics.append(music7)
        let audioUrl8 = Bundle.main.url(forResource: "爱你", withExtension: "mp3")!
        let lyricUrl8 = Bundle.main.url(forResource: "爱你", withExtension: nil)!
        let lrc8 = try! String(contentsOfFile: lyricUrl8.path)
        let music8 = VideoEditorMusicInfo.init(audioURL: audioUrl8,
                                               lrc: lrc8)
        musics.append(music8)
        completionHandler(musics)
        return false
    }
}

class ResultAddViewCell: PhotoPickerBaseViewCell {
    override func initView() {
        super.initView()
        isHidden = false
        imageView.image = UIImage.image(for: "hx_picker_add_img")
    }
}

@objc protocol ResultViewCellDelegate: NSObjectProtocol {
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
            // 隐藏被编辑过的标示
            assetEditMarkIcon.isHidden = true
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
        // 默认是隐藏的，需要显示出来
        isHidden = false
        contentView.addSubview(deleteButton)
    }
    
    override func layoutView() {
        super.layoutView()
        deleteButton.x = width - deleteButton.width
    }
}
