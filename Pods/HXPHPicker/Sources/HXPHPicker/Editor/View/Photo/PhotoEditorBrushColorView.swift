//
//  PhotoEditorBrushColorView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/12.
//

import UIKit

protocol PhotoEditorBrushColorViewDelegate: AnyObject {
    func brushColorView(_ colorView: PhotoEditorBrushColorView, changedColor colorHex: String)
    func brushColorView(didUndoButton colorView: PhotoEditorBrushColorView)
}

public class PhotoEditorBrushColorView: UIView {
    weak var delegate: PhotoEditorBrushColorViewDelegate?
    var brushColors: [String] = []
    var currentColorIndex: Int = 0 {
        didSet {
            collectionView.selectItem(
                at: IndexPath(
                    item: currentColorIndex,
                    section: 0
                ),
                animated: true,
                scrollPosition: .centeredHorizontally
            )
        }
    }
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.itemSize = CGSize(width: 37, height: 37)
        return flowLayout
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView.init(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(
            PhotoEditorBrushColorViewCell.self,
            forCellWithReuseIdentifier: "PhotoEditorBrushColorViewCellID"
        )
        return collectionView
    }()
    
    var canUndo: Bool = false {
        didSet {
            undoButton.isEnabled = canUndo
        }
    }
    
    lazy var undoButton: UIButton = {
        let button = UIButton.init(type: .system)
        button.setImage(UIImage.image(for: "hx_editor_brush_repeal"), for: .normal)
        button.addTarget(self, action: #selector(didUndoClick(button:)), for: .touchUpInside)
        button.tintColor = .white
        button.isEnabled = false
        return button
    }()
    
    @objc func didUndoClick(button: UIButton) {
        delegate?.brushColorView(didUndoButton: self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(collectionView)
        addSubview(undoButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionView.frame = bounds
        flowLayout.sectionInset = UIEdgeInsets(
            top: 0,
            left: 12 + UIDevice.leftMargin,
            bottom: 0,
            right: height + UIDevice.rightMargin
        )
        undoButton.frame = CGRect(x: width - UIDevice.rightMargin - height, y: 0, width: height, height: height)
    }
}

extension PhotoEditorBrushColorView: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        brushColors.count
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "PhotoEditorBrushColorViewCellID",
            for: indexPath
        ) as! PhotoEditorBrushColorViewCell
        cell.colorHex = brushColors[indexPath.item]
        return cell
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.scrollToItem(
            at: indexPath,
            at: .centeredHorizontally,
            animated: true
        )
        delegate?.brushColorView(
            self,
            changedColor: brushColors[indexPath.item]
        )
    }
}

class PhotoEditorBrushColorViewCell: UICollectionViewCell {
    lazy var colorBgView: UIView = {
        let view = UIView.init()
        view.size = CGSize(width: 22, height: 22)
        view.layer.cornerRadius = 11
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var colorView: UIView = {
        let view = UIView.init()
        view.size = CGSize(width: 16, height: 16)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    var colorHex: String! {
        didSet {
            let color = colorHex.color
            if color.isWhite {
                colorBgView.backgroundColor = "#dadada".color
            }else {
                colorBgView.backgroundColor = .white
            }
            colorView.backgroundColor = color
        }
    }
    
    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.colorBgView.transform = self.isSelected ? .init(scaleX: 1.2, y: 1.2) : .identity
                self.colorView.transform = self.isSelected ? .init(scaleX: 1.25, y: 1.25) : .identity
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(colorBgView)
        contentView.addSubview(colorView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        colorBgView.center = CGPoint(x: width / 2, y: height / 2)
        colorView.center = CGPoint(x: width / 2, y: height / 2)
    }
}
