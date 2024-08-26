//
//  PhotoPickerPageViewController.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/23.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public class PhotoPickerPageViewController: HXBaseViewController, PhotoPickerList {
    
    public weak var delegate: PhotoPickerListDelegate?
    
    public var contentInset: UIEdgeInsets = .zero {
        didSet {
            headerView.y = contentInset.top
            contentVCs.forEach {
                $0.contentInset = .init(top: headerView.frame.maxY, left: contentInset.left, bottom: contentInset.bottom, right: contentInset.right)
            }
        }
    }
    
    public var scrollIndicatorInsets: UIEdgeInsets = .zero {
        didSet {
            contentVCs.forEach {
                $0.scrollIndicatorInsets = scrollIndicatorInsets
            }
        }
    }
    
    public var pickerConfig: PickerConfiguration
    public var config: PhotoListConfiguration
    public var collectionView: UICollectionView! = .init(frame: .zero, collectionViewLayout: .init())
    
    public var filterOptions: PhotoPickerFilterSection.Options {
        get {
            if contentVCs.isEmpty {
                return .any
            }
            return contentVCs[headerView.selectedIndex].filterOptions
        }
        set {
            contentVCs.forEach {
                $0.filterOptions = newValue
            }
        }
    }
    
    public var assetResult: PhotoFetchAssetResult = .init() {
        didSet {
            var titles: [String] = []
            contentVCs = []
            if !assetResult.videoAssets.isEmpty {
                titles.append(.textPhotoList.pageVideoTitle.text)
                let assets = assetResult.videoAssets
                let vc = PhotoPickerListViewController.init(config: pickerConfig)
                vc.delegate = self
                vc.assetResult = .init(assets: assets, videoAssets: assets, videoCount: assets.count)
                contentVCs.append(vc)
            }
            if !assetResult.normalAssets.isEmpty {
                titles.append(.textPhotoList.pagePhotoTitle.text)
                let assets = assetResult.normalAssets
                let vc = PhotoPickerListViewController.init(config: pickerConfig)
                vc.delegate = self
                vc.assetResult = .init(assets: assets, normalAssets: assets, photoCount: assets.count)
                contentVCs.append(vc)
            }
            if !assetResult.gifAssets.isEmpty {
                titles.append(.textPhotoList.pageGifTitle.text)
                let assets = assetResult.gifAssets
                let vc = PhotoPickerListViewController.init(config: pickerConfig)
                vc.delegate = self
                vc.assetResult = .init(assets: assets, gifAssets: assets, photoCount: assets.count)
                contentVCs.append(vc)
            }
            if !assetResult.livePhotoAssets.isEmpty {
                titles.append(.textPhotoList.pageLivePhotoTitle.text)
                let assets = assetResult.livePhotoAssets
                let vc = PhotoPickerListViewController.init(config: pickerConfig)
                vc.delegate = self
                vc.assetResult = .init(assets: assets, livePhotoAssets: assets, photoCount: assets.count)
                contentVCs.append(vc)
            }
            if !titles.isEmpty {
                titles.insert(.textPhotoList.pageAllTitle.text, at: 0)
                let vc = PhotoPickerListViewController.init(config: pickerConfig)
                vc.delegate = self
                vc.assetResult = assetResult
                contentVCs.insert(vc, at: 0)
            }
            headerView.titles = titles
            headerView.selectedIndex = 0
            
            scrollView.subviews.forEach { $0.removeFromSuperview() }
            children.forEach { $0.removeFromParent() }
            contentVCs.forEach {
                addChild($0)
                scrollView.addSubview($0.view)
            }
            layoutViews()
            scrollView.contentOffset = .zero
        }
    }
    
    public var assets: [PhotoAsset] {
        get {
            if contentVCs.isEmpty {
                return []
            }
            return contentVCs[headerView.selectedIndex].assets
        }
        set { }
    }
    
    public var photoCount: Int {
        get {
            if contentVCs.isEmpty {
                return 0
            }
            return contentVCs[headerView.selectedIndex].photoCount
        }
        set { }
    }
    
    public var videoCount: Int {
        get {
            if contentVCs.isEmpty {
                return 0
            }
            return contentVCs[headerView.selectedIndex].videoCount
        }
        set { }
    }
    
    public var didFetchAsset: Bool = false
    
    var contentVCs: [PhotoPickerListViewController] = []
    var headerView: PhotoPickerPageHeaderView!
    var scrollView: UIScrollView!
    
    public required init(config: PickerConfiguration) {
        pickerConfig = config
        self.config = config.photoList
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }else {
            automaticallyAdjustsScrollViewInsets = false
        }
        if let gesture = pickerController.dismissPanGestureRecognizer {
            scrollView.panGestureRecognizer.require(toFail: gesture)
        }
        view.addSubview(scrollView)
        headerView = PhotoPickerPageHeaderView()
        headerView.delegate = self
        view.addSubview(headerView)
    }
    
    public func scrollTo(_ asset: PhotoAsset?) {
        contentVCs.forEach { $0.scrollTo(asset) }
    }
    public func scrollToCenter(for photoAsset: PhotoAsset?) {
        contentVCs.forEach { $0.scrollToCenter(for: photoAsset) }
    }
    public func scrollCellToVisibleArea(_ cell: PhotoPickerBaseViewCell) {
        contentVCs.forEach { $0.scrollCellToVisibleArea(cell) }
    }
    public func addedAsset(for asset: PhotoAsset) {
        contentVCs.first?.addedAsset(for: asset)
    }
    
    public func reloadCell(for asset: PhotoAsset) {
        contentVCs.forEach { $0.reloadCell(for: asset) }
    }
    public func reloadData() {
        contentVCs.forEach { $0.reloadData() }
    }
    
    public func updateCellLoadMode(_ mode: PhotoManager.ThumbnailLoadMode, judgmentIsEqual: Bool) {
        contentVCs.forEach { $0.updateCellLoadMode(mode, judgmentIsEqual: judgmentIsEqual) }
    }
    public func cellReloadImage() {
        contentVCs.forEach { $0.cellReloadImage() }
    }
    public func getCell(for asset: PhotoAsset) -> PhotoPickerBaseViewCell? {
        if contentVCs.isEmpty {
            return nil
        }
        return contentVCs[headerView.selectedIndex].getCell(for: asset)
    }
    public func updateCellSelectedTitle() {
        contentVCs.forEach { $0.updateCellSelectedTitle() }
    }
    public func resetICloud(for asset: PhotoAsset) {
        contentVCs.forEach { $0.resetICloud(for: asset) }
    }
    public func selectCell(for asset: PhotoAsset, isSelected: Bool) {
        contentVCs.forEach { $0.selectCell(for: asset, isSelected: isSelected) }
    }
    
    var isDeviceOrientation: Bool = false
    public override func deviceOrientationWillChanged(notify: Notification) {
        isDeviceOrientation = true
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        headerView.frame = .init(x: 0, y: contentInset.top, width: view.width, height: 40)
        scrollView.frame = view.bounds
        layoutViews()
        if isDeviceOrientation {
            headerView(headerView, didSelectedButton: headerView.selectedIndex)
            isDeviceOrientation = false
        }
    }
    
    func layoutViews() {
        scrollView.contentSize = .init(
            width: view.width * CGFloat(contentVCs.count),
            height: view.height
        )
        for (index, controller) in contentVCs.enumerated() {
            controller.view.frame = .init(x: view.width * CGFloat(index), y: 0, width: view.width, height: view.height)
            controller.contentInset = .init(top: headerView.frame.maxY, left: contentInset.left, bottom: contentInset.bottom, right: contentInset.right)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PhotoPickerPageViewController: UIScrollViewDelegate, PhotoPickerPageHeaderViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let value = offsetX / (scrollView.contentSize.width - scrollView.width)
        headerView.offsetValue = value
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let index = Int(offsetX / scrollView.width)
        headerView.selectedIndex = Int(index)
    }
    
    func headerView(_ headerView: PhotoPickerPageHeaderView, didSelectedButton index: Int) {
        scrollView.setContentOffset(.init(x: scrollView.width * CGFloat(index), y: 0), animated: true)
    }
}

