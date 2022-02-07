//
//  PhotoEditorFilterView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/23.
//

import UIKit
import CoreImage

protocol PhotoEditorFilterViewDelegate: AnyObject {
    func filterView(shouldSelectFilter filterView: PhotoEditorFilterView) -> Bool
    func filterView(_ filterView: PhotoEditorFilterView, didSelected filter: PhotoEditorFilter, atItem: Int)
    func filterView(_ filterView: PhotoEditorFilterView, didChanged value: Float)
    func filterView(_ filterView: PhotoEditorFilterView, touchUpInside value: Float)
}

class PhotoEditorFilterView: UIView {
    
    weak var delegate: PhotoEditorFilterViewDelegate?
    
    lazy var backgroundView: UIVisualEffectView = {
        let visualEffect = UIBlurEffect.init(style: .dark)
        let view = UIVisualEffectView.init(effect: visualEffect)
        view.contentView.addSubview(collectionView)
        return view
    }()
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 5
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.itemSize = CGSize(width: 60, height: 100)
        return flowLayout
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: CGRect(x: 0, y: 0, width: 0, height: 50),
            collectionViewLayout: flowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(
            PhotoEditorFilterViewCell.self,
            forCellWithReuseIdentifier: "PhotoEditorFilterViewCellID"
        )
        return collectionView
    }()
    
    lazy var sliderView: PhotoEditorFilterSlider = {
        let slider = PhotoEditorFilterSlider.init()
        slider.isHidden = true
        slider.maximumTrackTintColor = .white.withAlphaComponent(0.4)
        slider.minimumTrackTintColor = .white
        let image = UIImage.image(for: .white, havingSize: CGSize(width: 20, height: 20), radius: 10)
        slider.setThumbImage(image, for: .normal)
        slider.setThumbImage(image, for: .highlighted)
        slider.layer.shadowColor = UIColor.black.withAlphaComponent(0.4).cgColor
        slider.layer.shadowRadius = 4
        slider.layer.shadowOpacity = 0.5
        slider.layer.shadowOffset = CGSize(width: 0, height: 0)
        slider.addTarget(
            self,
            action: #selector(sliderDidChanged(slider:)),
            for: .valueChanged
        )
        slider.addTarget(
            self,
            action: #selector(sliderTouchUpInside(slider:)),
            for: [
                .touchUpInside,
                .touchCancel,
                .touchUpOutside
            ]
        )
        return slider
    }()
    
    @objc func sliderDidChanged(slider: UISlider) {
        if currentSelectedIndex < 0 {
            return
        }
        if filters[currentSelectedIndex].isOriginal {
            return
        }
        delegate?.filterView(self, didChanged: slider.value)
    }
    
    @objc func sliderTouchUpInside(slider: UISlider) {
        if currentSelectedIndex < 0 {
            return
        }
        if filters[currentSelectedIndex].isOriginal {
            return
        }
        delegate?.filterView(self, touchUpInside: slider.value)
    }
    var filters: [PhotoEditorFilter] = []
    var image: UIImage? = nil {
        didSet {
            collectionView.reloadData()
            scrollToSelectedCell()
        }
    }
    var currentSelectedIndex: Int
    let filterConfig: PhotoEditorConfiguration.Filter
    init(
        filterConfig: PhotoEditorConfiguration.Filter,
        hasLastFilter: Bool,
        isVideo: Bool = false
    ) {
        self.filterConfig = filterConfig
        let originalFilter = PhotoEditorFilter(
            filterName: isVideo ? "原片".localized : "原图".localized,
            defaultValue: -1
        )
        originalFilter.isOriginal = true
        originalFilter.isSelected = true
        filters.append(originalFilter)
        currentSelectedIndex = 0
        super.init(frame: .zero)
        if hasLastFilter {
            originalFilter.isSelected = false
            currentSelectedIndex = -1
        }
        for filterInfo in filterConfig.infos {
            let filter = PhotoEditorFilter(
                filterName: filterInfo.filterName,
                defaultValue: filterInfo.defaultValue
            )
//            if sourceIndex == index {
//                originalFilter.isSelected = false
//                filter.isSelected = true
//                currentSelectedIndex = index + 1
//                if filterInfo.defaultValue == -1 {
//                    sliderView.isHidden = true
//                }else {
//                    sliderView.isHidden = false
//                    sliderView.value = value
//                }
//            }
            filters.append(filter)
        }
        addSubview(backgroundView)
        addSubview(sliderView)
    }
    func scrollToSelectedCell() {
        if currentSelectedIndex > 0 {
            collectionView.scrollToItem(
                at: IndexPath(
                    item: currentSelectedIndex,
                    section: 0
                ),
                at: .centeredHorizontally,
                animated: true
            )
        }
    }
    func currentSelectedCell() -> PhotoEditorFilterViewCell? {
        collectionView.cellForItem(at: IndexPath(item: currentSelectedIndex, section: 0)) as? PhotoEditorFilterViewCell
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        sliderView.frame = CGRect(
            x: UIDevice.leftMargin + 20,
            y: 0,
            width: width - 40 - UIDevice.leftMargin - UIDevice.rightMargin,
            height: 20
        )
        backgroundView.frame = CGRect(
            x: 0,
            y: 30,
            width: width,
            height: 120 + UIDevice.bottomMargin
        )
        collectionView.frame = CGRect(x: 0, y: 0, width: width, height: 120)
        flowLayout.sectionInset = UIEdgeInsets(
            top: 10,
            left: 15 + UIDevice.leftMargin,
            bottom: 0,
            right: 15 + UIDevice.rightMargin
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PhotoEditorFilterView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filters.count
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "PhotoEditorFilterViewCellID",
            for: indexPath
        ) as! PhotoEditorFilterViewCell
        cell.delegate = self
        cell.imageView.image = image
        cell.selectedColor = filterConfig.selectedColor
        cell.filter = filters[indexPath.item]
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
        ) as? PhotoEditorFilterViewCell {
            currentCell.updateSelectedView(true)
        }else {
            collectionView.reloadItems(at: [IndexPath(item: currentSelectedIndex, section: 0)])
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoEditorFilterViewCell {
            cell.filter.isSelected = true
            cell.filter.sourceIndex = indexPath.item - 1
            cell.updateSelectedView(false)
            if cell.filter.defaultValue == -1 {
                sliderView.isHidden = true
            }else {
                sliderView.isHidden = false
                sliderView.value = cell.filter.defaultValue
            }
            delegate?.filterView(self, didSelected: cell.filter, atItem: indexPath.item - 1)
        }
        currentSelectedIndex = indexPath.item
    }
}

