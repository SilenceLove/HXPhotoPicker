//
//  HXPHPreviewViewController.swift
//  HXPHPickerExample
//
//  Created by 洪欣 on 2020/11/13.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit
import Photos

protocol HXPHPreviewViewControllerDelegate: NSObjectProtocol {
    func previewViewControllerDidClickOriginal(_ previewViewController:HXPHPreviewViewController, with isOriginal: Bool)
    func previewViewControllerDidClickSelectBox(_ previewViewController:HXPHPreviewViewController, with isSelected: Bool)
}

class HXPHPreviewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, HXPHPreviewViewCellDelegate, HXPHPickerBottomViewDelegate, UINavigationControllerDelegate, UIViewControllerTransitioningDelegate {
    
    weak var delegate: HXPHPreviewViewControllerDelegate?
    var config : HXPHPreviewViewConfiguration!
    var currentPreviewIndex : Int = 0
    var orientationDidChange : Bool = false
    var statusBarShouldBeHidden : Bool = false
    var previewAssets : [HXPHAsset] = []
    var videoLoadSingleCell = false
    var viewDidAppear: Bool = false
    var firstLayoutSubviews: Bool = true
    lazy var selectBoxControl: HXPHPickerCellSelectBoxControl = {
        let boxControl = HXPHPickerCellSelectBoxControl.init(frame: CGRect(x: 0, y: 0, width: config.selectBox.size.width, height: config.selectBox.size.height))
        boxControl.backgroundColor = .clear
        boxControl.config = config.selectBox
        boxControl.addTarget(self, action: #selector(didSelectBoxControlClick), for: UIControl.Event.touchUpInside)
        return boxControl
    }()
    @objc func didSelectBoxControlClick() {
        let isSelected = !selectBoxControl.isSelected
        let photoAsset = previewAssets[currentPreviewIndex]
        var canUpdate = false
        var bottomNeedAnimated = false
        let beforeIsEmpty = hx_pickerController!.selectedAssetArray.isEmpty
        if isSelected {
            // 选中
            if hx_pickerController!.addedPhotoAsset(photoAsset: photoAsset) {
                canUpdate = true
                bottomView.selectedView.insertPhotoAsset(photoAsset: photoAsset)
                if beforeIsEmpty {
                    bottomNeedAnimated = true
                }
            }
        }else {
            // 取消选中
            _ = hx_pickerController?.removePhotoAsset(photoAsset: photoAsset)
            if !beforeIsEmpty && hx_pickerController!.selectedAssetArray.isEmpty {
                bottomNeedAnimated = true
            }
            bottomView.selectedView.removePhotoAsset(photoAsset: photoAsset)
            canUpdate = true
        }
        if canUpdate {
            if bottomNeedAnimated {
                UIView.animate(withDuration: 0.25) {
                    self.configBottomViewFrame()
                    self.bottomView.layoutSubviews()
                }
            }else {
                configBottomViewFrame()
            }
            updateSelectBox(isSelected, photoAsset: photoAsset)
            selectBoxControl.isSelected = isSelected
            bottomView.updateFinishButtonTitle()
            delegate?.previewViewControllerDidClickSelectBox(self, with: isSelected)
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
                let font = UIFont.systemFont(ofSize: config!.selectBox.titleFontSize)
                let textHeight = text.hx_stringHeight(ofFont: font, maxWidth: boxWidth)
                var textWidth = text.hx_stringWidth(ofFont: font, maxHeight: textHeight)
                selectBoxControl.textSize = CGSize(width: textWidth, height: textHeight)
                textWidth += boxHeight * 0.5
                if textWidth < boxWidth {
                    textWidth = boxWidth
                }
                selectBoxControl.text = text
                selectBoxControl.hx_size = CGSize(width: textWidth, height: boxHeight)
            }else {
                selectBoxControl.hx_size = CGSize(width: boxWidth, height: boxHeight)
            }
        }else {
            selectBoxControl.hx_size = CGSize(width: boxWidth, height: boxHeight)
        }
    }
    
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
    