extension PhotoPickerPageViewController: PhotoPickerListDelegate {
    public func photoList(_ photoList: PhotoPickerList, didSelectCell asset: PhotoAsset, at index: Int, animated: Bool) {
        delegate?.photoList(self, didSelectCell: asset, at: index, animated: animated)
    }
    
    public func photoList(didLimitCell photoList: PhotoPickerList) {
        delegate?.photoList(didLimitCell: photoList)
    }
    
    public func photoList(selectedAssetDidChanged photoList: PhotoPickerList) {
        delegate?.photoList(selectedAssetDidChanged: self)
    }
    
    public func photoList(_ photoList: PhotoPickerList, openEditor asset: PhotoAsset, with image: UIImage?) {
        delegate?.photoList(self, openEditor: asset, with: image)
    }
    
    public func photoList(_ photoList: PhotoPickerList, openPreview assets: [PhotoAsset], with page: Int, animated: Bool) {
        delegate?.photoList(self, openPreview: assets, with: page, animated: animated)
    }
    
    public func photoList(presentCamera photoList: PhotoPickerList) {
        delegate?.photoList(presentCamera: self)
    }
    
    public func photoList(presentFilter photoList: PhotoPickerList, modalPresentationStyle: UIModalPresentationStyle) {
        delegate?.photoList(presentFilter: self, modalPresentationStyle: modalPresentationStyle)
    }
    
