//
//  BaseViewController.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/12/18.
//  Copyright © 2020 Silence. All rights reserved.
//


import UIKit
import Photos

class BaseViewController: UIViewController , HXPHPickerControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDragDelegate, UICollectionViewDropDelegate, HXPHPickerBaseViewCellDelegate {
     
    @IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var addCell: HXPHPickerBaseAddViewCell {
        get {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HXPHPickerBaseAddViewCellID", for: IndexPath(item: selectedAssets.count, section: 0)) as! HXPHPickerBaseAddViewCell
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
    var selectedAssets: [HXPHAsset] = []
    /// 是否选中的原图
    var isOriginal: Bool = false
    /// 相机拍摄的本地资源
    var localCameraAssetArray: [HXPHAsset] = []
    /// 相关配置
    var config: HXPHConfiguration = HXPHTools.getWXConfig()
    init() {
        super.init(nibName:"BaseViewController",bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        config.albumList.customCellClass = HXAlbumViewCustomCell.self
//        config.photoList.cell.customSingleCellClass = HXPHPickerViewCustomCell.self
//        config.photoList.cell.customMultipleCellClass = HXPHPickerMultiSelectViewCustomCell.self
        collectionViewTopConstraint.constant = 20
        collectionView.register(HXPHPickerBaseViewCell.self, forCellWithReuseIdentifier: "HXPHPickerBaseViewCellID")
        collectionView.register(HXPHPickerBaseAddViewCell.self, forCellWithReuseIdentifier: "HXPHPickerBaseAddViewCellID")
        if #available(iOS 11.0, *) {
            collectionView.dragDelegate = self
            collectionView.dropDelegate = self
            collectionView.dragInteractionEnabled = true
        }else {
            let longGestureRecognizer = UILongPressGestureRecognizer.init(target: self, action: #selector(longGestureRecognizerClick(longGestureRecognizer:)))
            collectionView.addGestureRecognizer(longGestureRecognizer)
        }
        view.backgroundColor = UIColor.white
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "设置", style:    .done, target: self, action: #selector(didSettingButtonClick))
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
        let itemWidth = Int((view.hx_width - 24 - 2) / 3)
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        configCollectionViewHeight()
    }
    func getCollectionViewrowCount() -> Int {
        let assetCount = canSetAddCell ? selectedAssets.count + 1 : selectedAssets.count
        var rowCount = Int(assetCount / 3) + 1
        if assetCount % 3 == 0 {
            rowCount -= 1
        }
        return rowCount
    }
    func configCollectionViewHeight() {
        let rowCount = getCollectionViewrowCount()
        beforeRowCount = rowCount
        let itemWidth = Int((view.hx_width - 24 - 2) / 3)
        var height = CGFloat(rowCount * itemWidth + rowCount)
        if height > view.hx_height - UIDevice.current.hx_navigationBarHeight - 20 - 150 {
            height = view.hx_height - UIDevice.current.hx_navigationBarHeight - 20 - 150
        }
        collectionViewHeightConstraint.constant = height
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
        present(UINavigationController.init(rootViewController: ConfigurationViewController.init(config: config)), animated: true, completion: nil)
    }
    
    /// 跳转选择资源界面
    @IBAction func selectButtonClick(_ sender: UIButton) {
        presentPickerController()
    }
    func presentPickerController() {
        let pickerController = HXPHPickerController.init(picker: config)
        pickerController.pickerControllerDelegate = self
        pickerController.selectedAssetArray = selectedAssets
        pickerController.localCameraAssetArray = localCameraAssetArray
        pickerController.isOriginal = isOriginal
        present(pickerController, animated: true, completion: nil)
    }
    /// 获取已选资源的地址
    @IBAction func didRequestSelectedAssetURL(_ sender: Any) {
        let total = selectedAssets.count
        if total == 0 {
            HXPHProgressHUD.showWarningHUD(addedTo: self.view, text: "请先选择资源", animated: true, delay: 1.5)
            return
        }
        var count = 0
        HXPHProgressHUD.showLoadingHUD(addedTo: self.view, text: "获取中", animated: true)
        weak var weakSelf = self
        for photoAsset in selectedAssets {
            if photoAsset.mediaType == .photo {
                if photoAsset.mediaSubType == .livePhoto {
                    var imageURL: URL?
                    var videoURL: URL?
                    HXPHAssetManager.requestLivePhoto(contentURL: photoAsset.asset!) { (url) in
                        imageURL = url
                    } videoHandler: { (url) in
                        videoURL = url
                    } completionHandler: { (error) in
                        count += 1
                        if error == nil {
                            let image = UIImage.init(contentsOfFile: imageURL!.path)
                            print("LivePhoto中的图片：\(String(describing: image!))")
                            print("LivePhoto中的视频地址：\(videoURL!)")
                        }else {
                            print("LivePhoto中的内容获取失败\(error!)")
                        }
                        if count == total {
                            HXPHProgressHUD.hideHUD(forView: weakSelf?.view, animated: false)
                            HXPHProgressHUD.showSuccessHUD(addedTo: weakSelf?.view, text: "获取完成", animated: true, delay: 1.5)
                        }
                    }
                }else {
                    count += 1
                    photoAsset.requestImageURL { (imageURL) in
                        if imageURL != nil {
                            print("图片地址：\(imageURL!)")
                        }else {
                            print("图片地址获取失败")
                        }
                        if count == total {
                            HXPHProgressHUD.hideHUD(forView: weakSelf?.view, animated: false)
                            HXPHProgressHUD.showSuccessHUD(addedTo: weakSelf?.view, text: "获取完成", animated: true, delay: 1.5)
                        }
                    }
//                    print("图片：\(photoAsset.originalImage!)")
//                    if count == total {
//                        HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
//                    }
                }
            }else {
                photoAsset.requestVideoURL { (videoURL) in
                    count += 1
                    if videoURL == nil {
                        print("视频地址获取失败")
                    }else {
                        print("视频地址：\(videoURL!)")
                    }
                    if count == total {
                        HXPHProgressHUD.hideHUD(forView: weakSelf?.view, animated: false)
                        HXPHProgressHUD.showSuccessHUD(addedTo: weakSelf?.view, text: "获取完成", animated: true, delay: 1.5)
                    }
                }
            }
        }
    }
    // MARK: HXPHPickerControllerDelegate
    func pickerController(_ pickerController: HXPHPickerController, didFinishWith selectedAssetArray: [HXPHAsset], _ isOriginal: Bool) {
        self.selectedAssets = selectedAssetArray
        self.isOriginal = isOriginal
        collectionView.reloadData()
        updateCollectionViewHeight()
    }
    func pickerController(_ pickerController: HXPHPickerController, singleFinishWith photoAsset:HXPHAsset, _ isOriginal: Bool) {
        selectedAssets = [photoAsset]
        self.isOriginal = isOriginal
        collectionView.reloadData()
        updateCollectionViewHeight()
    }
    func pickerController(didCancel pickerController: HXPHPickerController) {
        
    }
    func pickerController(_ pickerController: HXPHPickerController, didDismissWith localCameraAssetArray: [HXPHAsset]) {
        setNeedsStatusBarAppearanceUpdate()
        self.localCameraAssetArray = localCameraAssetArray
    }
    func pickerController(_ pickerController: HXPHPickerController, presentPreviewViewForIndexAt index: Int) -> UIView? {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
        return cell
    }
    func pickerController(_ pickerController: HXPHPickerController, presentPreviewImageForIndexAt index: Int) -> UIImage? {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as! HXPHPickerBaseViewCell
        return cell.imageView.image
    }
    func pickerController(_ pickerController: HXPHPickerController, dismissPreviewViewForIndexAt index: Int) -> UIView? {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
        return cell
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return canSetAddCell ? selectedAssets.count + 1 : selectedAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if canSetAddCell && indexPath.item == selectedAssets.count {
            return addCell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HXPHPickerBaseViewCellID", for: indexPath) as! HXPHPickerBaseViewCell
        cell.delegate = self
        cell.photoAsset = selectedAssets[indexPath.item]
        return cell
    }
    // MARK: HXPHPickerBaseViewCellDelegate
    func cell(didDeleteButton cell: HXPHPickerBaseViewCell) {
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
        // 预览时可以重新初始化一个config设置单独的颜色或其他配置
        // modalPresentationStyle = .custom 会使用框架自带的动画效果
        let pickerController = HXPHPickerController.init(preview: config, modalPresentationStyle: .custom)
        pickerController.selectedAssetArray = selectedAssets
        pickerController.previewIndex = indexPath.item
        pickerController.pickerControllerDelegate = self
        // 透明导航栏建议修改取消图片
//        config.previewView.cancelImageName = ""
//        pickerController.navigationBar.setBackgroundImage(UIImage.hx_image(for: UIColor.clear, havingSize: .zero), for: .default)
//        pickerController.navigationBar.shadowImage = UIImage.hx_image(for: UIColor.clear, havingSize: .zero)
        present(pickerController, animated: true, completion: nil)
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
class HXAlbumViewCustomCell: HXAlbumViewCell {
    override func layoutView() {
        super.layoutView()
        photoCountLb.hx_x += 100
    }
}
class HXPHPickerViewCustomCell: HXPHPickerViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = false
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func requestThumbnailImage() {
        imageView.image = UIImage.init(named: "hx_picker_add_img")
    }
}
class HXPHPickerMultiSelectViewCustomCell: HXPHPickerMultiSelectViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = false
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func requestThumbnailImage() {
        // 重写图片内容
        imageView.image = UIImage.init(named: "hx_picker_add_img")
    }
    override func didSelectControlClick(control: HXPHPickerCellSelectBoxControl) {
        // 重写选择框事件，也可以将选择框隐藏。自己新加一个选择框，然后触发代理回调
        delegate?.cell?(didSelectControl: self, isSelected: control.isSelected)
    }
    override func updateSelectedState(isSelected: Bool, animated: Bool) {
        // 重写更新选择的状态，如果是自定义的选择框需要在此设置选择框的选中状态
        super.updateSelectedState(isSelected: isSelected, animated: animated)
    }
    override func updateSelectControlSize(width: CGFloat, height: CGFloat) {
        // 重写更新选择框大小
        super.updateSelectControlSize(width: width, height: height)
    }
    override func layoutView() {
        // 重写布局
        super.layoutView()
    }
}
class HXPHPickerBaseAddViewCell: HXPHPickerViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = false
        imageView.image = UIImage.init(named: "hx_picker_add_img")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@objc protocol HXPHPickerBaseViewCellDelegate: NSObjectProtocol {
    @objc optional func cell(didDeleteButton cell: HXPHPickerBaseViewCell)
}

class HXPHPickerBaseViewCell: HXPHPickerViewCell {
    weak var delegate: HXPHPickerBaseViewCellDelegate?
    lazy var deleteButton: UIButton = {
        let deleteButton = UIButton.init(type: .custom)
        deleteButton.setImage(UIImage.init(named: "hx_compose_delete"), for: .normal)
        deleteButton.hx_size = deleteButton.currentImage?.size ?? .zero
        deleteButton.addTarget(self, action: #selector(didDeleteButtonClick), for: .touchUpInside)
        return deleteButton
    }()
    override func requestThumbnailImage() {
        // 因为这里的cell不会很多，重新设置 targetWidth，使图片更加清晰
        weak var weakSelf = self
        requestID = photoAsset?.requestThumbnailImage(targetWidth: hx_width * UIScreen.main.scale, completion: { (image, photoAsset, info) in
            if photoAsset == weakSelf?.photoAsset && image != nil {
                weakSelf?.imageView.image = image
                if !HXPHAssetManager.assetDownloadIsDegraded(for: info) {
                    weakSelf?.requestID = nil
                }
            }
        })
    }
    @objc func didDeleteButtonClick() {
        delegate?.cell?(didDeleteButton: self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 默认是隐藏的，需要显示出来
        isHidden = false
        contentView.addSubview(deleteButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        deleteButton.hx_x = hx_width - deleteButton.hx_width
    }
}