    lazy var bottomView : HXPHPickerBottomView = {
        let bottomView = HXPHPickerBottomView.init(config: config.bottomView)
        bottomView.hx_delegate = self
        bottomView.selectedView.reloadData(photoAssets: hx_pickerController!.selectedAssetArray)
        bottomView.boxControl.isSelected = hx_pickerController!.isOriginal
        return bottomView
    }()
    // MARK: HXPHPickerBottomViewDelegate
    func bottomViewDidPreviewButtonClick(view: HXPHPickerBottomView) {}
    func bottomViewDidFinishButtonClick(view: HXPHPickerBottomView) {
        if previewAssets.isEmpty {
            HXPHProgressHUD.showWarningHUD(addedTo: self.view, text: "没有可选资源".hx_localized, animated: true, delay: 2)
            return
        }
        let photoAsset = previewAssets[currentPreviewIndex]
        if hx_pickerController!.config.selectMode == .multiple {
            if hx_pickerController!.selectedAssetArray.isEmpty {
                _ = hx_pickerController?.addedPhotoAsset(photoAsset: photoAsset)
            }
            hx_pickerController?.finishCallback()
        }else {
            hx_pickerController?.singleFinishCallback(for: photoAsset)
        }
    }
    func bottomViewDidOriginalButtonClick(view: HXPHPickerBottomView, with isOriginal: Bool) {
        delegate?.previewViewControllerDidClickOriginal(self, with: isOriginal)
        hx_pickerController?.originalButtonCallback()
    }
    func bottomViewDidSelectedViewClick(_ bottomView: HXPHPickerBottomView, didSelectedItemAt photoAsset: HXPHAsset) {
        if previewAssets.contains(photoAsset) {
            let index = previewAssets.firstIndex(of: photoAsset) ?? 0
            if index == currentPreviewIndex {
                return
            }
            getCell(for: currentPreviewIndex)?.cancelRequest()
            collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: false)
            self.requestPreviewTimer?.invalidate()
            self.requestPreviewTimer = Timer(timeInterval: 0.2, target: self, selector:#selector(delayRequestPreview) , userInfo: nil, repeats: false)
            RunLoop.main.add(self.requestPreviewTimer!, forMode: RunLoop.Mode.common)
        }else {
            bottomView.selectedView.scrollTo(photoAsset: nil)
        }
    }
    @objc func delayRequestPreview() {
        self.getCell(for: self.currentPreviewIndex)?.requestPreviewAsset()
        self.requestPreviewTimer = nil
    }
    var requestPreviewTimer: Timer?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func configBottomViewFrame() {
        let bottomHeight = hx_pickerController!.selectedAssetArray.isEmpty ? 50 + UIDevice.current.hx_bottomMargin : 50 + UIDevice.current.hx_bottomMargin + 70
        bottomView.frame = CGRect(x: 0, y: view.hx_height - bottomHeight, width: view.hx_width, height: bottomHeight)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let margin : CGFloat = 20
        let itemWidth = view.hx_width + margin;
        collectionViewLayout.minimumLineSpacing = margin
        collectionViewLayout.itemSize = view.hx_size
        let contentWidth = (view.hx_width + itemWidth) * CGFloat(previewAssets.count)
        collectionView.frame = CGRect(x: -(margin * 0.5), y: 0, width: itemWidth, height: view.hx_height)
        collectionView.contentSize = CGSize(width: contentWidth, height: view.hx_height)
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
            if !previewAssets.isEmpty {
                DispatchQueue.main.async {
                    self.bottomView.selectedView.scrollTo(photoAsset: self.previewAssets[self.currentPreviewIndex], isAnimated: false)
                }
            }
            firstLayoutSubviews = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true;
        edgesForExtendedLayout = .all;
        view.clipsToBounds = true
        config = hx_pickerController!.config.previewView
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationChanged(notify:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        initView()
    }
    
    func initView() {
        view.addSubview(collectionView)
        view.addSubview(bottomView)
        bottomView.updateFinishButtonTitle()
        if hx_pickerController!.config.selectMode == .multiple {
            if !hx_pickerController!.config.allowSelectedTogether && hx_pickerController!.config.maximumSelectVideoCount == 1 &&
                hx_pickerController!.config.selectType == .any{
                videoLoadSingleCell = true
            }
            navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: selectBoxControl)
            if !previewAssets.isEmpty {
                if currentPreviewIndex == 0  {
                    let photoAsset = previewAssets.first!
                    bottomView.selectedView.scrollTo(photoAsset: photoAsset)
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
    func configColor() {
        view.backgroundColor = HXPHManager.shared.isDark ? config.backgroundDarkColor : config.backgroundColor
        collectionView.backgroundColor = HXPHManager.shared.isDark ? config.backgroundDarkColor : config.backgroundColor
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
            let cell = getCell(for: currentPreviewIndex)
            cell?.cancelRequest()
            cell?.scrollContentView?.imageView.image = image
        }
    }
    @objc func deviceOrientationChanged(notify: Notification) {
        orientationDidChange = true
        let cell = getCell(for: currentPreviewIndex)
        if cell?.photoAsset?.mediaSubType == .livePhoto {
            if #available(iOS 9.1, *) {
                cell?.scrollContentView?.livePhotoView.stopPlayback()
            }
        }
        bottomView.selectedView.reloadSectionInset()
    }
    // MARK: HXPHPreviewViewCellDelegate
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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return previewAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
            videoCell.autoPlayVideo = config.autoPlayVideo
        }
        cell.photoAsset = photoAsset
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let myCell = cell as! HXPHPreviewViewCell
        myCell.cancelRequest()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != collectionView || orientationDidChange {
            return
        }
        let offsetX = scrollView.contentOffset.x  + (view.hx_width + 20) * 0.5
        let width = view.hx_width + 20
        var currentIndex = Int(offsetX / width)
        if currentIndex > previewAssets.count - 1 {
            currentIndex = previewAssets.count - 1
        }
        if currentIndex < 0 {
            currentIndex = 0
        }
        if !previewAssets.isEmpty {
            let photoAsset = previewAssets[currentIndex]
            if photoAsset.mediaType == .video && videoLoadSingleCell {
                selectBoxControl.isHidden = true
            }else {
                selectBoxControl.isHidden = false
                updateSelectBox(photoAsset.isSelected, photoAsset: photoAsset)
                if selectBoxControl.isSelected == photoAsset.isSelected {
                    selectBoxControl.setNeedsDisplay()
                }else {
                    selectBoxControl.isSelected = photoAsset.isSelected
                }
            }
            if !firstLayoutSubviews {
                bottomView.selectedView.scrollTo(photoAsset: photoAsset)
            }
        }
        self.currentPreviewIndex = currentIndex
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView != collectionView || orientationDidChange {
            return
        }
        let cell = getCell(for: currentPreviewIndex)
        cell?.requestPreviewAsset()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppear = true
        let cell = getCell(for: currentPreviewIndex)
        cell?.requestPreviewAsset()
    }
    override var prefersStatusBarHidden: Bool {
        return statusBarShouldBeHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) && viewDidAppear {
                configColor()
            }
        }
    }
    
    // MARK: UINavigationControllerDelegate
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            if toVC is HXPHPreviewViewController {
                return HXPHPickerControllerTransition.init(type: .push)
            }
        }else if operation == .pop {
            if fromVC is HXPHPreviewViewController {
                let cell = getCell(for: currentPreviewIndex)
                if cell != nil && cell!.photoAsset!.mediaType == .video {
                    cell?.scrollContentView?.videoView.hiddenPlayButton()
                }
                return HXPHPickerControllerTransition.init(type: .pop)
            }
        }
        return nil
    }
    
    deinit {
        print("\(self) deinit")
        NotificationCenter.default.removeObserver(self)
    }
}