extension PhotoEditorFilterView: PhotoEditorFilterViewCellDelegate {
    func filterViewCell(fetchFilter cell: PhotoEditorFilterViewCell) -> UIImage? {
        if let image = image?.ci_Image,
           let index = filters.firstIndex(of: cell.filter) {
            let filterInfo = filterConfig.infos[index - 1]
            return filterInfo.filterHandler(image,
                                            cell.imageView.image,
                                            filterInfo.defaultValue,
                                            .touchUpInside)?.image
        }
        return nil
    }
}

protocol PhotoEditorFilterViewCellDelegate: AnyObject {
    func filterViewCell(fetchFilter cell: PhotoEditorFilterViewCell) -> UIImage?
}

class PhotoEditorFilterViewCell: UICollectionViewCell {
    weak var delegate: PhotoEditorFilterViewCellDelegate?
    lazy var imageView: UIImageView = {
        let view = UIImageView.init()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    lazy var filterNameLb: UILabel = {
        let label = UILabel.init()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var selectedView: UIView = {
        let view = UIView.init()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.red.cgColor
        view.layer.cornerRadius = 4
        return view
    }()
    
    var selectedColor: UIColor? {
        didSet {
            selectedView.layer.borderColor = selectedColor?.cgColor
        }
    }
    var filter: PhotoEditorFilter! {
        didSet {
            filterNameLb.text = filter.filterName
            selectedView.isHidden = !filter.isSelected
            if !filter.isOriginal {
                imageView.image = delegate?.filterViewCell(fetchFilter: self)
            }
        }
    }
    
    func updateSelectedView(_ isHidden: Bool) {
        selectedView.isHidden = isHidden
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(selectedView)
        contentView.addSubview(filterNameLb)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: 4, y: 4, width: width - 8, height: width - 8)
        selectedView.frame = CGRect(x: 0, y: 0, width: width, height: width)
        let filterNameY = imageView.frame.maxY + 12
        var filterNameHeight = filterNameLb.text?.height(ofFont: filterNameLb.font, maxWidth: width) ?? 15
        if filterNameHeight > height - filterNameY {
            filterNameHeight = height - filterNameY
        }
        filterNameLb.frame = CGRect(x: 0, y: filterNameY, width: width, height: filterNameHeight)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PhotoEditorFilterSlider: UISlider {
    override func minimumValueImageRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(x: 0, y: (bounds.height - 3) * 0.5, width: bounds.width, height: 3)
    }
    override func maximumValueImageRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(x: 0, y: (bounds.height - 3) * 0.5, width: bounds.width, height: 3)
    }
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.trackRect(forBounds: bounds)
        return CGRect(x: rect.minX, y: (bounds.height - 3) * 0.5, width: rect.width, height: 3)
    }
}