    public func photoList(_ photoList: PhotoPickerList, didSelectedAsset asset: PhotoAsset) {
        contentVCs.forEach {
            if $0 != photoList {
                $0.selectCell(for: asset, isSelected: true)
            }
        }
        delegate?.photoList(self, didSelectedAsset: asset)
    }
    
    public func photoList(_ photoList: PhotoPickerList, didDeselectedAsset asset: PhotoAsset) {
        contentVCs.forEach {
            if $0 != photoList {
                $0.selectCell(for: asset, isSelected: false)
            }
        }
        delegate?.photoList(self, didDeselectedAsset: asset)
    }
    
    public func photoList(_ photoList: PhotoPickerList, updateAsset asset: PhotoAsset) {
        delegate?.photoList(self, updateAsset: asset)
    }
}

protocol PhotoPickerPageHeaderViewDelegate: AnyObject {
    func headerView(_ headerView: PhotoPickerPageHeaderView, didSelectedButton index: Int)
}

class PhotoPickerPageHeaderView: UIView {
    
    weak var delegate: PhotoPickerPageHeaderViewDelegate?
    
    var titles: [String] = [] {
        didSet {
            updateContentView()
        }
    }
    
    var lineView: UIView!
    var bgView: UIToolbar!
    
    var selectedIndex: Int = 0 {
        didSet {
            if titles.isEmpty || selectedIndex < 0 || selectedIndex > titles.count - 1 {
                return
            }
            let button = subviews[selectedIndex + 1] as! UIButton
            if lastBtn == button {
                return
            }
            button.isEnabled = false
            lastBtn?.isEnabled = true
            lastBtn = button
        }
    }
    
    var offsetValue: CGFloat = 0 {
        didSet {
            guard let lineView = lineView, !titles.isEmpty else {
                return
            }
            if offsetValue < 0 || offsetValue > 1 {
                return
            }
            let count = CGFloat(titles.count)
            let viewWidth = width / count
            lineView.centerX = viewWidth * 0.5 + (width - viewWidth) * offsetValue
        }
    }
    
    var lastBtn: UIButton?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        lineView = UIView()
        lineView.backgroundColor = "#FE2443".color
        lineView.size = .init(width: 20, height: 2)
        
        bgView = UIToolbar()
        bgView.barStyle = .black
    }
    
    func updateContentView() {
        subviews.forEach { $0.removeFromSuperview() }
        addSubview(bgView)
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white.withAlphaComponent(0.5), for: .normal)
            button.setTitleColor(.white, for: .disabled)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
            button.addTarget(self, action: #selector(didButtonClick(button:)), for: .touchUpInside)
            button.tag = index
            if index == 0 {
                button.isEnabled = false
                lastBtn = button
            }
            addSubview(button)
        }
        addSubview(lineView)
    }
    
    @objc
    func didButtonClick(button: UIButton) {
        selectedIndex = button.tag
        delegate?.headerView(self, didSelectedButton: selectedIndex)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if titles.isEmpty {
            return
        }
        let count = CGFloat(titles.count)
        let viewWidth = width / count
        for (index, view) in subviews.enumerated() {
            if index == 0 {
                view.frame = .init(x: 0, y: -UIDevice.navigationBarHeight, width: width, height: height + UIDevice.navigationBarHeight)
            } else if index < subviews.count - 1 {
                view.frame = .init(x: viewWidth * CGFloat(index - 1), y: 0, width: viewWidth, height: height)
            }else {
                view.centerX = subviews[selectedIndex + 1].centerX
                view.y = height - view.height - 5
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
