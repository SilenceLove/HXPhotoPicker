//
//   .swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/9/17.
//

import UIKit

open class PhotoPickerView: UIView {
    public weak var delegate: PhotoPickerViewDelegate?
    public let manager: PickerManager
    
    /// 已选数组
    /// 赋值之后需要 collectionView.reloadData()
    public var selectedAssets: [PhotoAsset] {
        get {
            manager.selectedAssetArray
        }
        set {
            manager.selectedAssetArray = newValue
        }
    }
    
    /// 是否原图，预览界面时选中原图按钮
    public var isOriginal: Bool = false
    
    /// 启用拖动手势
    public var dragEnable: Bool = true {
        didSet {
            panGR.isEnabled = dragEnable
        }
    }
    
    public var contentInset: UIEdgeInsets = .zero {
        didSet {
            collectionView.contentInset = contentInset
        }
    }
    
    public var scrollDirection: UICollectionView.ScrollDirection {
        didSet {
            if oldValue == scrollDirection {
                return
            }
            resetScrollCell()
            if scrollDirection == .horizontal {
                self.horizontalLayout.changing = true
                panGR.isEnabled = dragEnable
            }else {
                self.verticalLayout.changing = true
                panGR.isEnabled = false
            }
            self.collectionView.setCollectionViewLayout(
                scrollDirection == .horizontal ? self.horizontalLayout : self.verticalLayout,
                animated: true
            ) { isFinished in
                if isFinished {
                    if self.scrollDirection == .horizontal {
                        self.horizontalLayout.invalidateLayout()
                        self.horizontalLayout.changing = false
                    }else {
                        self.verticalLayout.invalidateLayout()
                        self.verticalLayout.changing = false
                    }
                    if !self.collectionView.indexPathsForVisibleItems.isEmpty {
                        self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
                    }
                    DispatchQueue.main.async {
                        self.scrollViewDidScroll(self.collectionView)
                    }
                }
            }
            UIView.animate(withDuration: 0.25) {
                self.setupOther()
            }
        }
    }
    
    /// 内容视图
    public var collectionView: UICollectionView!
    
    /// 初始化选择视图
    /// - Parameters:
    ///   - manager: 管理数据
    ///   - scrollDirection: 布局方向
    ///   - delegate: 代理
    public init(
        manager: PickerManager,
        scrollDirection: UICollectionView.ScrollDirection = .vertical,
        delegate: PhotoPickerViewDelegate? = nil
    ) {
        self.manager = manager
        self.scrollDirection = scrollDirection
        isMultipleSelect = manager.config.selectMode == .multiple
        if manager.config.selectMode == .multiple &&
            !manager.config.allowSelectedTogether &&
            manager.config.maximumSelectedVideoCount == 1 &&
            manager.config.selectOptions.isPhoto &&
            manager.config.selectOptions.isVideo &&
            manager.config.photoList.cell.isHiddenSingleVideoSelect {
            videoLoadSingleCell = true
        }else {
            videoLoadSingleCell = false
        }
        super.init(frame: .zero)
        self.delegate = delegate
        initViews()
    }
    
    var verticalLayout: PhotoPickerSwitchLayout!
    var horizontalLayout: PhotoPickerSwitchLayout!
    var emptyView: PhotoPickerEmptyView!
    var deniedView: DeniedAuthorizationView!
    var panGR: UIPanGestureRecognizer!
    var dragView: UIImageView!
    
    var config: PhotoListConfiguration {
        manager.config.photoList
    }
    
    let isMultipleSelect: Bool
    let videoLoadSingleCell: Bool
    var assets: [PhotoAsset] = []
    #if !targetEnvironment(macCatalyst)
    var cameraCell: PickerCameraViewCell {
        var indexPath: IndexPath
        if config.sort == .asc {
            indexPath = IndexPath(item: assets.count, section: 0)
        }else {
            indexPath = IndexPath(item: 0, section: 0)
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NSStringFromClass(
                PickerCameraViewCell.classForCoder()
            ),
            for: indexPath
        ) as! PickerCameraViewCell
        return cell
    }
    #endif
    var limitAddCell: PhotoPickerLimitCell {
        let indexPath: IndexPath
        if config.sort == .asc {
            if canAddCamera {
                indexPath = IndexPath(item: assets.count - 1, section: 0)
            }else {
                indexPath = IndexPath(item: assets.count, section: 0)
            }
        }else {
            if canAddCamera {
                indexPath = IndexPath(item: 1, section: 0)
            }else {
                indexPath = IndexPath(item: 0, section: 0)
            }
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NSStringFromClass(
                PhotoPickerLimitCell.classForCoder()
            ),
            for: indexPath
        ) as! PhotoPickerLimitCell
        cell.config = config.limitCell
        return cell
    }
    
    var dragTempCell: PhotoPickerBaseViewCell?
    var initialDragRect: CGRect = .zero
    var didFetchAsset: Bool = false
    var canAddCamera: Bool {
        #if targetEnvironment(macCatalyst)
        return false
        #else
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            return false
        }
        if didFetchAsset && config.allowAddCamera {
            return true
        }
        return false
        #endif
    }
    var canAddLimit: Bool {
        #if targetEnvironment(macCatalyst)
        return false
        #else
        if didFetchAsset && config.allowAddLimit && AssetPermissionsUtil.isLimitedAuthorizationStatus {
            return true
        }
        return false
        #endif
    }
    var needOffset: Bool {
        if config.sort == .desc {
            if canAddCamera || canAddLimit {
                return true
            }
        }
        return false
    }
    var offsetIndex: Int {
        if !needOffset {
            return 0
        }
        if canAddCamera && canAddLimit {
            return 2
        }else if canAddCamera {
            return 1
        }else {
            return 1
        }
    }
    var allowPreview: Bool = true
    var orientationDidChange: Bool = false
    var beforeOrientationIndexPath: IndexPath?
    var loadingView: PhotoHUDProtocol?
    var isFirst = true
    var scrollIndexPath: IndexPath?
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
        collectionView.contentInset = contentInset
        if orientationDidChange {
            collectionView.reloadData()
            DispatchQueue.main.async {
                if let indexPath = self.beforeOrientationIndexPath {
                    self.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
                }
            }
            orientationDidChange = false
        }
        loadingView?.center = CGPoint(x: width * 0.5, y: height * 0.5)
        setupOther()
    }
    
    func setupOther() {
        emptyView.width = collectionView.width
        emptyView.centerY = collectionView.height * 0.5
        if scrollDirection == .horizontal && config.allowAddCamera {
            let cameraWidth = (height - contentInset.top - contentInset.bottom) / 16 * 9
            let contentWidth = width - contentInset.left - contentInset.right
            emptyView.centerX = cameraWidth + (contentWidth - cameraWidth) * 0.5
        }else {
            emptyView.centerX = collectionView.width * 0.5
        }
        if AssetPermissionsUtil.authorizationStatus == .denied {
            deniedView.frame = bounds
        }
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
