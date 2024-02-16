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
    
    private var flowLayout: UICollectionViewFlowLayout!
    private var collectionView: EditorCollectionView!
    
    private var loaddingView: UIActivityIndicatorView!
    private var loadQueue: OperationQueue!
    
    var loadCompletion: ((EditorFiltersView) -> Void)?
    var didLoad: Bool = false
    var image: UIImage?
    var filters: [PhotoEditorFilter] = []
    var currentSelectedIndex: Int = 0
    let filterConfig: EditorConfiguration.Filter
    init(
        filterConfig: EditorConfiguration.Filter
    ) {
        self.filterConfig = filterConfig
        super.init(frame: .zero)
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 60, height: 90)
        flowLayout.minimumLineSpacing = 5
        flowLayout.minimumInteritemSpacing = 0
        collectionView = EditorCollectionView(
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
        addSubview(collectionView)
        loaddingView = UIActivityIndicatorView(style: .white)
        loaddingView.hidesWhenStopped = true
        loadQueue = OperationQueue()
        loadQueue.maxConcurrentOperationCount = 1
    }
    
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
        if Thread.isMainThread {
            loaddingView.startAnimating()
            addSubview(loaddingView)
            
            let operation = BlockOperation()
            operation.addExecutionBlock { [unowned operation, weak self] in
                guard let self = self else { return }
                if operation.isCancelled { return }
                self.image = originalImage.scaleToFillSize(size: CGSize(width: 80, height: 80), mode: .center)
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
            operation.addExecutionBlock { [unowned operation, weak self] in
                guard let self = self else { return }
                if operation.isCancelled { return }
                self.image = originalImage.scaleToFillSize(size: CGSize(width: 80, height: 80))
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
            filterName: isVideo ? .textManager.editor.filter.originalVideoTitle.text : .textManager.editor.filter.originalPhotoTitle.text
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
        if !didLoad {
            return nil
        }
        return collectionView.cellForItem(
            at: IndexPath(item: currentSelectedIndex, section: 0)
        ) as? EditorFiltersViewCell
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
            cell.image = image
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
                cell.image,
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
    
    var image: UIImage? {
        get {
            imageView.image
        }
        set {
            imageView.image = newValue
        }
    }
    
    private var imageView: UIImageView!
    private var filterNameLb: UILabel!
    private var selectedView: UIView!
    private var editButton: UIButton!
    private var parameterLb: UILabel!
    
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
    }
    
    private func initViews() {
        imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        contentView.addSubview(imageView)
        selectedView = UIView()
        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        selectedView.layer.borderWidth = 2
        selectedView.layer.borderColor = UIColor.red.cgColor
        selectedView.layer.cornerRadius = 4
        contentView.addSubview(selectedView)
        editButton = UIButton(type: .custom)
        editButton.setImage(.imageResource.editor.filter.edit.image, for: .normal)
        editButton.addTarget(self, action: #selector(didEditButtonClick), for: .touchUpInside)
        contentView.addSubview(editButton)
        filterNameLb = UILabel()
        filterNameLb.textColor = .white
        filterNameLb.font = .textManager.editor.filter.nameFont
        filterNameLb.textAlignment = .center
        filterNameLb.adjustsFontSizeToFitWidth = true
        contentView.addSubview(filterNameLb)
        parameterLb = UILabel()
        parameterLb.text = "0"
        parameterLb.textColor = .white
        parameterLb.font = .textManager.editor.filter.parameterFont
        parameterLb.textAlignment = .center
        parameterLb.isHidden = true
        contentView.addSubview(parameterLb)
    }
    
    @objc
    private func didEditButtonClick() {
        delegate?.filterViewCell(didEdit: self)
    }
    
    func updateFilter() {
        filterNameLb.text = filter.filterName.localized
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
