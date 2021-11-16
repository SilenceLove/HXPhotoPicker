//
//  PhotoPickerLimitCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/10/22.
//

import UIKit

class PhotoPickerLimitCell: UICollectionViewCell {
    
    lazy var lineLayer: CAShapeLayer = {
        let lineLayer = CAShapeLayer()
        lineLayer.contentsScale = UIScreen.main.scale
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineCap = .round
        return lineLayer
    }()
    
    lazy var titleLb: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    var config: PhotoListConfiguration.LimitCell? {
        didSet {
            setConfig()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.addSublayer(lineLayer)
        contentView.addSubview(titleLb)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        lineLayer.frame = bounds
        titleLb.x = 0
        titleLb.y = (height - 20) * 0.5 + 22
        titleLb.width = width
        titleLb.height = titleLb.textHeight
        setLineLayerPath()
    }
    
    func setConfig() {
        guard let config = config else {
            return
        }
        titleLb.text = config.title?.localized
        let isDark = PhotoManager.isDark
        backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        lineLayer.strokeColor = isDark ? config.lineDarkColor.cgColor : config.lineColor.cgColor
        lineLayer.lineWidth = config.lineWidth
        titleLb.textColor = isDark ? config.titleDarkColor : config.titleColor
        titleLb.font = config.titleFont
    }
    
    func setLineLayerPath() {
        let path = UIBezierPath()
        let centerX = width * 0.5
        let margin: CGFloat = config?.title == nil ? 0 : 20
        let centerY = (height - margin) * 0.5
        let linelength = (config?.lineLength ?? 30) * 0.5
        path.move(to: CGPoint(x: centerX - linelength, y: centerY))
        path.addLine(to: CGPoint(x: centerX + linelength, y: centerY))
        
        path.move(to: .init(x: centerX, y: centerY - linelength))
        path.addLine(to: .init(x: centerX, y: centerY + linelength))
        
        lineLayer.path = path.cgPath
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                setConfig()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
