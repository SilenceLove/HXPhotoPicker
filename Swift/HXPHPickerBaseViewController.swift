//
//  HXPHPickerBaseViewController.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/12/18.
//  Copyright © 2020 Silence. All rights reserved.
//


import UIKit
import Photos

class HXPHPickerBaseViewController: UIViewController , HXPHPickerControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDragDelegate, UICollectionViewDropDelegate, HXPHPickerBaseViewCellDelegate {
     
    @IBOutlet weak var collectionView: UICollectionView!
    /// 当前已选资源
    var selectedAssets: [HXPHAsset] = []
    /// 是否选中的原图
    var isOriginal: Bool = false
    /// 相机拍摄的本地资源
    var localCameraAssetArray: [HXPHAsset] = []
    /// 相关配置
    var config: HXPHConfiguration = HXPHTools.getWXConfig()
    init() {
        super.init(nibName:"HXPHPickerBaseViewController",bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(HXPHPickerBaseViewCell.self, forCellWithReuseIdentifier: "HXPHPickerBaseViewCellID")
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
        switch longGestureRecognizer.state {
        case .began:
            let touchPoint = longGestureRecognizer.location(in: collectionView)
            if let selectedIndexPath = collectionView.indexPathForItem(at: touchPoint) {
                collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
            }
            break
        case .changed:
            let touchPoint = longGestureRecognizer.location(in: collectionView)
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
    }
    @objc func didSettingButtonClick() {
        present(UINavigationController.init(rootViewController: ConfigurationViewController.init(config: config)), animated: true, completion: nil)
    }
    
    /// 跳转选择资源界面
    @IBAction func selectButtonClick(_ sender: UIButton) {
        let pickerController = HXPHPickerController.init(config: config)
        pickerController.pickerContollerDelegate = self
        pickerController.selectedAssetArray = selectedAssets
        pickerController.localCameraAssetArray = localCameraAssetArray
        pickerController.isOriginal = isOriginal
        present(pickerController, animated: true, completion: nil)
    }
    /// 获取已选资源的地址
    @IBAction func didRequestSelectedAssetURL(_ sender: Any) {
        let total = selectedAssets.count
        if total == 0 {
            return
        }
        var count = 0
        HXPHProgressHUD.showLoadingHUD(addedTo: self.navigationController?.view, text: "获取中", animated: true)
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
                            HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
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
                            HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
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
                        HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
                    }
                }
            }
        }
    }
    // MARK: HXPHPickerControllerDelegate
    func pickerContoller(_ pickerController: HXPHPickerController, didFinishWith selectedAssetArray: [HXPHAsset], _ isOriginal: Bool) {
        self.selectedAssets = selectedAssetArray
        self.isOriginal = isOriginal
        collectionView.reloadData()
    }
    
    func pickerContoller(_ pickerController: HXPHPickerController, singleFinishWith photoAsset:HXPHAsset, _ isOriginal: Bool) {
        selectedAssets = [photoAsset]
        self.isOriginal = isOriginal
        collectionView.reloadData()
    }
    func pickerContoller(_ pickerController: HXPHPickerController, didDismissWith localCameraAssetArray: [HXPHAsset]) {
        self.localCameraAssetArray = localCameraAssetArray
    }
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        selectedAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HXPHPickerBaseViewCellID", for: indexPath) as! HXPHPickerBaseViewCell
        cell.delegate = self
        cell.photoAsset = selectedAssets[indexPath.item]
        return cell
    }
    // MARK: HXPHPickerBaseViewCellDelegate
    func cell(didDeleteButton cell: HXPHPickerBaseViewCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            selectedAssets.remove(at: indexPath.item)
            collectionView.deleteItems(at: [indexPath])
        }
    }
    // MARK: UICollectionViewDelegate
    /// 跳转单独预览界面
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let pickerController = HXPHPickerController.init(preview: config)
        pickerController.selectedAssetArray = selectedAssets
        pickerController.previewIndex = indexPath.item
        pickerController.pickerContollerDelegate = self
        // 透明导航栏建议修改取消图片
//        config.previewView.cancelImageName = ""
//        pickerController.navigationBar.setBackgroundImage(UIImage.hx_image(for: UIColor.clear, havingSize: .zero), for: .default)
//        pickerController.navigationBar.shadowImage = UIImage.hx_image(for: UIColor.clear, havingSize: .zero)
        present(pickerController, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let sourceAsset = selectedAssets[sourceIndexPath.item]
        selectedAssets.remove(at: sourceIndexPath.item)
        selectedAssets.insert(sourceAsset, at: destinationIndexPath.item)
    }
    @available(iOS 11.0, *)
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let photoAsset = selectedAssets[indexPath.item]
        let itemProvider = NSItemProvider.init()
        let dragItem = UIDragItem.init(itemProvider: itemProvider)
        dragItem.localObject = photoAsset
        return [dragItem]
    }
    @available(iOS 11.0, *)
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return true
    }
    @available(iOS 11.0, *)
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
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
        // 重新设置 targetWidth
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
