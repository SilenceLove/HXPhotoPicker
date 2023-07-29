//
//  EditorBrushColorView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/10.
//

import UIKit

protocol EditorBrushColorViewDelegate: AnyObject {
    func brushColorView(
        _ colorView: EditorBrushColorView,
        changedColor colorHex: String
    )
    func brushColorView(
        _ colorView: EditorBrushColorView,
        changedColor color: UIColor
    )
    func brushColorView(
        didUndoButton colorView: EditorBrushColorView
    )
}

public class EditorBrushColorView: UIView {
    weak var delegate: EditorBrushColorViewDelegate?
    let config: EditorConfiguration.Brush
    let brushColors: [String]
    
    lazy var shadeView: UIView = {
        let view = UIView.init()
        view.addSubview(collectionView)
        view.layer.mask = maskLayer
        return view
    }()
    
    lazy var maskLayer: CAGradientLayer = {
        let maskLayer = CAGradientLayer.init()
        maskLayer.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
        maskLayer.locations = [0.925, 1.0]
        return maskLayer
    }()
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.itemSize = CGSize(width: 37, height: 37)
        return flowLayout
    }()
    
    lazy var collectionView: EditorCollectionView = {
        let collectionView = EditorCollectionView.init(frame: .zero, collectionViewLayout: flowLayout)
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
            EditorBrushColorViewCell.self,
            forCellWithReuseIdentifier: "EditorBrushColorViewCellID"
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
    
    var canAddCustom: Bool {
        if #available(iOS 14.0, *), config.addCustomColor {
            return true
        }else {
            return false
        }
    }
    lazy var customColor: EditorBrushCustomColor = {
        let custom = EditorBrushCustomColor(
            color: config.customDefaultColor
        )
        return custom
    }()
    
    init(config: EditorConfiguration.Brush) {
        self.config = config
        self.brushColors = config.colors
        super.init(frame: .zero)
        addSubview(shadeView)
        addSubview(undoButton)
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
        let cHeight: CGFloat = 60
        if UIDevice.isPortrait {
            maskLayer.startPoint = CGPoint(x: 0, y: 1)
            maskLayer.endPoint = CGPoint(x: 1, y: 1)
            flowLayout.scrollDirection = .horizontal
            shadeView.frame = CGRect(
                x: 0,
                y: 5,
                width: width,
                height: cHeight
            )
            let colorCount: CGFloat
            if canAddCustom {
                colorCount = CGFloat(brushColors.count + 1)
            }else {
                colorCount =  CGFloat(brushColors.count)
            }
            let margin = UIDevice.leftMargin + UIDevice.rightMargin
            let colorsWidth: CGFloat = 37 * colorCount + (colorCount - 1) * 5 + margin + 12 + cHeight
            let maxWidth = width
            if colorsWidth < maxWidth {
                shadeView.x = (maxWidth - colorsWidth) * 0.5
            }else {
                shadeView.x = 0
            }
            shadeView.width = min(colorsWidth, maxWidth)
            shadeView.height = cHeight
            collectionView.frame = shadeView.bounds
            if colorsWidth < maxWidth {
                maskLayer.frame = CGRect(x: 0, y: 0, width: shadeView.width, height: shadeView.height)
            }else {
                maskLayer.frame = CGRect(
                    x: 0, y: 0,
                    width: shadeView.width - 50 - UIDevice.rightMargin,
                    height: shadeView.height
                )
            }
            flowLayout.sectionInset = UIEdgeInsets(
                top: 0,
                left: 12 + UIDevice.leftMargin,
                bottom: 0,
                right: cHeight + UIDevice.rightMargin
            )
            undoButton.frame = CGRect(
                x: width - UIDevice.rightMargin - cHeight,
                y: shadeView.y,
                width: cHeight,
                height: cHeight
            )
        }else {
            maskLayer.startPoint = CGPoint(x: 1, y: 1)
            maskLayer.endPoint = CGPoint(x: 1, y: 0)
            flowLayout.scrollDirection = .vertical
            shadeView.frame = CGRect(
                x: 5,
                y: 0,
                width: 60,
                height: height
            )
            collectionView.frame = shadeView.bounds
            maskLayer.frame = CGRect(
                x: 0,
                y: UIDevice.topMargin + 44,
                width: shadeView.width,
                height: shadeView.height - UIDevice.topMargin - 44
            )
            flowLayout.sectionInset = UIEdgeInsets(
                top: UIDevice.topMargin + 44 + 5,
                left: 0,
                bottom: 12 + UIDevice.bottomMargin,
                right: 0
            )
            undoButton.frame = CGRect(
                x: 0,
                y: UIDevice.topMargin,
                width: cHeight,
                height: 44
            )
            undoButton.centerX = shadeView.centerX
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorBrushColorView: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if canAddCustom {
            return brushColors.count + 1
        }else {
            return brushColors.count
        }
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorBrushColorViewCellID",
            for: indexPath
        ) as! EditorBrushColorViewCell
        if canAddCustom && indexPath.item == brushColors.count {
            cell.customColor = customColor
        }else {
            cell.colorHex = brushColors[indexPath.item]
        }
        return cell
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.scrollToItem(
            at: indexPath,
            at: UIDevice.isPortrait ? .centeredHorizontally : .centeredVertically,
            animated: true
        )
        if canAddCustom {
            if indexPath.item == brushColors.count {
                if #available(iOS 14.0, *) {
                    didSelectCustomColor(customColor.color)
                    if !customColor.isFirst && !customColor.isSelected {
                        customColor.isSelected = true
                        return
                    }
                    let vc = UIColorPickerViewController()
                    vc.delegate = self
                    vc.selectedColor = customColor.color
                    viewController?.present(vc, animated: true, completion: nil)
                    customColor.isFirst = false
                    customColor.isSelected = true
                }
                return
            }
            customColor.isSelected = false
        }
        delegate?.brushColorView(
            self,
            changedColor: brushColors[indexPath.item]
        )
    }
}

