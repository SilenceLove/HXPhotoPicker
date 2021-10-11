//
//   .swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/17.
//

import UIKit

open class PhotoPickerView: UIView {
    public weak var delegate: PhotoPickerViewDelegate?
    public let manager: PickerManager
    
    /// 已选数组
    /// 需要reload
    public var selectedAssets: [PhotoAsset] {
        get {
            manager.selectedAssetArray
        }
        set {
            manager.selectedAssetArray = newValue
        }
    }
    
    /// 是否原图，预览界面是的选中原图按钮
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
            manager.config.selectOptions.isVideo {
            videoLoadSingleCell = true
        }else {
            videoLoadSingleCell = false
        }
        super.init(frame: .zero)
        self.delegate = delegate
        setup()
    }
    public lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: bounds,
            collectionViewLayout: scrollDirection == .vertical ? verticalLayout : horizontalLayout
        )
        collectionView.dataSource = self
        collectionView.delegate = self
        if let customSingleCellClass = config.cell.customSingleCellClass {
            collectionView.register(
                customSingleCellClass,
                forCellWithReuseIdentifier:
                    NSStringFromClass(
                        PhotoPickerViewCell.classForCoder()
                    )
            )
        }else {
            collectionView.register(
                PhotoPickerViewCell.self,
                forCellWithReuseIdentifier:
                    NSStringFromClass(
                        PhotoPickerViewCell.classForCoder()
                    )
            )
        }
        if let customSelectableCellClass = config.cell.customSelectableCellClass {
            collectionView.register(
                customSelectableCellClass,
                forCellWithReuseIdentifier:
                    NSStringFromClass(
                        PhotoPickerSelectableViewCell.classForCoder()
                    )
            )
        }else {
            collectionView.register(
                PhotoPickerSelectableViewCell.self,
                forCellWithReuseIdentifier:
                    NSStringFromClass(
                        PhotoPickerSelectableViewCell.classForCoder()
                    )
            )
        }
        if config.allowAddCamera {
            collectionView.register(
                PickerCamerViewCell.self,
                forCellWithReuseIdentifier:
                    NSStringFromClass(PickerCamerViewCell.classForCoder())
            )
        }
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        return collectionView
    }()
    lazy var verticalLayout: PhotoPickerSwitchLayout = {
        let layout = PhotoPickerSwitchLayout()
        layout.scrollDirection = .vertical
        return layout
    }()
    lazy var horizontalLayout: PhotoPickerSwitchLayout = {
        let layout = PhotoPickerSwitchLayout()
        layout.scrollDirection = .horizontal
        return layout
    }()
    var config: PhotoListConfiguration {
        manager.config.photoList
    }
    let isMultipleSelect: Bool
    let videoLoadSingleCell: Bool
    var assets: [PhotoAsset] = []
    var cameraCell: PickerCamerViewCell {
        var indexPath: IndexPath
        if config.sort == .asc {
            indexPath = IndexPath(item: assets.count, section: 0)
        }else {
            indexPath = IndexPath(item: 0, section: 0)
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NSStringFromClass(
                PickerCamerViewCell.classForCoder()
            ),
            for: indexPath
        ) as! PickerCamerViewCell
        return cell
    }
    
    lazy var emptyView: EmptyView = {
        let emptyView = EmptyView(frame: .zero)
        emptyView.config = config.emptyView
        return emptyView
    }()
    lazy var deniedView: DeniedAuthorizationView = {
        var config = manager.config.notAuthorized
        config.hiddenCloseButton = true
        let deniedView = DeniedAuthorizationView(config: config)
        return deniedView
    }()
    lazy var panGR: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerClick(pan:)))
        if scrollDirection == .horizontal {
            pan.isEnabled = dragEnable
        }else {
            pan.isEnabled = false
        }
        return pan
    }()
    lazy var dragView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    var dragTempCell: PhotoPickerBaseViewCell?
    var initialDragRect: CGRect = .zero
    var needOffset: Bool {
        config.sort == .desc &&
            config.allowAddCamera &&
            canAddCamera
    }
    var canAddCamera: Bool = false
    var allowPreview: Bool = true
    var orientationDidChange: Bool = false
    var beforeOrientationIndexPath: IndexPath?
    var loadingView: ProgressHUD?
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
        if AssetManager.authorizationStatus() == .denied {
            deniedView.frame = bounds
        }
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
//        print("deinit:\(self)")
    }
}
