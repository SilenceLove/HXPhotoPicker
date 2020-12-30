//
//  HXPHPreviewViewController.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

protocol HXPHPreviewViewControllerDelegate: NSObjectProtocol {
    func previewViewController(_ previewController: HXPHPreviewViewController, didOriginalButton isOriginal: Bool)
    func previewViewController(_ previewController: HXPHPreviewViewController, didSelectBox photoAsset: HXPHAsset, isSelected: Bool)
}

public class HXPHPreviewViewController: UIViewController {
    
    weak var delegate: HXPHPreviewViewControllerDelegate?
    var config : HXPHPreviewViewConfiguration!
    var currentPreviewIndex : Int = 0
    var orientationDidChange : Bool = false
    var statusBarShouldBeHidden : Bool = false
    var previewAssets : [HXPHAsset] = []
    var videoLoadSingleCell = false
    var viewDidAppear: Bool = false
    var firstLayoutSubviews: Bool = true
    var interactiveTransition: HXPHPickerInteractiveTransition?
    lazy var selectBoxControl: HXPHPickerSelectBoxView = {
        let boxControl = HXPHPickerSelectBoxView.init(frame: CGRect(x: 0, y: 0, width: config.selectBox.size.width, height: config.selectBox.size.height))
        boxControl.backgroundColor = .clear
        boxControl.config = config.selectBox
        boxControl.addTarget(self, action: #selector(didSelectBoxControlClick), for: UIControl.Event.touchUpInside)
        return boxControl
    }()
    
    
    lazy var collectionViewLayout : UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        return layout
    }()
    
    lazy var collectionView : UICollectionView = {
        let collectionView = UICollectionView.init(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
            self.automaticallyAdjustsScrollViewInsets = false
        }
        collectionView.register(HXPHPreviewPhotoViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPreviewPhotoViewCell.self))
        collectionView.register(HXPHPreviewLivePhotoViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPreviewLivePhotoViewCell.self))
        collectionView.register(HXPHPreviewVideoViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPreviewVideoViewCell.self))
        return collectionView
    }()
    var isExternalPreview: Bool = false
    var isMultipleSelect : Bool = false
    var allowLoadPhotoLibrary: Bool = true
    lazy var bottomView : HXPHPickerBottomView = {
        let bottomView = HXPHPickerBottomView.init(config: config.bottomView, allowLoadPhotoLibrary: allowLoadPhotoLibrary, isMultipleSelect: isMultipleSelect, isPreview: true, isExternalPreview: isExternalPreview) 
        bottomView.hx_delegate = self
        if config.bottomView.showSelectedView && (isMultipleSelect || isExternalPreview) {
            bottomView.selectedView.reloadData(photoAssets: pickerController!.selectedAssetArray)
        }
        if !isExternalPreview {
            bottomView.boxControl.isSelected = pickerController!.isOriginal
            bottomView.requestAssetBytes()
        }
        return bottomView
    }()
    var requestPreviewTimer: Timer?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let margin : CGFloat = 20
        let itemWidth = view.width + margin;
        collectionViewLayout.minimumLineSpacing = margin
        collectionViewLayout.itemSize = view.size
        let contentWidth = (view.width + itemWidth) * CGFloat(previewAssets.count)
        collectionView.frame = CGRect(x: -(margin * 0.5), y: 0, width: itemWidth, height: view.height)
        collectionView.contentSize = CGSize(width: contentWidth, height: view.height)
        collectionView.setContentOffset(CGPoint(x: CGFloat(currentPreviewIndex) * itemWidth, y: 0), animated: false)
        DispatchQueue.main.async {
            if self.orientationDidChange {
                let cell = self.getCell(for: self.currentPreviewIndex)
                cell?.setupScrollViewContenSize()
                self.orientationDidChange = false
            }
        }
        configBottomViewFrame()
        if firstLayoutSubviews {
            if !previewAssets.isEmpty && config.bottomView.showSelectedView && (isMultipleSelect || isExternalPreview) {
                DispatchQueue.main.async {
                    self.bottomView.selectedView.scrollTo(photoAsset: self.previewAssets[self.currentPreviewIndex], isAnimated: false)
                }
            }
            firstLayoutSubviews = false
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        isMultipleSelect = pickerController?.config.selectMode == .multiple
        allowLoadPhotoLibrary = pickerController?.config.allowLoadPhotoLibrary ?? true
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        view.clipsToBounds = true
        config = pickerController!.config.previewView
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationChanged(notify:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        initView()
        if pickerController?.modalPresentationStyle == .fullScreen {
            interactiveTransition = HXPHPickerInteractiveTransition.init(panGestureRecognizerFor: self, type: .pop)
        }
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppear = true
        let cell = getCell(for: currentPreviewIndex)
        cell?.requestPreviewAsset()
    }
    public override var prefersStatusBarHidden: Bool {
        return statusBarShouldBeHidden
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return pickerController?.config.statusBarStyle ?? .default
    }
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) && viewDidAppear {
                configColor()
            }
        }
    }
     
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: Function
extension HXPHPreviewViewController {
     