protocol HXPHPreviewSelectedViewDelegate: NSObjectProtocol {
    func selectedView(_ selectedView: HXPHPreviewSelectedView, didSelectItemAt photoAsset: HXPHAsset)
}

class HXPHPreviewSelectedView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    weak var delegate: HXPHPreviewSelectedViewDelegate?
    
    lazy var collectionViewLayout : UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        layout.sectionInset = UIEdgeInsets(top: 10, left: 12 + UIDevice.current.hx_leftMargin, bottom: 5, right: 12 + UIDevice.current.hx_rightMargin)
        return layout
    }()
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView.init(frame: bounds, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(HXPHPreviewSelectedViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPreviewSelectedViewCell.self))
        return collectionView
    }()
    
    var photoAssetArray: [HXPHAsset] = []
    var currentSelectedIndexPath: IndexPath?
    var tickColor: UIColor?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(collectionView)
    }
    func reloadSectionInset() {
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 10, left: 12 + UIDevice.current.hx_leftMargin, bottom: 5, right: 12 + UIDevice.current.hx_rightMargin)
    }
    func reloadData(photoAssets: [HXPHAsset]) {
        isHidden = photoAssets.isEmpty
        photoAssetArray = photoAssets
        collectionView.reloadData()
    }
    
    func insertPhotoAsset(photoAsset: HXPHAsset) {
        let beforeIsEmpty = photoAssetArray.isEmpty
        let item = photoAssetArray.count
        let indexPath = IndexPath(item: item, section: 0)
        photoAssetArray.append(photoAsset)
        collectionView.insertItems(at: [indexPath])
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        currentSelectedIndexPath = indexPath
        if beforeIsEmpty {
            alpha = 0
            isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.alpha = 1
            }
        }
    }
    
    func removePhotoAsset(photoAsset: HXPHAsset) {
        let beforeIsEmpty = photoAssetArray.isEmpty
        let item = photoAssetArray.firstIndex(of: photoAsset)
        if item != nil {
            if item! == currentSelectedIndexPath?.item {
                currentSelectedIndexPath = nil
            }
            photoAssetArray.remove(at: item!)
            collectionView.deleteItems(at: [IndexPath(item: item!, section: 0)])
        }
        if !beforeIsEmpty && photoAssetArray.isEmpty {
            UIView.animate(withDuration: 0.25) {
                self.alpha = 0
            } completion: { (isFinish) in
                if isFinish {
                    self.isHidden = true
                }
            }
        }
    }
    func scrollTo(photoAsset: HXPHAsset?, isAnimated: Bool) {
        if photoAsset == nil {
            deSelectedCurrentIndexPath()
            return
        }
        if photoAssetArray.contains(photoAsset!) {
            let item = photoAssetArray.firstIndex(of: photoAsset!) ?? 0
            if item == currentSelectedIndexPath?.item {
                return
            }
            let indexPath = IndexPath(item: item, section: 0)
            collectionView.selectItem(at: indexPath, animated: isAnimated, scrollPosition: .centeredHorizontally)
            currentSelectedIndexPath = indexPath
        }else {
            deSelectedCurrentIndexPath()
        }
    }
    func scrollTo(photoAsset: HXPHAsset?) {
        scrollTo(photoAsset: photoAsset, isAnimated: true)
    }
    func deSelectedCurrentIndexPath() {
        if currentSelectedIndexPath != nil {
            collectionView.deselectItem(at: currentSelectedIndexPath!, animated: true)
            currentSelectedIndexPath = nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photoAssetArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPreviewSelectedViewCell.self), for: indexPath) as! HXPHPreviewSelectedViewCell
        cell.tickColor = tickColor
        cell.photoAsset = photoAssetArray[indexPath.item]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentSelectedIndexPath = indexPath
        delegate?.selectedView(self, didSelectItemAt: photoAssetArray[indexPath.item])
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let photoAsset = photoAssetArray[indexPath.item]
        return getItemSize(photoAsset: photoAsset)
    }
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let myCell = cell as! HXPHPreviewSelectedViewCell
        myCell.cancelRequest()
    }
    func getItemSize(photoAsset: HXPHAsset) -> CGSize {
        let minWidth: CGFloat = 70 - collectionViewLayout.sectionInset.top - collectionViewLayout.sectionInset.bottom
        let maxWidth: CGFloat = minWidth / 9 * 16
        let maxHeight: CGFloat = minWidth
        let aspectRatio = maxHeight / photoAsset.imageSize.height
        let itemHeight = maxHeight
        var itemWidth = photoAsset.imageSize.width * aspectRatio
        if itemWidth < minWidth {
            itemWidth = minWidth
        }else if itemWidth > maxWidth {
            itemWidth = maxWidth
        }
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    override func layoutSubviews() {
        collectionView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class HXPHPreviewSelectedViewCell: UICollectionViewCell {
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView.init()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    lazy var selectedView: UIView = {
        let selectedView = UIView.init()
        selectedView.isHidden = true
        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        selectedView.addSubview(tickView)
        return selectedView
    }()
    
    lazy var tickView: HXAlbumTickView = {
        let tickView = HXAlbumTickView.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        return tickView
    }()
    
    var tickColor: UIColor? {
        didSet {
            tickView.tickLayer.strokeColor = tickColor?.cgColor
        }
    }
    
    var requestID: PHImageRequestID?
    
    var photoAsset: HXPHAsset? {
        didSet {
            weak var weakSelf = self
            requestID = photoAsset?.requestThumbnailImage(targetWidth: 150, completion: { (image, asset, info) in
                if weakSelf?.photoAsset == asset {
                    weakSelf?.imageView.image = image
                }
            })
            
        }
    }
    override var isSelected: Bool {
        didSet {
            selectedView.isHidden = !isSelected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(selectedView)
    }
    
    func cancelRequest() {
        if requestID != nil {
            PHImageManager.default().cancelImageRequest(requestID!)
            requestID = nil
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        selectedView.frame = bounds
        tickView.center = CGPoint(x: hx_width * 0.5, y: hx_height * 0.5)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
