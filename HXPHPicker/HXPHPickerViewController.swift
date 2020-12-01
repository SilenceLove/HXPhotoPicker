//
//  HXPHPickerViewController.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2019/6/29.
//  Copyright © 2019年 洪欣. All rights reserved.
//

import UIKit

class HXPHPickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, HXPHPickerViewCellDelegate, HXPHPickerBottomViewDelegate, HXPHPreviewViewControllerDelegate {
    
    var config: HXPHPhotoListConfiguration!
    var assetCollection: HXPHAssetCollection!
    var assets: [HXPHAsset] = []
    lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let collectionViewLayout = UICollectionViewFlowLayout.init()
        let space = config.spacing
        collectionViewLayout.minimumLineSpacing = space
        collectionViewLayout.minimumInteritemSpacing = space
        return collectionViewLayout
    }()
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView.init(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HXPHPickerViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPickerViewCell.classForCoder()))
        collectionView.register(HXPHPickerMultiSelectViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPickerMultiSelectViewCell.classForCoder()))
        
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
            self.automaticallyAdjustsScrollViewInsets = false
        }
        return collectionView
    }()
    var orientationDidChange : Bool = false
    var beforeOrientationIndexPath: IndexPath?
    var showLoading : Bool = false
    var isMultipleSelect : Bool = false
    var videoLoadSingleCell = false
    
    lazy var bottomView : HXPHPickerBottomView = {
        let bottomView = HXPHPickerBottomView.init(config: config.bottomView)
        bottomView.hx_delegate = self
        bottomView.boxControl.isSelected = hx_pickerController()!.isOriginal
        return bottomView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configData()
        initView()
        configColor()
        fetchData()
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationChanged(notify:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    @objc func deviceOrientationChanged(notify: Notification) {
        beforeOrientationIndexPath = collectionView.indexPathsForVisibleItems.first
        orientationDidChange = true
    }
    func configData() {
        isMultipleSelect = hx_pickerController()!.config.selectMode == .multiple
        if !hx_pickerController()!.config.photosAndVideosCanBeSelectedTogether && hx_pickerController()!.config.maximumSelectVideoCount == 1 &&
            hx_pickerController()!.config.selectType == .any &&
            isMultipleSelect {
            videoLoadSingleCell = true
        }
        config = hx_pickerController()!.config.photoList
        updateTitle()
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "取消".hx_localized, style: .done, target: self, action: #selector(didCancelItemClick))
    }
    func configColor() {
        view.backgroundColor = HXPHManager.shared.isDark ? config.backgroundDarkColor : config.backgroundColor
        collectionView.backgroundColor = HXPHManager.shared.isDark ? config.backgroundDarkColor : config.backgroundColor
    }
    @objc func didCancelItemClick() {
        hx_pickerController()?.cancelCallback()
    }
    
    func initView() {
        extendedLayoutIncludesOpaqueBars = true;
        edgesForExtendedLayout = .all;
        view.addSubview(collectionView)
        if isMultipleSelect {
            view.addSubview(bottomView)
            bottomView.updateFinishButtonTitle()
        }
    }
    func updateTitle() {
        title = assetCollection?.albumName
    }
    func fetchData() {
        if hx_pickerController()!.config.albumShowMode == .popup {
            HXPHAssetManager.requestAuthorization { (status) in
                
            }
        }else {
            if showLoading {
                HXPHProgressHUD.showLoadingHUD(addedTo: view, afterDelay: 0.15, animated: true)
            }
            fetchPhotoAssets()
        }
    }
    func fetchPhotoAssets() {
        hx_pickerController()!.fetchPhotoAssets(assetCollection: assetCollection) { (photoAssets, photoAsset) in
            self.assets = photoAssets
            self.collectionView.reloadData()
            self.scrollToAppropriatePlace(photoAsset: photoAsset)
            if self.showLoading {
                HXPHProgressHUD.hideHUD(forView: self.view, animated: true)
                self.showLoading = false
            }else {
                HXPHProgressHUD.hideHUD(forView: self.navigationController?.view, animated: false)
            }
        }
    }
    func scrollToAppropriatePlace(photoAsset: HXPHAsset?) {
        if assets.isEmpty {
            return
        }
        if !hx_pickerController()!.config.reverseOrder {
            var item = assets.count - 1
            if photoAsset != nil {
                item = assets.firstIndex(of: photoAsset!) ?? item
            }
            collectionView.scrollToItem(at: IndexPath(item: item, section: 0), at: .bottom, animated: false)
        }
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: HXPHPickerViewCell
        let photoAsset = assets[indexPath.item]
        if hx_pickerController()?.config.selectMode == .single || (photoAsset.mediaType == .video && videoLoadSingleCell) {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPickerViewCell.classForCoder()), for: indexPath) as! HXPHPickerViewCell
        }else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPickerMultiSelectViewCell.classForCoder()), for: indexPath) as! HXPHPickerMultiSelectViewCell
        }
        cell.delegate = self
        cell.config = config.cell
        cell.photoAsset = photoAsset
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let myCell: HXPHPickerViewCell = cell as! HXPHPickerViewCell
        
        myCell.cancelRequest()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        pushPreviewViewController(previewAssets: assets, currentPreviewIndex: indexPath.item)
    }
    
    func pushPreviewViewController(previewAssets: [HXPHAsset], currentPreviewIndex: Int) {
        let vc = HXPHPreviewViewController.init()
        vc.previewAssets = previewAssets
        vc.currentPreviewIndex = currentPreviewIndex
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: HXPHPickerViewCellDelegate
    
    func cellDidSelectControlClick(_ cell: HXPHPickerMultiSelectViewCell, isSelected: Bool) {
        if isSelected {
            // 取消选中
            _ = hx_pickerController()?.removePhotoAsset(photoAsset: cell.photoAsset!)
            cell.updateSelectedState(isSelected: false, animated: true)
            if config.cell.selectBox.type == .number {
                updateCellSelectedTitle()
            }
        }else {
            // 选中
            if hx_pickerController()!.addedPhotoAsset(photoAsset: cell.photoAsset!) {
                if HXPHAssetManager.isICloudAsset(for: cell.photoAsset!.asset) {
                    navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                    HXPHProgressHUD.showLoadingHUD(addedTo: navigationController?.view, text: "正在下载...", animated: true)
                    weak var weakSelf = self
                    if cell.photoAsset?.mediaType == .photo {
                        _ = cell.photoAsset?.requestImageData(iCloudHandler: nil, progressHandler: { (photoAsset, progress) in
                            print(progress)
                        }, success: { (photoAsset, data, orientation, info) in
                            cell.photoAsset?.asset = HXPHAssetManager.fetchAsset(withLocalIdentifier: photoAsset.asset!.localIdentifier)
                            cell.updateSelectedState(isSelected: true, animated: true)
                            weakSelf?.bottomView.updateFinishButtonTitle()
                            HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
                            weakSelf?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                        }, failure: { (photoAsset, info) in
                            HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
                            weakSelf?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                        })
                    }else if cell.photoAsset?.mediaType == .video {
                        _ = cell.photoAsset?.requestAVAsset(iCloudHandler: nil, progressHandler: nil, success: { (photoAsset, avAsset, info) in
                            cell.photoAsset?.asset = HXPHAssetManager.fetchAsset(withLocalIdentifier: photoAsset.asset!.localIdentifier)
                            cell.updateSelectedState(isSelected: true, animated: true)
                            weakSelf?.bottomView.updateFinishButtonTitle()
                            HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
                            weakSelf?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                        }, failure: { (photoAsset, info) in
                            HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
                            weakSelf?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                        })
                    }
                    return
                }
                cell.updateSelectedState(isSelected: true, animated: true)
            }
        }
        bottomView.updateFinishButtonTitle()
    }
    
    func updateCellSelectedTitle() {
        for visibleCell in collectionView.visibleCells {
            if visibleCell is HXPHPickerMultiSelectViewCell {
                let cell = visibleCell as! HXPHPickerMultiSelectViewCell
                if cell.photoAsset!.selected {
                    if Int(cell.selectControl.text) != (cell.photoAsset!.selectIndex + 1) {
                        cell.updateSelectedState(isSelected: true, animated: false)
                        cell.selectControl.setNeedsDisplay()
                    }
                }
            }
        }
    }
    
    // MARK: HXPHPickerBottomViewDelegate
    func bottomViewDidPreviewButtonClick(view: HXPHPickerBottomView) {
        pushPreviewViewController(previewAssets: hx_pickerController()!.selectedAssetArray, currentPreviewIndex: 0)
    }
    func bottomViewDidFinishButtonClick(view: HXPHPickerBottomView) {
        hx_pickerController()?.finishCallback()
    }
    func bottomViewDidOriginalButtonClick(view: HXPHPickerBottomView, with isOriginal: Bool) {
        hx_pickerController()?.originalButtonCallback()
    }
    
    // MARK: HXPHPreviewViewControllerDelegate
    func previewViewControllerDidClickOriginal(_ previewViewController: HXPHPreviewViewController, with isOriginal: Bool) {
        if isMultipleSelect {
            bottomView.boxControl.isSelected = isOriginal
        }
    }
    func previewViewControllerDidClickSelectBox(_ previewViewController: HXPHPreviewViewController, with isSelected: Bool) {
        collectionView.reloadData()
        bottomView.updateFinishButtonTitle()
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let margin: CGFloat = UIDevice.current.hx_leftMargin
        collectionView.frame = CGRect(x: margin, y: 0, width: view.hx_width - 2 * margin, height: view.hx_height)
        var collectionTop: CGFloat
        if navigationController?.modalPresentationStyle == .fullScreen {
            collectionTop = UIDevice.current.hx_navigationBarHeight
        }else {
            collectionTop = navigationController!.navigationBar.hx_height
        }
        if isMultipleSelect {
            bottomView.frame = CGRect(x: 0, y: view.hx_height - 50 - UIDevice.current.hx_bottomMargin, width: view.hx_width, height: 50 + UIDevice.current.hx_bottomMargin)
            collectionView.contentInset = UIEdgeInsets(top: collectionTop, left: 0, bottom: bottomView.hx_height + 0.5, right: 0)
        }else {
            collectionView.contentInset = UIEdgeInsets(top: collectionTop, left: 0, bottom: UIDevice.current.hx_bottomMargin, right: 0)
        }
        let space = config.spacing
        let count : CGFloat
        if  UIDevice.current.hx_isPortrait == true {
            count = CGFloat(config.rowNumber)
        }else {
            count = CGFloat(config.landscapeRowNumber)
        }
        let itemWidth = (collectionView.hx_width - space * (count - CGFloat(1))) / count
        collectionViewLayout.itemSize = CGSize.init(width: itemWidth, height: itemWidth)
        collectionView.setCollectionViewLayout(collectionViewLayout, animated: true)
        if orientationDidChange {
            collectionView.scrollToItem(at: beforeOrientationIndexPath ?? IndexPath(item: 0, section: 0), at: .top, animated: false)
            orientationDidChange = false
        }
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
        NotificationCenter.default.removeObserver(self)
    }
}