@available(iOS 14.0, *)
extension EditorBrushColorView: UIColorPickerViewControllerDelegate {
    public func colorPickerViewControllerDidSelectColor(
        _ viewController: UIColorPickerViewController
    ) {
        if #available(iOS 15.0, *) {
            return
        }
        didSelectCustomColor(viewController.selectedColor)
    }
    @available(iOS 15.0, *)
    public func colorPickerViewController(
        _ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool
    ) {
        didSelectCustomColor(color)
    }
    func didSelectCustomColor(_ color: UIColor) {
        customColor.color = color
        let cell = collectionView.cellForItem(
            at: .init(item: brushColors.count, section: 0)
        ) as? EditorBrushColorViewCell
        cell?.customColor = customColor
        delegate?.brushColorView(
            self,
            changedColor: customColor.color
        )
    }
}

class EditorBrushColorViewCell: UICollectionViewCell {
    lazy var colorBgView: UIView = {
        let view = UIView.init()
        view.size = CGSize(width: 22, height: 22)
        view.layer.cornerRadius = 11
        view.layer.masksToBounds = true
        view.addSubview(imageView)
        return view
    }()
    
    lazy var imageView: UIImageView = {
        let view = UIImageView(image: "hx_editor_brush_color_custom".image)
        view.isHidden = true
        
        let bgLayer = CAShapeLayer()
        bgLayer.contentsScale = UIScreen.main.scale
        bgLayer.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        bgLayer.fillColor = UIColor.white.cgColor
        let bgPath = UIBezierPath(
            roundedRect: CGRect(x: 1.5, y: 1.5, width: 19, height: 19),
            cornerRadius: 19 * 0.5
        )
        bgLayer.path = bgPath.cgPath
        view.layer.addSublayer(bgLayer)

        let maskLayer = CAShapeLayer()
        maskLayer.contentsScale = UIScreen.main.scale
        maskLayer.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        let maskPath = UIBezierPath(rect: bgLayer.bounds)
        maskPath.append(
            UIBezierPath(
                roundedRect: CGRect(x: 3, y: 3, width: 16, height: 16),
                cornerRadius: 8
            ).reversing()
        )
        maskLayer.path = maskPath.cgPath
        view.layer.mask = maskLayer
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
            imageView.isHidden = true
            guard let colorHex = colorHex else { return }
            let color = colorHex.color
            if color.isWhite {
                colorBgView.backgroundColor = "#dadada".color
            }else {
                colorBgView.backgroundColor = .white
            }
            colorView.backgroundColor = color
        }
    }
    
    var customColor: EditorBrushCustomColor? {
        didSet {
            guard let customColor = customColor else {
                return
            }
            imageView.isHidden = false
            colorView.backgroundColor = customColor.color
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
        imageView.frame = colorBgView.bounds
        colorView.center = CGPoint(x: width / 2, y: height / 2)
    }
}

struct EditorBrushCustomColor {
    var isFirst: Bool = true
    var isSelected: Bool = false
    var color: UIColor
}
