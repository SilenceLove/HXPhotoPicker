//
//  EditorToolsView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/6.
//

import UIKit

protocol EditorToolsViewDelegate: AnyObject {
    func toolsView(_ toolsView: EditorToolsView, didSelectItemAt model: EditorConfiguration.ToolsView.Options)
    func toolsView(_ toolsView: EditorToolsView, deselectItemAt model: EditorConfiguration.ToolsView.Options)
}

class EditorToolsView: UIView {
    
    weak var delegate: EditorToolsViewDelegate?
    
    let contentType: EditorContentViewType
    
    private var shadeView: UIView!
    private var shadeMaskLayer: CAGradientLayer!
    private var flowLayout: UICollectionViewFlowLayout!
    private var collectionView: EditorCollectionView!
    
    var musicCellShowBox: Bool = false {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var options: [EditorConfiguration.ToolsView.Options] = []
    let config: EditorConfiguration.ToolsView
    init(config: EditorConfiguration.ToolsView, contentType: EditorContentViewType) {
        self.config = config
        self.contentType = contentType
        super.init(frame: .zero)
        initViews()
    }
    
    private func initViews() {
        for option in config.toolOptions {
            if contentType == .image {
                switch option.type {
                case .graffiti, .chartlet, .text, .cropSize, .filter, .filterEdit, .mosaic:
                    options.append(option)
                default:
                    break
                }
            }else if contentType == .video {
                switch option.type {
                case .time, .music, .graffiti, .chartlet, .text, .cropSize, .filter, .filterEdit:
                    options.append(option)
                default:
                    break
                }
            }
        }
        shadeView = UIView()
        flowLayout = UICollectionViewFlowLayout()
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
        collectionView.register(EditorToolViewCell.self, forCellWithReuseIdentifier: "EditorToolViewCellID")
        shadeView.addSubview(collectionView)
        
        shadeMaskLayer = CAGradientLayer()
        shadeMaskLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
        shadeMaskLayer.startPoint = CGPoint(x: 0, y: 1)
        shadeMaskLayer.endPoint = CGPoint(x: 1, y: 1)
        shadeMaskLayer.locations = [0.0, 0.05, 0.95, 1.0]
        shadeView.layer.mask = shadeMaskLayer
        addSubview(shadeView)
    }
    
    func selectedOptionType(_ type: EditorConfiguration.ToolsView.Options.`Type`) {
        DispatchQueue.main.async {
            for (index, option) in self.options.enumerated() where option.type == type {
                self.didClick(at: .init(item: index, section: 0))
                return
            }
        }
    }
    
    func scrollToOption(with type: EditorConfiguration.ToolsView.Options.`Type`) {
        let scrollPosition: UICollectionView.ScrollPosition
        if UIDevice.isPortrait {
            scrollPosition = .centeredHorizontally
        }else {
            scrollPosition = .centeredVertically
        }
        for (index, option) in self.options.enumerated() where option.type == type {
            collectionView.scrollToItem(
                at: .init(item: index, section: 0),
                at: scrollPosition,
                animated: true
            )
            return
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let count = CGFloat(options.count)
        if UIDevice.isPortrait {
            
            flowLayout.scrollDirection = .horizontal
            flowLayout.itemSize = CGSize(width: 30, height: 50)
            flowLayout.minimumLineSpacing = 15
            
            collectionView.contentInset = .init(top: 0, left: 12, bottom: 0, right: 12)
            
            shadeMaskLayer.startPoint = CGPoint(x: 0, y: 1)
            shadeMaskLayer.endPoint = CGPoint(x: 1, y: 1)
            let toolsWidth: CGFloat = 30 * count + (count - 1) * 15 + 24
            let maxWidth = width
            if toolsWidth < maxWidth {
                shadeView.x = (maxWidth - toolsWidth) * 0.5
            }else {
                shadeView.x = 0
            }
            shadeView.width = min(toolsWidth, maxWidth)
            shadeView.height = 50
            shadeView.y = 0
        }else {
            flowLayout.scrollDirection = .vertical
            flowLayout.itemSize = CGSize(width: 30, height: 50)
            flowLayout.minimumLineSpacing = 0
            
            collectionView.contentInset = .init(top: 0, left: 0, bottom: 12 + UIDevice.bottomMargin, right: 0)
            
            shadeMaskLayer.startPoint = CGPoint(x: 1, y: 0)
            shadeMaskLayer.endPoint = CGPoint(x: 1, y: 1)
            let toolsHeight: CGFloat = 50 * count + 12
            let maxHeight = height
            if toolsHeight < maxHeight {
                shadeView.y = (maxHeight - toolsHeight) * 0.5
            }else {
                shadeView.y = 0
            }
            shadeView.x = 0
            shadeView.width = 50
            shadeView.height = min(toolsHeight, maxHeight)
        }
        collectionView.frame = shadeView.bounds
        shadeMaskLayer.frame = CGRect(x: 0, y: 0, width: shadeView.width, height: shadeView.height)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var selectedIndexPath: IndexPath?
}

extension EditorToolsView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        options.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorToolViewCellID",
            for: indexPath
        ) as! EditorToolViewCell
        let model = options[indexPath.item]
        cell.delegate = self
        if model.type == .music {
            cell.musicTickColor = config.musicTickColor
            cell.musicTickBackgroundColor = config.musicTickBackgroundColor
            cell.showBox = musicCellShowBox
        }else {
            cell.showBox = false
        }
        cell.selectedColor = config.toolSelectedColor
        cell.model = model
        switch model.type {
        case .time, .graffiti, .mosaic, .filter, .filterEdit:
            if let selectedIndexPath = selectedIndexPath,
               selectedIndexPath.item == indexPath.item {
                cell.isSelectedImageView = true
            }else {
                cell.isSelectedImageView = false
            }
        default:
            cell.isSelectedImageView = false
        }
        return cell
    }
}

