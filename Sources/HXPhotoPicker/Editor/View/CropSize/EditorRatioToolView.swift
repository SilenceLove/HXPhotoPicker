//
//  EditorRatioToolView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/7.
//

import UIKit

protocol EditorRatioToolViewDelegate: AnyObject {
    func ratioToolView(_ ratioToolView: EditorRatioToolView, didSelectedRatioAt ratio: CGSize)
}

class EditorRatioToolView: UIView {
    
    weak var delegate: EditorRatioToolViewDelegate?
    
    private var flowLayout: UICollectionViewFlowLayout!
    private var collectionView: EditorCollectionView!
    
    let ratios: [EditorRatioToolConfig]
    var selectedIndex: Int
    var selectedRatio: EditorRatioToolConfig? {
        if selectedIndex > ratios.count - 1 || selectedIndex < 0 {
            return nil
        }
        return ratios[selectedIndex]
    }
    init(
        ratios: [EditorRatioToolConfig],
        selectedIndex: Int = 0
    ) {
        self.ratios = ratios
        self.selectedIndex = selectedIndex
        super.init(frame: .zero)
        initViews()
    }
    
    var isFirst: Bool = true
    func initViews() {
        flowLayout = UICollectionViewFlowLayout()
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
        collectionView.register(EditorRatioToolViewCell.self, forCellWithReuseIdentifier: "EditorRatioToolViewCellID")
        addSubview(collectionView)
    }
    
    func scrollToFree(animated: Bool) {
        for (index, ratio) in ratios.enumerated() where ratio.ratio == .zero {
            scrollToIndex(at: index, animated: animated)
            return
        }
    }
    
    func scrollToIndex(at index: Int, animated: Bool) {
        if index < 0 {
            deselected()
            return
        }
        selectedIndex = index
        if UIDevice.isPortrait {
            collectionView.selectItem(
                at: .init(item: index, section: 0),
                animated: animated,
                scrollPosition: .centeredHorizontally
            )
        }else {
            collectionView.selectItem(
                at: .init(item: index, section: 0),
                animated: animated,
                scrollPosition: .centeredVertically
            )
        }
    }
    
    func deselected() {
        if selectedIndex < 0 {
            return
        }
        collectionView.deselectItem(at: .init(item: selectedIndex, section: 0), animated: false)
        selectedIndex = -1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.isPortrait {
            var contentWidth = UIDevice.rightMargin + 24
            for (index, ratio) in ratios.enumerated() {
                let itemWidth = ratio.title.text.width(ofFont: .systemFont(ofSize: UIDevice.isPad ? 16 : 14), maxHeight: .max) + 12
                contentWidth += itemWidth
                if index < ratios.count - 1 {
                    contentWidth += 12
                }
            }
            let maxWidth = width
            if contentWidth < maxWidth {
                let collectionX = (maxWidth - contentWidth) * 0.5
                collectionView.frame = .init(x: collectionX, y: 0, width: min(maxWidth, contentWidth), height: height)
            }else {
                collectionView.frame = bounds
            }
            
            flowLayout.scrollDirection = .horizontal
            collectionView.contentInset = .init(
                top: 0,
                left: UIDevice.leftMargin + 12,
                bottom: 0,
                right: UIDevice.rightMargin + 12
            )
        }else {
            collectionView.frame = bounds
            flowLayout.scrollDirection = .vertical
            collectionView.contentInset = .init(top: 12, left: 0, bottom: UIDevice.bottomMargin + 12, right: 0)
        }
        if isFirst {
            if selectedIndex >= 0 && !ratios.isEmpty {
                DispatchQueue.main.async {
                    let scrollPosition: UICollectionView.ScrollPosition
                    if UIDevice.isPortrait {
                        scrollPosition = .centeredHorizontally
                    }else {
                        scrollPosition = .centeredVertically
                    }
                    self.collectionView.selectItem(
                        at: .init(item: self.selectedIndex, section: 0),
                        animated: false,
                        scrollPosition: scrollPosition
                    )
                }
            }
            isFirst = false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorRatioToolView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        ratios.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorRatioToolViewCellID",
            for: indexPath
        ) as! EditorRatioToolViewCell
        cell.config = ratios[indexPath.item]
        cell.updateSelectState(indexPath.item == selectedIndex)
        return cell
    }
}

extension EditorRatioToolView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let ratio = ratios[indexPath.item]
        selectedIndex = indexPath.item
        delegate?.ratioToolView(self, didSelectedRatioAt: ratio.ratio)
        if UIDevice.isPortrait {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }else {
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        if UIDevice.isPortrait {
            return 0
        }
        return 15
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        if UIDevice.isPortrait {
            return 12
        }
        return 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if UIDevice.isPortrait {
            let config = ratios[indexPath.item]
            let itemWidth = config.title.text.width(ofFont: .systemFont(ofSize: UIDevice.isPad ? 16 : 14), maxHeight: .max) + 12
            return .init(width: itemWidth, height: collectionView.height)
        }
        return .init(width: collectionView.width, height: 25)
    }
}
