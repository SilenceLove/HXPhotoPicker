//
//  EditorFiltersView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/9.
//

import UIKit

protocol EditorFiltersViewDelegate: AnyObject {
    func filterView(shouldSelectFilter filterView: EditorFiltersView) -> Bool
    func filterView(_ filterView: EditorFiltersView, didSelected filter: PhotoEditorFilter, atItem: Int)
    func filterView(_ filterView: EditorFiltersView, didSelectedParameter filter: PhotoEditorFilter, at index: Int)
}

class EditorFiltersView: UIView {
    
    weak var delegate: EditorFiltersViewDelegate?
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 60, height: 90)
        flowLayout.minimumLineSpacing = 5
        flowLayout.minimumInteritemSpacing = 0
        return flowLayout
    }()
    
    lazy var collectionView: EditorCollectionView = {
        let collectionView = EditorCollectionView(
            frame: CGRect(x: 0, y: 0, width: 0, height: 50),
            collectionViewLayout: flowLayout
        )
        collectionView.delaysContentTouches = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(
            EditorFiltersViewCell.self,
            forCellWithReuseIdentifier: "EditorFiltersViewCellID"
        )
        return collectionView
    }()
    
    var image: UIImage? = nil
    
    var filters: [PhotoEditorFilter] = []
    var currentSelectedIndex: Int = 0
    var filterConfig: EditorConfiguration.Filter
    init(
        filterConfig: EditorConfiguration.Filter
    ) {
        self.filterConfig = filterConfig
        super.init(frame: .zero)
        addSubview(collectionView)
    }
    
    var didLoad: Bool = false
    
    lazy var loaddingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .white)
        view.hidesWhenStopped = true
        return view
    }()
    
    lazy var loadQueue: OperationQueue = {
        let loadQueue = OperationQueue()
        loadQueue.maxConcurrentOperationCount = 1
        return loadQueue
    }()
    
    var loadCompletion: ((EditorFiltersView) -> Void)?
    
    func loadFilters(
        originalImage: UIImage,
        selectedIndex: Int = 0,
        isVideo: Bool = false
    ) {
        if didLoad {
            DispatchQueue.main.async {
                self.updateFilters(selectedIndex: selectedIndex, isVideo: isVideo)
                self.loadCompletion?(self)
            }
            return
        }
        loadQueue.cancelAllOperations()
        if DispatchQueue.isMain {
            loaddingView.startAnimating()
            addSubview(loaddingView)
            
            let operation = BlockOperation()
            operation.addExecutionBlock { [unowned operation] in
                if operation.isCancelled { return }
                self.image = originalImage.scaleToFillSize(size: CGSize(width: 80, height: 80), equalRatio: true)
                if operation.isCancelled { return }
                DispatchQueue.main.async {
                    self.didLoad = true
                    self.updateFilters(selectedIndex: selectedIndex, isVideo: isVideo)
                    self.loadCompletion?(self)
                }
            }
            loadQueue.addOperation(operation)
        }else {
            DispatchQueue.main.async {
                self.loaddingView.startAnimating()
                self.addSubview(self.loaddingView)
            }
            let operation = BlockOperation()
            operation.addExecutionBlock { [unowned operation] in
                if operation.isCancelled { return }
                self.image = originalImage.scaleToFillSize(size: CGSize(width: 80, height: 80), equalRatio: true)
                if operation.isCancelled { return }
                DispatchQueue.main.async {
                    self.didLoad = true
                    self.updateFilters(selectedIndex: selectedIndex, isVideo: isVideo)
                    self.loadCompletion?(self)
                }
            }
            loadQueue.addOperation(operation)
        }
    }
    
    func updateFilters(
        selectedIndex: Int = 0,
        selectedParameters: [PhotoEditorFilterParameterInfo] = [],
        isVideo: Bool = false
    ) {
        loaddingView.removeFromSuperview()
        let filterInfos = filterConfig.infos
        filters = []
        let originalFilter = PhotoEditorFilter(
            filterName: isVideo ? "原片".localized : "原图".localized
        )
        originalFilter.isOriginal = true
        if selectedIndex == 0 {
            originalFilter.isSelected = true
        }
        filters.append(originalFilter)
        currentSelectedIndex = selectedIndex
        for (index, filterInfo) in filterInfos.enumerated() {
            var parameters: [PhotoEditorFilterParameterInfo] = []
            if index + 1 == currentSelectedIndex && !selectedParameters.isEmpty {
                parameters = selectedParameters
            }else {
                for parameter in filterInfo.parameters {
                    parameters.append(.init(parameter: parameter))
                }
            }
            let filter = PhotoEditorFilter(
                filterName: filterInfo.filterName,
                identifier: filterConfig.identifier,
                parameters: parameters
            )
            filter.sourceIndex = index
            filters.append(filter)
            if filters.count - 1 == currentSelectedIndex {
                filter.isSelected = true
            }
        }
        collectionView.reloadData()
        scrollToSelectedCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func reloadData() {
        currentSelectedCell()?.updateParameter()
    }
    func scrollToSelectedCell() {
        if currentSelectedIndex > 0 && didLoad {
            DispatchQueue.main.async {
                self.collectionView.scrollToItem(
                    at: IndexPath(
                        item: self.currentSelectedIndex,
                        section: 0
                    ),
                    at: UIDevice.isPortrait ? .centeredHorizontally : .centeredVertically,
                    animated: true
                )
            }
        }
    }
    func currentSelectedCell() -> EditorFiltersViewCell? {
        didLoad ? collectionView.cellForItem(at: IndexPath(item: currentSelectedIndex, section: 0)) as? EditorFiltersViewCell : nil
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.isPortrait {
            let count = CGFloat(filters.count)
            let contentWidth = 60 * count + 5 * (count - 1) + UIDevice.rightMargin + 30
            let maxWidth = width
            if contentWidth < maxWidth {
                let collectionX = (maxWidth - contentWidth) * 0.5
                collectionView.frame = .init(x: collectionX, y: 0, width: min(maxWidth, contentWidth), height: height)
            }else {
                collectionView.frame = bounds
            }
            flowLayout.scrollDirection = .horizontal
            flowLayout.sectionInset = UIEdgeInsets(
                top: 10,
                left: 15 + UIDevice.leftMargin,
                bottom: 0,
                right: 15 + UIDevice.rightMargin
            )
        }else {
            collectionView.frame = bounds
            flowLayout.scrollDirection = .vertical
            flowLayout.sectionInset = UIEdgeInsets(
                top: 15,
                left: 10,
                bottom: 15 + UIDevice.bottomMargin,
                right: 0
            )
        }
        loaddingView.center = collectionView.center
    }
}

