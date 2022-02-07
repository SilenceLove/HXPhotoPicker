//
//  PhotoEditorCropToolView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/4/15.
//

import UIKit

protocol PhotoEditorCropToolViewDelegate: AnyObject {
    func cropToolView(didRotateButtonClick cropToolView: PhotoEditorCropToolView)
    func cropToolView(didMirrorHorizontallyButtonClick cropToolView: PhotoEditorCropToolView)
    func cropToolView(didChangedAspectRatio cropToolView: PhotoEditorCropToolView, at model: PhotoEditorCropToolModel)
}

public class PhotoEditorCropToolView: UIView {
    weak var delegate: PhotoEditorCropToolViewDelegate?
    public lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 20
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 10)
        flowLayout.scrollDirection = .horizontal
        return flowLayout
    }()
    public lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView.init(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(
            PhotoEditorCropToolViewCell.classForCoder(),
            forCellWithReuseIdentifier: "PhotoEditorCropToolViewCellID"
        )
        collectionView.register(
            PhotoEditorCropToolHeaderView.classForCoder(),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "PhotoEditorCropToolHeaderViewID"
        )
        return collectionView
    }()
    
    let ratioModels: [PhotoEditorCropToolModel]
    var showRatios: Bool
    var themeColor: UIColor?
    var currentSelectedModel: PhotoEditorCropToolModel?
    init(
        showRatios: Bool,
        scaleArray: [[Int]]
    ) {
        self.showRatios = showRatios
        var ratioModels: [PhotoEditorCropToolModel] = []
        for ratioArray in scaleArray {
            let model = PhotoEditorCropToolModel.init()
            model.widthRatio = CGFloat(ratioArray.first!)
            model.heightRatio = CGFloat(ratioArray.last!)
            if ratioModels.count == 0 {
                model.isSelected = true
                currentSelectedModel = model
            }
            ratioModels.append(model)
        }
        self.ratioModels = ratioModels
        super.init(frame: .zero)
        
        addSubview(collectionView)
    }
    func updateContentInset() {
        collectionView.contentInset = UIEdgeInsets(
            top: 0,
            left: UIDevice.leftMargin,
            bottom: 0,
            right: UIDevice.rightMargin
        )
    }
    func reset(animated: Bool) {
        currentSelectedModel?.isSelected = false
        currentSelectedModel = ratioModels.first
        currentSelectedModel?.isSelected = true
        collectionView.reloadData()
        collectionView.setContentOffset(CGPoint(x: -collectionView.contentInset.left, y: 0), animated: animated)
    }
    public override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PhotoEditorCropToolView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        showRatios ? ratioModels.count : 0
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "PhotoEditorCropToolViewCellID",
            for: indexPath
        ) as! PhotoEditorCropToolViewCell
        cell.themeColor = themeColor
        cell.model = ratioModels[indexPath.item]
        return cell
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "PhotoEditorCropToolHeaderViewID",
            for: indexPath
        ) as! PhotoEditorCropToolHeaderView
        headerView.delegate = self
        headerView.showRatios = showRatios
        return headerView
    }
}
extension PhotoEditorCropToolView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let model = ratioModels[indexPath.item]
        if !model.scaleSize.equalTo(.zero) {
            return model.scaleSize
        }
        let scaleWidth: CGFloat = 38
        if model.widthRatio == 0 || model.widthRatio == 1 {
            model.size = .init(width: 28, height: 28)
            model.scaleSize = .init(width: 28, height: scaleWidth)
        }else {
            let scale = scaleWidth / model.widthRatio
            var itemWidth = model.widthRatio * scale
            var itemHeight = model.heightRatio * scale
            if itemHeight > scaleWidth {
                itemHeight = scaleWidth
                itemWidth = scaleWidth / model.heightRatio * model.widthRatio
            }
            model.size = .init(width: itemWidth, height: itemHeight)
            if itemHeight < scaleWidth {
                itemHeight = scaleWidth
            }
            let textWidth = model.scaleText.width(
                ofFont: UIFont.mediumPingFang(ofSize: 12),
                maxHeight: itemHeight - 3
            ) + 5
            if itemWidth < textWidth {
                itemHeight = textWidth / itemWidth * itemHeight
                itemWidth = textWidth
                if itemHeight > 45 {
                    itemHeight = 45
                }
                model.size = .init(width: itemWidth, height: itemHeight)
            }
            model.scaleSize = .init(width: itemWidth, height: itemHeight)
        }
        return model.scaleSize
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(width: 100, height: 50)
    }
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var selectedIndexPath: IndexPath?
        if let model = currentSelectedModel {
            let index = ratioModels.firstIndex(of: model)!
            if index == indexPath.item {
                return
            }
            selectedIndexPath = IndexPath(item: index, section: 0)
        }
        currentSelectedModel?.isSelected = false
        let model = ratioModels[indexPath.item]
        model.isSelected = true
        currentSelectedModel = model
        var reloadIndexPaths: [IndexPath] = []
        reloadIndexPaths.append(indexPath)
        if selectedIndexPath != nil {
            reloadIndexPaths.append(selectedIndexPath!)
        }
        collectionView.reloadItems(at: reloadIndexPaths)
        delegate?.cropToolView(didChangedAspectRatio: self, at: model)
    }
}