    func initView() {
        view.addSubview(collectionView)
        view.addSubview(bottomView)
        bottomView.updateFinishButtonTitle()
        if isMultipleSelect || isExternalPreview {
            if !pickerController!.config.allowSelectedTogether && pickerController!.config.maximumSelectedVideoCount == 1 &&
                pickerController!.config.selectType == .any{
                videoLoadSingleCell = true
            }
            if !isExternalPreview {
                navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: selectBoxControl)
            }else {
                var cancelItem: UIBarButtonItem
                if config.cancelType == .image {
                    let isDark = HXPHManager.shared.isDark
                    cancelItem = UIBarButtonItem.init(image: UIImage.image(for: isDark ? config.cancelDarkImageName : config.cancelImageName), style: .done, target: self, action: #selector(didCancelItemClick))
                }else {
                    cancelItem = UIBarButtonItem.init(title: "取消".localized, style: .done, target: self, action: #selector(didCancelItemClick))
                }
                if config.cancelPosition == .left {
                    navigationItem.leftBarButtonItem = cancelItem
                }else {
                    navigationItem.rightBarButtonItem = cancelItem
                }
            }
            if !previewAssets.isEmpty {
                if currentPreviewIndex == 0  {
                    let photoAsset = previewAssets.first!
                    if config.bottomView.showSelectedView {
                        bottomView.selectedView.scrollTo(photoAsset: photoAsset)
                    }
                    if !isExternalPreview {
                        if photoAsset.mediaType == .video && videoLoadSingleCell {
                            selectBoxControl.isHidden = true
                        }else {
                            updateSelectBox(photoAsset.isSelected, photoAsset: photoAsset)
                            selectBoxControl.isSelected = photoAsset.isSelected
                        }
                    }
                }
            }
        }
    }
    func configBottomViewFrame() {
        var bottomHeight: CGFloat
        if isExternalPreview {
            bottomHeight = (pickerController?.selectedAssetArray.isEmpty ?? true) ? 0 : UIDevice.current.bottomMargin + 70
            if !config.bottomView.showSelectedView && config.bottomView.editButtonHidden {
                if config.bottomView.editButtonHidden {
                    bottomHeight = 0
                }else {
                    bottomHeight = UIDevice.current.bottomMargin + 50
                }
            }
        }else {
            bottomHeight = pickerController?.selectedAssetArray.isEmpty ?? true ? 50 + UIDevice.current.bottomMargin : 50 + UIDevice.current.bottomMargin + 70
            if !config.bottomView.showSelectedView || !isMultipleSelect {
                bottomHeight = 50 + UIDevice.current.bottomMargin
            }
        }
        bottomView.frame = CGRect(x: 0, y: view.height - bottomHeight, width: view.width, height: bottomHeight)
    }
    func configColor() {
        view.backgroundColor = HXPHManager.shared.isDark ? config.backgroundDarkColor : config.backgroundColor
    }
    func getCell(for item: Int) -> HXPHPreviewViewCell? {
        if previewAssets.isEmpty {
            return nil
        }
        let cell = self.collectionView.cellForItem(at: IndexPath.init(item: item, section: 0)) as? HXPHPreviewViewCell
        return cell
    }
    func setCurrentCellImage(image: UIImage?) {
        if image != nil {
            if let cell = getCell(for: currentPreviewIndex) {
                if cell.photoAsset?.mediaSubType != .imageAnimated {
                    cell.cancelRequest()
                    cell.scrollContentView?.imageView.image = image
                }
            }
        }
    }
    func deleteCurrentPhotoAsset() {
        if previewAssets.isEmpty || !isExternalPreview {
            return
        }
        let photoAsset = previewAssets[currentPreviewIndex]
        if let shouldDelete = pickerController?.previewShouldDeleteAsset(photoAsset: photoAsset, index: currentPreviewIndex), !shouldDelete {
            return
        }
        previewAssets.remove(at: currentPreviewIndex)
        collectionView.deleteItems(at: [IndexPath.init(item: currentPreviewIndex, section: 0)])
        bottomView.selectedView.removePhotoAsset(photoAsset: photoAsset)
        pickerController?.previewDidDeleteAsset(photoAsset: photoAsset, index: currentPreviewIndex)
        if previewAssets.isEmpty {
            didCancelItemClick()
            return
        }
        scrollViewDidScroll(collectionView)
        setupRequestPreviewTimer()
    }
    func addedCameraPhotoAsset(_ photoAsset: HXPHAsset) {
        previewAssets.insert(photoAsset, at: currentPreviewIndex)
        collectionView.insertItems(at: [IndexPath.init(item: currentPreviewIndex, section: 0)])
    }
}
// MARK: Action
extension HXPHPreviewViewController {
    
