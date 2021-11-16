//
//  PhotoEditorBrushColorView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/12.
//

import UIKit

protocol PhotoEditorBrushColorViewDelegate: AnyObject {
    func brushColorView(
        _ colorView: PhotoEditorBrushColorView,
        changedColor colorHex: String
    )
    func brushColorView(
        didUndoButton colorView: PhotoEditorBrushColorView
    )
    func brushColorView(
        touchDown colorView: PhotoEditorBrushColorView
    )
    func brushColorView(
        _ colorView: PhotoEditorBrushColorView,
        didChangedBrushLine lineWidth: CGFloat
    )
    func brushColorView(
        touchUpOutside colorView: PhotoEditorBrushColorView
    )
}

public class PhotoEditorBrushColorView: UIView {
    weak var delegate: PhotoEditorBrushColorViewDelegate?
    let config: EditorBrushConfiguration
    let brushColors: [String]
    lazy var brushSizeSlider: UISlider = {
        let slider = UISlider()
        slider.maximumTrackTintColor = .white.withAlphaComponent(0.4)
        slider.minimumTrackTintColor = .white
        let image = UIImage.image(for: .white, havingSize: CGSize(width: 20, height: 20), radius: 10)
        slider.setThumbImage(image, for: .normal)
        slider.setThumbImage(image, for: .highlighted)
        slider.layer.shadowColor = UIColor.black.withAlphaComponent(0.4).cgColor
        slider.layer.shadowRadius = 4
        slider.layer.shadowOpacity = 0.5
        slider.layer.shadowOffset = CGSize(width: 0, height: 0)
        slider.value = Float(config.lineWidth / (config.maximumLinewidth - config.minimumLinewidth))
        slider.addTarget(
            self,
            action: #selector(sliderDidChanged(slider:)),
            for: .valueChanged
        )
        slider.addTarget(
            self,
            action: #selector(sliderTouchDown(slider:)),
            for: [
                .touchDown
            ]
        )
        slider.addTarget(
            self,
            action: #selector(sliderTouchUpOutside(slider:)),
            for: [
                .touchUpInside,
                .touchCancel,
                .touchUpOutside
            ]
        )
        slider.isHidden = !config.showSlider
        return slider
    }()
    
    @objc func sliderDidChanged(slider: UISlider) {
        let lineWidth = (
            config.maximumLinewidth - config.minimumLinewidth
        ) * CGFloat(slider.value) + config.minimumLinewidth
        delegate?.brushColorView(self, didChangedBrushLine: lineWidth)
    }
    
    @objc func sliderTouchDown(slider: UISlider) {
        delegate?.brushColorView(touchDown: self)
    }
    
    @objc func sliderTouchUpOutside(slider: UISlider) {
        delegate?.brushColorView(touchUpOutside: self)
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
    
    init(config: EditorBrushConfiguration) {
        self.config = config
        self.brushColors = config.colors
        super.init(frame: .zero)
        addSubview(collectionView)
        addSubview(undoButton)
        addSubview(brushSizeSlider)
        collectionView.selectItem(
            at: IndexPath(
                item: config.defaultColorIndex,
                section: 0
            ),
            animated: true,
            scrollPosition: .centeredHorizontally
        )
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        brushSizeSlider.frame = CGRect(
            x: UIDevice.leftMargin + 20,
            y: 0,
            width: width - 40 - UIDevice.leftMargin - UIDevice.rightMargin,
            height: 20
        )
        let cHeight: CGFloat = 60
        collectionView.frame = CGRect(x: 0, y: brushSizeSlider.frame.maxY + 5, width: width, height: cHeight)
        flowLayout.sectionInset = UIEdgeInsets(
            top: 0,
            left: 12 + UIDevice.leftMargin,
            bottom: 0,
            right: cHeight + UIDevice.rightMargin
        )
        undoButton.frame = CGRect(
            x: width - UIDevice.rightMargin - cHeight,
            y: collectionView.y,
            width: cHeight,
            height: cHeight
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
                self.colorBgView.transform = self.isSelected ? .init(scaleX: 1.25, y: 1.25) : .identity
                self.colorView.transform = self.isSelected ? .init(scaleX: 1.3, y: 1.3) : .identity
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