extension EditorFiltersView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        didLoad ? filters.count : 0
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorFiltersViewCellID",
            for: indexPath
        ) as! EditorFiltersViewCell
        cell.delegate = self
        let filter = filters[indexPath.item]
        if filter.isOriginal {
            cell.imageView.image = image
        }
        cell.selectedColor = filterConfig.selectedColor
        cell.filter = filter
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        if let shouldSelect = delegate?.filterView(shouldSelectFilter: self), !shouldSelect {
            return
        }
        if currentSelectedIndex == indexPath.item {
            return
        }
        if currentSelectedIndex >= 0 {
            let currentFilter = filters[currentSelectedIndex]
            currentFilter.sourceIndex = 0
            currentFilter.isSelected = false
        }
        if let currentCell = collectionView.cellForItem(
            at: IndexPath(
                item: currentSelectedIndex,
                section: 0
            )
        ) as? EditorFiltersViewCell {
            currentCell.updateSelectedView(true)
            currentCell.updateParameter()
        }else {
            collectionView.reloadItems(at: [IndexPath(item: currentSelectedIndex, section: 0)])
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? EditorFiltersViewCell {
            cell.filter.isSelected = true
            cell.filter.sourceIndex = indexPath.item - 1
            cell.updateSelectedView(false)
            cell.updateParameter()
            delegate?.filterView(self, didSelected: cell.filter, atItem: indexPath.item - 1)
        }
        currentSelectedIndex = indexPath.item
    }
}