    @objc func didCancelItemClick() {
        pickerController?.cancelCallback()
        dismiss(animated: true, completion: nil)
    }
    @objc func didSelectBoxControlClick() {
        let isSelected = !selectBoxControl.isSelected
        let photoAsset = previewAssets[currentPreviewIndex]
        var canUpdate = false
        var bottomNeedAnimated = false
        let beforeIsEmpty = pickerController!.selectedAssetArray.isEmpty
        if isSelected {
            // 选中
            if pickerController!.addedPhotoAsset(photoAsset: photoAsset) {
                canUpdate = true
                if config.bottomView.showSelectedView && isMultipleSelect {
                    bottomView.selectedView.insertPhotoAsset(photoAsset: photoAsset)
                }
                if beforeIsEmpty {
                    bottomNeedAnimated = true
                }
            }
        }else {
            // 取消选中
            _ = pickerController?.removePhotoAsset(photoAsset: photoAsset)
            if !beforeIsEmpty && pickerController!.selectedAssetArray.isEmpty {
                bottomNeedAnimated = true
            }
            if config.bottomView.showSelectedView && isMultipleSelect {
                bottomView.selectedView.removePhotoAsset(photoAsset: photoAsset)
            }
            canUpdate = true
        }
        if canUpdate {
            if config.bottomView.showSelectedView && isMultipleSelect {
                if bottomNeedAnimated {
                    UIView.animate(withDuration: 0.25) {
                        self.configBottomViewFrame()
                        self.bottomView.layoutSubviews()
                    }
                }else {
                    configBottomViewFrame()
                }
            }
            updateSelectBox(isSelected, photoAsset: photoAsset)
            selectBoxControl.isSelected = isSelected
            delegate?.previewViewController(self, didSelectBox: photoAsset, isSelected: isSelected)
            bottomView.updateFinishButtonTitle()
            selectBoxControl.layer.removeAnimation(forKey: "SelectControlAnimation")
            let keyAnimation = CAKeyframeAnimation.init(keyPath: "transform.scale")
            keyAnimation.duration = 0.3
            keyAnimation.values = [1.2, 0.8, 1.1, 0.9, 1.0]
            selectBoxControl.layer.add(keyAnimation, forKey: "SelectControlAnimation")
        }
    }
    