extension PhotoEditorCropToolView: PhotoEditorCropToolHeaderViewDelegate {
    func headerView(didRotateButtonClick headerView: PhotoEditorCropToolHeaderView) {
        delegate?.cropToolView(didRotateButtonClick: self)
    }
    func headerView(didMirrorHorizontallyButtonClick headerView: PhotoEditorCropToolHeaderView) {
        delegate?.cropToolView(didMirrorHorizontallyButtonClick: self)
    }
}

protocol PhotoEditorCropToolHeaderViewDelegate: AnyObject {
    func headerView(didRotateButtonClick headerView: PhotoEditorCropToolHeaderView)
    func headerView(didMirrorHorizontallyButtonClick headerView: PhotoEditorCropToolHeaderView)
}

class PhotoEditorCropToolHeaderView: UICollectionReusableView {
    
    weak var delegate: PhotoEditorCropToolHeaderViewDelegate?
    
    lazy var rotateButton: UIButton = {
        let button = UIButton.init(type: .system)
        button.setImage("hx_editor_photo_rotate".image, for: .normal)
        button.size = button.currentImage?.size ?? .zero
        button.tintColor = .white
        button.addTarget(self, action: #selector(didRotateButtonClick(button:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didRotateButtonClick(button: UIButton) {
        delegate?.headerView(didRotateButtonClick: self)
    }
    
    lazy var mirrorHorizontallyButton: UIButton = {
        let button = UIButton.init(type: .system)
        button.setImage("hx_editor_photo_mirror_horizontally".image, for: .normal)
        button.size = button.currentImage?.size ?? .zero
        button.tintColor = .white
        button.addTarget(self, action: #selector(didMirrorHorizontallyButtonClick(button:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didMirrorHorizontallyButtonClick(button: UIButton) {
        delegate?.headerView(didMirrorHorizontallyButtonClick: self)
    }
    
    lazy var lineView: UIView = {
        let view = UIView.init(frame: .init(x: 0, y: 0, width: 2, height: 20))
        view.backgroundColor = .white
        return view
    }()
    var showRatios: Bool = true {
        didSet {
            lineView.isHidden = !showRatios
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(rotateButton)
        addSubview(mirrorHorizontallyButton)
        addSubview(lineView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        rotateButton.centerY = height * 0.5
        rotateButton.x = 20
        
        mirrorHorizontallyButton.x = rotateButton.frame.maxX + 10
        mirrorHorizontallyButton.centerY = rotateButton.centerY
        
        lineView.x = width - 2
        lineView.centerY = mirrorHorizontallyButton.centerY
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PhotoEditorCropToolViewCell: UICollectionViewCell {
    
    lazy var scaleView: UIView = {
        let view = UIView.init()
        view.layer.cornerRadius = 2
        view.addSubview(scaleImageView)
        view.addSubview(scaleLabel)
        return view
    }()
    
    lazy var scaleImageView: UIImageView = {
        let imageView = UIImageView.init(image: "hx_editor_photo_crop_free".image?.withRenderingMode(.alwaysTemplate))
        return imageView
    }()
    
    lazy var scaleLabel: UILabel = {
        let label = UILabel.init()
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.mediumPingFang(ofSize: 12)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    var themeColor: UIColor?
    var model: PhotoEditorCropToolModel! {
        didSet {
            updateViewFrame()
            scaleLabel.text = model.scaleText
            if model.widthRatio == 0 {
                scaleView.layer.borderWidth = 0
                scaleImageView.isHidden = false
            }else {
                scaleView.layer.borderWidth = 1.25
                scaleImageView.isHidden = true
            }
            if model.isSelected {
                scaleImageView.tintColor = themeColor
                scaleView.layer.borderColor = themeColor?.cgColor
                scaleLabel.textColor = themeColor
            }else {
                scaleImageView.tintColor = .white
                scaleView.layer.borderColor = UIColor.white.cgColor
                scaleLabel.textColor = .white
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(scaleView)
    }
    
    func updateViewFrame() {
        scaleView.size = model.size
        scaleView.centerX = model.scaleSize.width * 0.5
        scaleView.centerY = model.scaleSize.height * 0.5
        scaleLabel.frame = CGRect(x: 1.5, y: 1.5, width: scaleView.width - 3, height: scaleView.height - 3)
        scaleImageView.frame = scaleView.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