extension EditorFiltersView: EditorFiltersViewCellDelegate {
    func filterViewCell(fetchFilter cell: EditorFiltersViewCell) -> UIImage? {
        guard let index = filters.firstIndex(of: cell.filter) else {
            return nil
        }
        let filterInfo = filterConfig.infos[index - 1]
        if let handler = filterInfo.filterHandler, let image = image?.ci_Image {
            return handler(
                image,
                cell.imageView.image,
                cell.filter.parameters,
                true
            )?.image
        }else {
            
        }
        return nil
    }
    
    func filterViewCell(didEdit cell: EditorFiltersViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        delegate?.filterView(self, didSelectedParameter: cell.filter, at: indexPath.item)
    }
}

protocol EditorFiltersViewCellDelegate: AnyObject {
    func filterViewCell(fetchFilter cell: EditorFiltersViewCell) -> UIImage?
    func filterViewCell(didEdit cell: EditorFiltersViewCell)
}

class EditorFiltersViewCell: UICollectionViewCell {
    weak var delegate: EditorFiltersViewCellDelegate?
    
    lazy var imageView: UIImageView = {
        let view = UIImageView.init()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    lazy var filterNameLb: UILabel = {
        let label = UILabel.init()
        label.textColor = .white
        label.font = .regularPingFang(ofSize: 13)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    lazy var selectedView: UIView = {
        let view = UIView.init()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.red.cgColor
        view.layer.cornerRadius = 4
        return view
    }()
    
    lazy var editButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage("hx_editor_tools_filter_edit".image, for: .normal)
        button.addTarget(self, action: #selector(didEditButtonClick), for: .touchUpInside)
        return button
    }()
    
    @objc
    func didEditButtonClick() {
        delegate?.filterViewCell(didEdit: self)
    }
    
    lazy var parameterLb: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.textColor = .white
        label.font = .regularPingFang(ofSize: 11)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    var selectedColor: UIColor? {
        didSet {
            selectedView.layer.borderColor = selectedColor?.cgColor
            selectedView.backgroundColor = selectedColor?.withAlphaComponent(0.25)
        }
    }
    var filter: PhotoEditorFilter! {
        didSet {
            updateFilter()
        }
    }
    
    func updateFilter() {
        filterNameLb.text = filter.filterName
        if !filter.isOriginal {
            imageView.image = delegate?.filterViewCell(fetchFilter: self)
        }
        updateSelectedView(!filter.isSelected)
        updateParameter()
    }
    
    func updateParameter() {
        if let para = filter.parameters.first, filter.isSelected {
            parameterLb.isHidden = false
            parameterLb.text = String(Int(para.value * 100))
        }else {
            parameterLb.isHidden = true
        }
    }
    
    func updateSelectedView(_ isHidden: Bool) {
        selectedView.isHidden = isHidden
        if !filter.parameters.isEmpty {
            editButton.isHidden = isHidden
        }else {
            editButton.isHidden = true
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(selectedView)
        contentView.addSubview(editButton)
        contentView.addSubview(filterNameLb)
        contentView.addSubview(parameterLb)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: 4, y: 4, width: width - 8, height: width - 8)
        editButton.frame = imageView.frame
        selectedView.frame = CGRect(x: 0, y: 0, width: width, height: width)
        let filterNameY = imageView.frame.maxY + 12
        let filterNameHeight = filterNameLb.text?.height(ofFont: filterNameLb.font, maxWidth: .max) ?? 15
        filterNameLb.frame = CGRect(x: 0, y: filterNameY, width: width, height: filterNameHeight)
        parameterLb.y = filterNameLb.frame.maxY + 2
        parameterLb.width = width
        parameterLb.height = 12
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