    func updateSelectBox(_ isSelected: Bool, photoAsset: HXPHAsset) {
        let boxWidth = config!.selectBox.size.width
        let boxHeight = config!.selectBox.size.height
        if isSelected {
            if config.selectBox.type == .number {
                let text = String(format: "%d", arguments: [photoAsset.selectIndex + 1])
                let font = UIFont.mediumPingFang(ofSize: config!.selectBox.titleFontSize)
                let textHeight = text.height(ofFont: font, maxWidth: boxWidth)
                var textWidth = text.width(ofFont: font, maxHeight: textHeight)
                selectBoxControl.textSize = CGSize(width: textWidth, height: textHeight)
                textWidth += boxHeight * 0.5
                if textWidth < boxWidth {
                    textWidth = boxWidth
                }
                selectBoxControl.text = text
                selectBoxControl.size = CGSize(width: textWidth, height: boxHeight)
            }else {
                selectBoxControl.size = CGSize(width: boxWidth, height: boxHeight)
            }
        }else {
            selectBoxControl.size = CGSize(width: boxWidth, height: boxHeight)
        }
    }
}

// MARK: UICollectionViewDataSource
extension HXPHPreviewViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return previewAssets.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photoAsset = previewAssets[indexPath.item]
        let cell: HXPHPreviewViewCell
        if photoAsset.mediaType == .photo {
            if photoAsset.mediaSubType == .livePhoto {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPreviewLivePhotoViewCell.self), for: indexPath) as! HXPHPreviewLivePhotoViewCell
            }else {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPreviewPhotoViewCell.self), for: indexPath) as! HXPHPreviewPhotoViewCell
            }
        }else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPreviewVideoViewCell.self), for: indexPath) as! HXPHPreviewVideoViewCell
            let videoCell = cell as! HXPHPreviewVideoViewCell
            videoCell.videoPlayType = config.videoPlayType
        }
        cell.photoAsset = photoAsset
        cell.delegate = self
        return cell
    }
}
// MARK: UICollectionViewDelegate
extension HXPHPreviewViewController: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let myCell = cell as! HXPHPreviewViewCell
        myCell.scrollContentView?.startAnimatedImage()
    }
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let myCell = cell as! HXPHPreviewViewCell
        myCell.cancelRequest()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != collectionView || orientationDidChange {
            return
        }
        let offsetX = scrollView.contentOffset.x  + (view.width + 20) * 0.5
        let viewWidth = view.width + 20
        var currentIndex = Int(offsetX / viewWidth)
        if currentIndex > previewAssets.count - 1 {
            currentIndex = previewAssets.count - 1
        }
        if currentIndex < 0 {
            currentIndex = 0
        }
        if !previewAssets.isEmpty {
            let photoAsset = previewAssets[currentIndex]
            if !isExternalPreview {
                if photoAsset.mediaType == .video && videoLoadSingleCell {
                    selectBoxControl.isHidden = true
                }else {
                    selectBoxControl.isHidden = false
                    updateSelectBox(photoAsset.isSelected, photoAsset: photoAsset)
                    selectBoxControl.isSelected = photoAsset.isSelected
                }
            }
            if !firstLayoutSubviews && config.bottomView.showSelectedView && (isMultipleSelect || isExternalPreview) {
                bottomView.selectedView.scrollTo(photoAsset: photoAsset)
            }
            if let pickerController = pickerController, !config.bottomView.editButtonHidden {
                if photoAsset.mediaType == .photo {
                    bottomView.editBtn.isEnabled = pickerController.config.allowEditPhoto
                }else if photoAsset.mediaType == .video {
                    bottomView.editBtn.isEnabled = pickerController.config.allowEditVideo
                }
            }
            pickerController?.previewUpdateCurrentlyDisplayedAsset(photoAsset: photoAsset, index: currentIndex)
        }
        self.currentPreviewIndex = currentIndex
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView != collectionView || orientationDidChange {
            return
        }
        let cell = getCell(for: currentPreviewIndex)
        cell?.requestPreviewAsset()
    }
}

// MARK: UINavigationControllerDelegate
extension HXPHPreviewViewController: UINavigationControllerDelegate{
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            if toVC is HXPHPreviewViewController && fromVC is HXPHPickerViewController {
                return HXPHPickerControllerTransition.init(type: .push)
            }
        }else if operation == .pop {
            if fromVC is HXPHPreviewViewController && toVC is HXPHPickerViewController {
                let cell = getCell(for: currentPreviewIndex)
                cell?.scrollContentView?.hiddenOtherSubview()
                return HXPHPickerControllerTransition.init(type: .pop)
            }
        }
        return nil
    }
    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if let canInteration = interactiveTransition?.canInteration, canInteration {
            return interactiveTransition
        }
        return nil
    }
}
// MARK: HXPHPreviewViewCellDelegate
extension HXPHPreviewViewController: HXPHPreviewViewCellDelegate {
    