extension EditorToolsView: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: false)
    }
}

extension EditorToolsView: EditorToolViewCellDelegate {
    func toolViewCell(didClick cell: EditorToolViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        didClick(at: indexPath)
    }
    
    func didClick(at indexPath: IndexPath) {
        let option = options[indexPath.item]
        switch option.type {
        case .cropSize, .text, .music, .chartlet:
            break
        default:
            if #available(iOS 13.0, *), option.type == .graffiti {
                break
            }
            if let selectedIndexPath = selectedIndexPath,
               selectedIndexPath.item == indexPath.item {
                deselected()
                delegate?.toolsView(self, deselectItemAt: option)
                return
            }else {
                selected(indexPath: indexPath)
            }
        }
        delegate?.toolsView(self, didSelectItemAt: option)
    }
    
    func deselected() {
        if let indexPath = selectedIndexPath {
            let cell = collectionView.cellForItem(at: indexPath) as? EditorToolViewCell
            cell?.isSelectedImageView = false
            selectedIndexPath = nil
        }
    }
    
    func selected(indexPath: IndexPath) {
        deselected()
        let cell = collectionView.cellForItem(at: indexPath) as? EditorToolViewCell
        cell?.isSelectedImageView = true
        selectedIndexPath = indexPath
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

protocol EditorToolViewCellDelegate: AnyObject {
    func toolViewCell(didClick cell: EditorToolViewCell)
}

class EditorToolViewCell: UICollectionViewCell {
    weak var delegate: EditorToolViewCellDelegate?
    
    private var pointView: UIView!
    private var boxView: SelectBoxView!
    private var button: UIButton!
    
    var showBox: Bool = false {
        didSet {
            boxView.isSelected = showBox
            boxView.isHidden = !showBox
        }
    }
    var boxColor: UIColor? {
        didSet {
            guard let boxColor = boxColor else {
                return
            }
            boxView.config.tickColor = boxColor
            boxView.config.tickDarkColor = boxColor
        }
    }
    
    var musicTickColor: UIColor = "#222222".color {
        didSet {
            boxView.config.tickColor = musicTickColor
            boxView.config.tickDarkColor = musicTickColor
        }
    }
    
    var musicTickBackgroundColor: UIColor = "#FDCC00".color {
        didSet {
            boxView.config.selectedBackgroundColor = musicTickBackgroundColor
            boxView.config.selectedBackgroudDarkColor = musicTickBackgroundColor
        }
    }
    
    var model: EditorConfiguration.ToolsView.Options! {
        didSet {
            let image = model.imageType.image?.withRenderingMode(.alwaysTemplate)
            button.setImage(image, for: .normal)
        }
    }
    var selectedColor: UIColor? {
        didSet {
            pointView.backgroundColor = selectedColor
        }
    }
    
    var isSelectedImageView: Bool = false {
        didSet {
            pointView.isHidden = !isSelectedImageView
//            button.tintColor = isSelectedImageView ? selectedColor : .white
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        button = UIButton(type: .system)
        button.addTarget(self, action: #selector(didButtonClick), for: .touchUpInside)
        button.tintColor = .white
        contentView.addSubview(button)
        
        var config = SelectBoxConfiguration()
        config.style = .tick
        config.tickWidth = 1
        config.tickColor = musicTickColor
        config.tickDarkColor = musicTickColor
        config.selectedBackgroundColor = musicTickBackgroundColor
        config.selectedBackgroudDarkColor = musicTickBackgroundColor
        boxView = SelectBoxView(config, frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        boxView.isHidden = true
        boxView.isUserInteractionEnabled = false
        contentView.addSubview(boxView)
        
        pointView = UIView()
        pointView.size = .init(width: 4, height: 4)
        if #available(iOS 11.0, *) {
            pointView.cornersRound(radius: 2, corner: .allCorners)
        }
        contentView.addSubview(pointView)
    }
    
    @objc
    private func didButtonClick() {
        delegate?.toolViewCell(didClick: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = bounds
        if let image = button.image(for: .normal) {
            boxView.x = width * 0.5 + image.width * 0.5 - boxView.width * 0.5
            boxView.y = height * 0.5 + image.height * 0.5 - boxView.height + 3
        }
        pointView.y = button.frame.maxY - 10
        pointView.centerX = width * 0.5
        guard #available(iOS 11.0, *) else {
            pointView.cornersRound(radius: 2, corner: .allCorners)
            return
        }
    }
}
