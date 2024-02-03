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
    var canUndo: Bool = false {
        didSet {
            undoButton.isEnabled = canUndo
        }
    }
    var canAddCustom: Bool {
        if #available(iOS 14.0, *), config.addCustomColor {
            return true
        }else {
            return false
        }
    }
    
    private var shadeView: UIView!
    private var maskLayer: CAGradientLayer!
    private var flowLayout: UICollectionViewFlowLayout!
    private var collectionView: EditorCollectionView!
    private var undoButton: UIButton!
    private var customColor: EditorBrushCustomColor!
    
    init(config: EditorConfiguration.Brush) {
        self.config = config
        self.brushColors = config.colors
        super.init(frame: .zero)
        initViews()
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
    
    private func initViews() {
        maskLayer = CAGradientLayer.init()
        maskLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
        maskLayer.locations = [0.0, 0.05, 0.95, 1.0]
        
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.itemSize = CGSize(width: 37, height: 37)
        
        collectionView = EditorCollectionView(frame: .zero, collectionViewLayout: flowLayout)
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
        
        undoButton = UIButton(type: .system)
        undoButton.setImage(.imageResource.editor.brush.undo.image, for: .normal)
        undoButton.addTarget(self, action: #selector(didUndoClick(button:)), for: .touchUpInside)
        undoButton.tintColor = .white
        undoButton.isEnabled = false
        
        customColor = EditorBrushCustomColor(
            color: config.customDefaultColor
        )
        
        shadeView = UIView()
        shadeView.addSubview(collectionView)
        shadeView.layer.mask = maskLayer
    }
    
    @objc
    private func didUndoClick(button: UIButton) {
        delegate?.brushColorView(didUndoButton: self)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.isPortrait {
            let cHeight: CGFloat = 60
            flowLayout.minimumLineSpacing = 5
            maskLayer.startPoint = CGPoint(x: 0, y: 1)
            maskLayer.endPoint = CGPoint(x: 1, y: 1)
            flowLayout.scrollDirection = .horizontal
            shadeView.frame.origin = .init(x: 0, y: 5)
            let colorCount: CGFloat
            if canAddCustom {
                colorCount = CGFloat(brushColors.count + 1)
            }else {
                colorCount =  CGFloat(brushColors.count)
            }
            let margin = UIDevice.leftMargin + UIDevice.rightMargin
            let colorsWidth: CGFloat = 37 * colorCount + (colorCount - 1) * 5
            let maxWidth = width - margin - cHeight
            shadeView.width = min(colorsWidth, maxWidth)
            let flowLayoutLeft: CGFloat
            let flowLayoutRight: CGFloat
            let undoX: CGFloat
            let undoW: CGFloat
            if colorsWidth < maxWidth {
                if shadeView.layer.mask != nil {
                    shadeView.layer.mask = nil
                }
                shadeView.x = (width - shadeView.width) * 0.5
                flowLayoutLeft = 0
                flowLayoutRight = 0
                undoX = shadeView.frame.maxX
                undoW = 40
                maskLayer.frame = shadeView.bounds
            }else {
                if shadeView.layer.mask == nil {
                    shadeView.layer.mask = maskLayer
                }
                shadeView.x = 0
                flowLayoutLeft = 12 + UIDevice.leftMargin
                flowLayoutRight = cHeight + UIDevice.rightMargin
                undoX = width - UIDevice.rightMargin - cHeight
                undoW = cHeight
                maskLayer.frame = CGRect(
                    x: 0, y: 0,
                    width: shadeView.width - 50 - UIDevice.rightMargin,
                    height: shadeView.height
                )
            }
            shadeView.height = cHeight
            collectionView.frame = shadeView.bounds
            flowLayout.sectionInset = UIEdgeInsets(
                top: 0,
                left: flowLayoutLeft,
                bottom: 0,
                right: flowLayoutRight
            )
            undoButton.frame = CGRect(
                x: undoX,
                y: shadeView.y,
                width: undoW,
                height: cHeight
            )
        }else {
            let cHeight: CGFloat = 40
            let undoY: CGFloat = UIDevice.topMargin + 44
            if shadeView.layer.mask == nil {
                shadeView.layer.mask = maskLayer
            }
            flowLayout.minimumLineSpacing = 10
            maskLayer.startPoint = CGPoint(x: 1, y: 1)
            maskLayer.endPoint = CGPoint(x: 1, y: 0)
            flowLayout.scrollDirection = .vertical
            shadeView.frame = CGRect(
                x: 5,
                y: undoY + 5,
                width: 60,
                height: height - undoY - 5
            )
            collectionView.frame = shadeView.bounds
            maskLayer.frame = shadeView.bounds
            flowLayout.sectionInset = UIEdgeInsets(
                top: cHeight,
                left: 0,
                bottom: 12 + UIDevice.bottomMargin,
                right: 0
            )
            undoButton.frame = CGRect(
                x: 0,
                y: undoY,
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
    private var colorBgView: UIView!
    private var imageView: UIImageView!
    private var colorView: UIView!
    
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
                self.colorView.transform = self.isSelected ? .init(scaleX: 1.25, y: 1.25) : .identity
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView = UIImageView(image: .imageResource.editor.brush.customColor.image)
        imageView.isHidden = true
        
        let bgLayer = CAShapeLayer()
        bgLayer.contentsScale = UIScreen._scale
        bgLayer.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        bgLayer.fillColor = UIColor.white.cgColor
        let bgPath = UIBezierPath(
            roundedRect: CGRect(x: 1.5, y: 1.5, width: 19, height: 19),
            cornerRadius: 19 * 0.5
        )
        bgLayer.path = bgPath.cgPath
        imageView.layer.addSublayer(bgLayer)

        let maskLayer = CAShapeLayer()
        maskLayer.contentsScale = UIScreen._scale
        maskLayer.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        let maskPath = UIBezierPath(rect: bgLayer.bounds)
        maskPath.append(
            UIBezierPath(
                roundedRect: CGRect(x: 3, y: 3, width: 16, height: 16),
                cornerRadius: 8
            ).reversing()
        )
        maskLayer.path = maskPath.cgPath
        imageView.layer.mask = maskLayer
        
        colorBgView = UIView()
        colorBgView.size = CGSize(width: 22, height: 22)
        colorBgView.layer.cornerRadius = 11
        colorBgView.layer.masksToBounds = true
        colorBgView.addSubview(imageView)
        contentView.addSubview(colorBgView)
        
        colorView = UIView()
        colorView.size = CGSize(width: 17, height: 17)
        colorView.layer.cornerRadius = 8.5
        colorView.layer.masksToBounds = true
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
