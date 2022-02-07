//
//  EditorToolView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

protocol EditorToolViewDelegate: AnyObject {
    func toolView(_ toolView: EditorToolView, didSelectItemAt model: EditorToolOptions)
    func toolView(didFinishButtonClick toolView: EditorToolView)
}

public class EditorToolScrollView: UICollectionView {
    public override func touchesShouldCancel(in view: UIView) -> Bool {
        true
    }
}

public class EditorToolView: UIView {
    weak var delegate: EditorToolViewDelegate?
    var config: EditorToolViewConfiguration
    
    public lazy var maskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(false)
        return layer
    }()
    
    public lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 15
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.itemSize = CGSize(width: 30, height: 50)
        return flowLayout
    }()
    
    public lazy var collectionView: EditorToolScrollView = {
        let collectionView = EditorToolScrollView(
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
        collectionView.register(EditorToolViewCell.self, forCellWithReuseIdentifier: "EditorToolViewCellID")
        return collectionView
    }()
    
    func reloadContentInset() {
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 12 + UIDevice.leftMargin, bottom: 0, right: 12)
    }
    
    public lazy var finishButton: UIButton = {
        let finishButton = UIButton.init(type: .custom)
        finishButton.setTitle("完成".localized, for: .normal)
        finishButton.titleLabel?.font = UIFont.mediumPingFang(ofSize: 16)
        finishButton.layer.cornerRadius = 3
        finishButton.layer.masksToBounds = true
        finishButton.addTarget(self, action: #selector(didFinishButtonClick(button:)), for: .touchUpInside)
        return finishButton
    }()
    @objc func didFinishButtonClick(button: UIButton) {
        delegate?.toolView(didFinishButtonClick: self)
    }
    var stretchMask: Bool = false
    var currentSelectedIndexPath: IndexPath?
    var musicCellShowBox: Bool = false
    
    init(config: EditorToolViewConfiguration) {
        self.config = config
        super.init(frame: .zero)
        layer.addSublayer(maskLayer)
        addSubview(collectionView)
        addSubview(finishButton)
        configColor()
    }
    func configColor() {
        let isDark = PhotoManager.isDark
        finishButton.setTitleColor(
            isDark ? config.finishButtonTitleDarkColor : config.finishButtonTitleColor,
            for: .normal
        )
        finishButton.setBackgroundImage(
            UIImage.image(
                for: isDark ? config.finishButtonDarkBackgroundColor : config.finishButtonBackgroundColor,
                havingSize: .zero
            ),
            for: .normal
        )
    }
    func deselected() {
        if let indexPath = currentSelectedIndexPath {
            let cell = collectionView.cellForItem(at: indexPath) as? EditorToolViewCell
            cell?.isSelectedImageView = false
            currentSelectedIndexPath = nil
        }
    }
    
    func selected(indexPath: IndexPath) {
        deselected()
        let cell = collectionView.cellForItem(at: indexPath) as? EditorToolViewCell
        cell?.isSelectedImageView = true
        currentSelectedIndexPath = indexPath
    }
    
    func reloadMusic(isSelected: Bool) {
        musicCellShowBox = isSelected
        for (index, option) in config.toolOptions.enumerated() where
            option.type == .music {
            collectionView.reloadItems(
                at: [
                    IndexPath(item: index, section: 0)
                ]
            )
            return
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.frame = CGRect(
            x: 0,
            y: stretchMask ? -70 : -10,
            width: width,
            height: stretchMask ? height + 70 : height + 10
        )
        var finishWidth = (finishButton.currentTitle?.width(
                            ofFont: finishButton.titleLabel!.font,
                            maxHeight: 33) ?? 0) + 20
        if finishWidth < 60 {
            finishWidth = 60
        }
        finishButton.width = finishWidth
        finishButton.height = 33
        finishButton.x = width - finishButton.width - 12 - UIDevice.rightMargin
        finishButton.centerY = 25
        collectionView.width = finishButton.x
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorToolView: UICollectionViewDataSource, UICollectionViewDelegate, EditorToolViewCellDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        config.toolOptions.count
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorToolViewCellID",
            for: indexPath
        ) as! EditorToolViewCell
        let model = config.toolOptions[indexPath.item]
        cell.delegate = self
        cell.boxColor = config.musicSelectedColor
        if model.type == .music {
            cell.showBox = musicCellShowBox
        }else {
            cell.showBox = false
        }
        cell.selectedColor = config.toolSelectedColor
        cell.model = model
        if model.type == .graffiti || model.type == .mosaic {
            if let selectedIndexPath = currentSelectedIndexPath,
               selectedIndexPath.item == indexPath.item {
                cell.isSelectedImageView = true
            }else {
                cell.isSelectedImageView = false
            }
        }else {
            cell.isSelectedImageView = false
        }
        return cell
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: false)
    }
    
    func toolViewCell(didClick cell: EditorToolViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        let option = config.toolOptions[indexPath.item]
        if option.type == .graffiti || option.type == .mosaic {
            if let selectedIndexPath = currentSelectedIndexPath,
               selectedIndexPath.item == indexPath.item {
                deselected()
            }else {
                selected(indexPath: indexPath)
            }
        }
        delegate?.toolView(self, didSelectItemAt: option)
    }
}
