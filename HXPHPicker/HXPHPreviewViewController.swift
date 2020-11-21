//
//  HXPHPreviewViewController.swift
//  HXPHPickerExample
//
//  Created by 洪欣 on 2020/11/13.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

protocol HXPHPreviewViewControllerDelegate: NSObjectProtocol {
    func previewViewControllerDidClickOriginal(_ previewViewController:HXPHPreviewViewController, with isOriginal: Bool)
    func previewViewControllerDidClickSelectBox(_ previewViewController:HXPHPreviewViewController, with isSelected: Bool)
}

class HXPHPreviewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, HXPHPreviewViewCellDelegate, HXPHPickerBottomViewDelegate {
    
    weak var delegate: HXPHPreviewViewControllerDelegate?
    var config : HXPHPreviewViewConfiguration!
    var currentPreviewIndex : Int = 0
    var orientationDidChange : Bool = false
    var statusBarShouldBeHidden : Bool = false
    var previewAssets : [HXPHAsset] = []
    
    lazy var selectBoxControl: HXPHPickerCellSelectBoxControl = {
        let boxControl = HXPHPickerCellSelectBoxControl.init(frame: CGRect(x: 0, y: 0, width: config.selectBox.size.width, height: config.selectBox.size.height))
        boxControl.backgroundColor = UIColor.clear
        boxControl.config = config.selectBox
        boxControl.addTarget(self, action: #selector(didSelectBoxControlClick), for: UIControl.Event.touchUpInside)
        return boxControl
    }()
    @objc func didSelectBoxControlClick() {
        let isSelected = !selectBoxControl.isSelected
        let photoAsset = previewAssets[currentPreviewIndex]
        var canUpdate = false
        if isSelected {
            // 选中
            if hx_pickerController()!.addedPhotoAsset(photoAsset: photoAsset) {
                canUpdate = true
            }
        }else {
            // 取消选中
            _ = hx_pickerController()?.removePhotoAsset(photoAsset: photoAsset)
            canUpdate = true
        }
        if canUpdate {
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
            if config.selectBox.type == HXPHPickerCellSelectBoxType.number {
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
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        return layout
    }()
    
    lazy var collectionView : UICollectionView = {
        let collectionView = UICollectionView.init(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = config.backgroundColor
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        } else {
            // Fallback on earlier versions
            self.automaticallyAdjustsScrollViewInsets = false
        }
        collectionView.register(HXPHPreviewPhotoViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPreviewPhotoViewCell.self))
        collectionView.register(HXPHPreviewLivePhotoViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPreviewLivePhotoViewCell.self))
        return collectionView
    }()
    
    lazy var bottomView : HXPHPickerBottomView = {
        let bottomView = HXPHPickerBottomView.init(config: config.bottomView)
        bottomView.hx_delegate = self
        bottomView.boxControl.isSelected = hx_pickerController()!.isOriginal
        return bottomView
    }()
    // MARK: HXPHPickerBottomViewDelegate
    func bottomViewDidPreviewButtonClick(view: HXPHPickerBottomView) {}
    func bottomViewDidFinishButtonClick(view: HXPHPickerBottomView) {
        hx_pickerController()?.finishCallback()
        dismiss(animated: true, completion: nil)
    }
    func bottomViewDidOriginalButtonClick(view: HXPHPickerBottomView, with isOriginal: Bool) {
        delegate?.previewViewControllerDidClickOriginal(self, with: isOriginal)
    }
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        bottomView.frame = CGRect(x: 0, y: view.hx_height - UIDevice.hx_bottomMargin() - 50, width: view.hx_width, height: 50 + UIDevice.hx_bottomMargin())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true;
        edgesForExtendedLayout = UIRectEdge.all;
        view.clipsToBounds = true
        config = hx_pickerController()!.config.previewView
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationChanged(notify:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        view.backgroundColor = config.backgroundColor
        initView()
    }
    
    func initView() {
        view.addSubview(collectionView)
        view.addSubview(bottomView)
        bottomView.updateFinishButtonTitle()
        if hx_pickerController()!.config.selectMode == HXPHAssetSelectMode.multiple {
            navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: selectBoxControl)
            if currentPreviewIndex == 0 && !previewAssets.isEmpty {
                let photoAsset = previewAssets.first!
                updateSelectBox(photoAsset.selected, photoAsset: photoAsset)
                selectBoxControl.isSelected = photoAsset.selected
            }
        }
    }
    
    func getCell(for item: Int) -> HXPHPreviewViewCell? {
        if previewAssets.isEmpty {
            return nil
        }
        let cell = self.collectionView.cellForItem(at: IndexPath.init(item: item, section: 0)) as! HXPHPreviewViewCell
        return cell
    }
    
    @objc func deviceOrientationChanged(notify: Notification) {
        orientationDidChange = true
        let cell = getCell(for: currentPreviewIndex)
        if cell?.photoAsset?.mediaSubType == HXPHAssetMediaSubType.livePhoto {
            if #available(iOS 9.1, *) {
                cell?.scrollContentView?.livePhotoView.stopPlayback()
            }
        }
    }
    
    func singleTap() {
        if navigationController == nil {
            return
        }
        let isHidden = navigationController!.navigationBar.isHidden
        statusBarShouldBeHidden = !isHidden
        if self.modalPresentationStyle == UIModalPresentationStyle.fullScreen {
            UIApplication.shared.setStatusBarHidden(statusBarShouldBeHidden, with: UIStatusBarAnimation.fade)
            navigationController?.setNeedsStatusBarAppearanceUpdate()
        }
        navigationController!.setNavigationBarHidden(statusBarShouldBeHidden, animated: true)
        if !statusBarShouldBeHidden {
            self.bottomView.isHidden = false
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
        let cell :HXPHPreviewViewCell
        if photoAsset.mediaSubType == HXPHAssetMediaSubType.livePhoto {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPreviewLivePhotoViewCell.self), for: indexPath) as! HXPHPreviewLivePhotoViewCell
        }else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPreviewPhotoViewCell.self), for: indexPath) as! HXPHPreviewPhotoViewCell
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
            updateSelectBox(photoAsset.selected, photoAsset: photoAsset)
            if selectBoxControl.isSelected == photoAsset.selected {
                selectBoxControl.setNeedsDisplay()
            }else {
                selectBoxControl.isSelected = photoAsset.selected
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
        let cell = getCell(for: currentPreviewIndex)
        cell?.requestPreviewAsset()
    }
    override var prefersStatusBarHidden: Bool {
        return statusBarShouldBeHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.fade
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