protocol HXPHPickerBottomViewDelegate: NSObjectProtocol {
    func bottomViewDidPreviewButtonClick(view: HXPHPickerBottomView)
    func bottomViewDidFinishButtonClick(view: HXPHPickerBottomView)
    func bottomViewDidOriginalButtonClick(view: HXPHPickerBottomView, with isOriginal: Bool)
}

class HXPHPickerBottomView: UIToolbar {
    weak var hx_delegate: HXPHPickerBottomViewDelegate?
    
    var config: HXPHPickerBottomViewConfiguration?
    
    lazy var previewBtn: UIButton = {
        let previewBtn = UIButton.init(type: .custom)
        previewBtn.setTitle("预览".hx_localized, for: .normal)
        previewBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        previewBtn.isEnabled = false
        previewBtn.addTarget(self, action: #selector(didPreviewButtonClick(button:)), for: .touchUpInside)
        previewBtn.isHidden = config!.previewButtonHidden
        return previewBtn
    }()
    
    @objc func didPreviewButtonClick(button: UIButton) {
        hx_delegate?.bottomViewDidPreviewButtonClick(view: self)
    }
    
    lazy var editBtn: UIButton = {
        let editBtn = UIButton.init(type: .custom)
        editBtn.setTitle("编辑".hx_localized, for: .normal)
        editBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        editBtn.addTarget(self, action: #selector(didEditBtnButtonClick(button:)), for: .touchUpInside)
        editBtn.isHidden = config!.editButtonHidden
        return editBtn
    }()
    
    @objc func didEditBtnButtonClick(button: UIButton) {
        hx_delegate?.bottomViewDidPreviewButtonClick(view: self)
    }
    
    lazy var originalBtn: UIView = {
        let originalBtn = UIView.init()
        originalBtn.addSubview(originalTitleLb)
        originalBtn.addSubview(boxControl)
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(didOriginalButtonClick))
        originalBtn.addGestureRecognizer(tap)
        originalBtn.isHidden = config!.originalButtonHidden
        return originalBtn
    }()
    
    @objc func didOriginalButtonClick() {
        if boxControl.isSelected {
            // 取消
            
        }else {
            // 选中
            
        }
        boxControl.isSelected = !boxControl.isSelected
        hx_viewController()?.hx_pickerController()?.isOriginal = boxControl.isSelected
        hx_delegate?.bottomViewDidOriginalButtonClick(view: self, with: boxControl.isSelected)
        boxControl.layer.removeAnimation(forKey: "SelectControlAnimation")
        let keyAnimation = CAKeyframeAnimation.init(keyPath: "transform.scale")
        keyAnimation.duration = 0.3
        keyAnimation.values = [1.2, 0.8, 1.1, 0.9, 1.0]
        boxControl.layer.add(keyAnimation, forKey: "SelectControlAnimation")
    }
    
    lazy var originalTitleLb: UILabel = {
        let originalTitleLb = UILabel.init()
        originalTitleLb.text = "原图".hx_localized
        originalTitleLb.font = UIFont.systemFont(ofSize: 17)
        originalTitleLb.frame = CGRect(x: 0, y: 0, width: originalTitleLb.text!.hx_stringWidth(ofFont: originalTitleLb.font, maxHeight: 50), height: 50)
        return originalTitleLb
    }()
    
    lazy var boxControl: HXPHPickerCellSelectBoxControl = {
        let boxControl = HXPHPickerCellSelectBoxControl.init(frame: CGRect(x: originalTitleLb.hx_width + 2, y: 0, width: 16, height: 16))
        boxControl.config = config!.originalSelectBox
        boxControl.hx_centerY = originalTitleLb.hx_height * 0.5
        boxControl.backgroundColor = UIColor.clear
        return boxControl
    }()
    
    lazy var finishBtn: UIButton = {
        let finishBtn = UIButton.init(type: .custom)
        finishBtn.setTitle("完成".hx_localized, for: .normal)
        finishBtn.titleLabel?.font = UIFont.hx_mediumPingFang(size: 16)
        finishBtn.layer.cornerRadius = 3
        finishBtn.layer.masksToBounds = true
        finishBtn.isEnabled = false
        finishBtn.addTarget(self, action: #selector(didFinishButtonClick(button:)), for: .touchUpInside)
        return finishBtn
    }()
    @objc func didFinishButtonClick(button: UIButton) {
        hx_delegate?.bottomViewDidFinishButtonClick(view: self)
    }
    
    init(config: HXPHPickerBottomViewConfiguration) {
        super.init(frame: CGRect.zero)
        self.config = config
        addSubview(previewBtn)
        addSubview(editBtn)
        addSubview(originalBtn)
        addSubview(finishBtn)
        configColor()
        isTranslucent = config.isTranslucent
    }
    func configColor() {
        backgroundColor = HXPHManager.shared.isDark ? config!.backgroundDarkColor : config!.backgroundColor
        barTintColor = HXPHManager.shared.isDark ? config!.barTintDarkColor : config!.barTintColor
        barStyle = HXPHManager.shared.isDark ? config!.barDarkStyle : config!.barStyle
        
        previewBtn.setTitleColor(HXPHManager.shared.isDark ? config?.previewButtonTitleDarkColor : config?.previewButtonTitleColor, for: .normal)
        
        editBtn.setTitleColor(HXPHManager.shared.isDark ? config?.editButtonTitleDarkColor : config?.editButtonTitleColor, for: .normal)
        
        if HXPHManager.shared.isDark {
            if config?.previewButtonDisableTitleDarkColor != nil {
                previewBtn.setTitleColor(config?.previewButtonDisableTitleDarkColor, for: .disabled)
            }else {
                previewBtn.setTitleColor(config?.previewButtonTitleDarkColor.withAlphaComponent(0.6), for: .disabled)
            }
            
            if config?.editButtonDisableTitleDarkColor != nil {
                editBtn.setTitleColor(config?.editButtonDisableTitleDarkColor, for: .disabled)
            }else {
                editBtn.setTitleColor(config?.editButtonTitleDarkColor.withAlphaComponent(0.6), for: .disabled)
            }
        }else {
            if config?.previewButtonDisableTitleColor != nil {
                previewBtn.setTitleColor(config?.previewButtonDisableTitleColor, for: .disabled)
            }else {
                previewBtn.setTitleColor(config?.previewButtonTitleColor.withAlphaComponent(0.6), for: .disabled)
            }
            
            if config?.editButtonDisableTitleColor != nil {
                editBtn.setTitleColor(config?.editButtonDisableTitleColor, for: .disabled)
            }else {
                editBtn.setTitleColor(config?.editButtonTitleColor.withAlphaComponent(0.6), for: .disabled)
            }
        }
        
        originalTitleLb.textColor = HXPHManager.shared.isDark ? config?.originalButtonTitleDarkColor : config?.originalButtonTitleColor
        finishBtn.setTitleColor(HXPHManager.shared.isDark ? config?.finishButtonTitleDarkColor : config?.finishButtonTitleColor, for: .normal)
        finishBtn.setTitleColor(HXPHManager.shared.isDark ? config?.finishButtonDisableTitleDarkColor : config?.finishButtonDisableTitleColor, for: .disabled)
        finishBtn.setBackgroundImage(UIImage.hx_image(for: HXPHManager.shared.isDark ? config!.finishButtonDarkBackgroudColor : config!.finishButtonBackgroudColor, havingSize: CGSize.zero), for: .normal)
        finishBtn.setBackgroundImage(UIImage.hx_image(for: HXPHManager.shared.isDark ? config!.finishButtonDisableDarkBackgroudColor : config!.finishButtonDisableBackgroudColor, havingSize: CGSize.zero), for: .disabled)
    }
    func updateFinishButtonTitle() {
        let selectCount = hx_viewController()?.hx_pickerController()?.selectedAssetArray.count ?? 0
        if selectCount > 0 {
            finishBtn.isEnabled = true
            previewBtn.isEnabled = true
            finishBtn.setTitle("完成".hx_localized + " (" + String(format: "%d", arguments: [selectCount]) + ")", for: .normal)
        }else {
            finishBtn.isEnabled = !config!.disableFinishButtonWhenNotSelected
            previewBtn.isEnabled = false
            finishBtn.setTitle("完成".hx_localized, for: .normal)
        }
        updateFinishButtonFrame()
    }
    
    func updateFinishButtonFrame() {
        originalBtn.hx_centerX = hx_width / 2
        var finishWidth : CGFloat = finishBtn.currentTitle!.hx_localized.hx_stringWidth(ofFont: finishBtn.titleLabel!.font, maxHeight: 50) + 20
        if finishWidth < 60 {
            finishWidth = 60
        }
        finishBtn.frame = CGRect(x: hx_width - UIDevice.current.hx_rightMargin - finishWidth - 12, y: 0, width: finishWidth, height: 33)
        finishBtn.hx_centerY = 25
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let previewWidth : CGFloat = previewBtn.currentTitle!.hx_localized.hx_stringWidth(ofFont: previewBtn.titleLabel!.font, maxHeight: 50)
        previewBtn.frame = CGRect(x: 12 + UIDevice.current.hx_leftMargin, y: 0, width: previewWidth, height: 50)
        editBtn.frame = previewBtn.frame
        originalBtn.frame = CGRect(x: 0, y: 0, width: boxControl.frame.maxX, height: 50)
        updateFinishButtonFrame()
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