    func singleTap() {
        if navigationController == nil {
            return
        }
        let isHidden = navigationController!.navigationBar.isHidden
        statusBarShouldBeHidden = !isHidden
        if self.modalPresentationStyle == .fullScreen {
            UIApplication.shared.setStatusBarHidden(statusBarShouldBeHidden, with: .fade)
            navigationController?.setNeedsStatusBarAppearanceUpdate()
        }
        navigationController!.setNavigationBarHidden(statusBarShouldBeHidden, animated: true)
        let currentCell = getCell(for: currentPreviewIndex)
        if !statusBarShouldBeHidden {
            self.bottomView.isHidden = false
            if currentCell?.photoAsset?.mediaType == .video {
                currentCell?.scrollContentView?.videoView.stopPlay()
            }
        }else {
            if currentCell?.photoAsset?.mediaType == .video {
                currentCell?.scrollContentView?.videoView.startPlay()
            }
        }
        UIView.animate(withDuration: 0.25) {
            self.bottomView.alpha = self.statusBarShouldBeHidden ? 0 : 1
        } completion: { (finish) in
            self.bottomView.isHidden = self.statusBarShouldBeHidden
        }

    }
}

// MARK: HXPHPickerBottomViewDelegate
extension HXPHPreviewViewController: HXPHPickerBottomViewDelegate {
    
    func bottomView(didEditButtonClick view: HXPHPickerBottomView) {
        let photoAsset = previewAssets[currentPreviewIndex]
        if let shouldEditAsset = pickerController?.shouldEditAsset(photoAsset: photoAsset) {
            if !shouldEditAsset {
                return
            }
        }
    }
    func bottomView(didFinishButtonClick view: HXPHPickerBottomView) {
        if previewAssets.isEmpty {
            HXPHProgressHUD.showWarningHUD(addedTo: self.view, text: "没有可选资源".localized, animated: true, delay: 2)
            return
        }
        let photoAsset = previewAssets[currentPreviewIndex]
        if pickerController!.config.selectMode == .multiple {
            if pickerController!.selectedAssetArray.isEmpty {
                _ = pickerController?.addedPhotoAsset(photoAsset: photoAsset)
            }
            pickerController?.finishCallback()
        }else {
            pickerController?.singleFinishCallback(for: photoAsset)
        }
    }
    func bottomView(didOriginalButtonClick view: HXPHPickerBottomView, with isOriginal: Bool) {
        delegate?.previewViewController(self, didOriginalButton: isOriginal)
        pickerController?.originalButtonCallback()
    }
    func bottomView(_ bottomView: HXPHPickerBottomView, didSelectedItemAt photoAsset: HXPHAsset) {
        if previewAssets.contains(photoAsset) {
            let index = previewAssets.firstIndex(of: photoAsset) ?? 0
            if index == currentPreviewIndex {
                return
            }
            getCell(for: currentPreviewIndex)?.cancelRequest()
            collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: false)
            setupRequestPreviewTimer()
            RunLoop.main.add(self.requestPreviewTimer!, forMode: RunLoop.Mode.common)
        }else {
            bottomView.selectedView.scrollTo(photoAsset: nil)
        }
    }
    func setupRequestPreviewTimer() {
        self.requestPreviewTimer?.invalidate()
        self.requestPreviewTimer = Timer(timeInterval: 0.2, target: self, selector:#selector(delayRequestPreview) , userInfo: nil, repeats: false)
        RunLoop.main.add(self.requestPreviewTimer!, forMode: RunLoop.Mode.common)
    }
    @objc func delayRequestPreview() {
        self.getCell(for: self.currentPreviewIndex)?.requestPreviewAsset()
        self.requestPreviewTimer = nil
    }
}

// MARK: Notification
extension HXPHPreviewViewController {
    
    @objc func deviceOrientationChanged(notify: Notification) {
        orientationDidChange = true
        let cell = getCell(for: currentPreviewIndex)
        if cell?.photoAsset?.mediaSubType == .livePhoto {
            if #available(iOS 9.1, *) {
                cell?.scrollContentView?.livePhotoView.stopPlayback()
            }
        }
        if config.bottomView.showSelectedView && (isMultipleSelect || isExternalPreview) {
            bottomView.selectedView.reloadSectionInset()
        }
    }
}
