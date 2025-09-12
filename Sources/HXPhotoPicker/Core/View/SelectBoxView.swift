//
//  SelectBoxView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

public final class SelectBoxView: UIControl {
    
    public enum Style: Int {
        /// 数字
        case number
        /// 勾勾
        case tick
    }
    
    public var text: String = "0" {
        didSet {
            if config.style == .number {
                textLayer.string = text
                
                updateTextLayerFrame()
            }
        }
    }
    public override var isSelected: Bool {
        didSet {
            if !isSelected {
                text = "0"
            }
            updateLayers()
        }
    }
    public override var isHighlighted: Bool {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            updateLayers()
            CATransaction.commit()
        }
    }
    
    var textSize: CGSize = CGSize.zero {
        didSet {
            guard oldValue != self.textSize else {
                return
            }
            updateTextLayerFrame()
        }
    }
    
    private var backgroundLayer: CAShapeLayer!
    private var textLayer: CATextLayer!
    private var tickLayer: CAShapeLayer!
    
    public var config: SelectBoxConfiguration
    public init(_ config: SelectBoxConfiguration, frame: CGRect = .zero) {
        self.config = config
        super.init(frame: frame)
        initViews()
        layer.addSublayer(backgroundLayer)
        layer.addSublayer(textLayer)
        layer.addSublayer(tickLayer)
    }
    
    private func initViews() {
        backgroundLayer = CAShapeLayer()
        backgroundLayer.contentsScale = UIScreen._scale
        
        textLayer = CATextLayer()
        textLayer.contentsScale = UIScreen._scale
        textLayer.alignmentMode = .center
        textLayer.isWrapped = true
        
        tickLayer = CAShapeLayer()
        tickLayer.lineJoin = .round
        tickLayer.contentsScale = UIScreen._scale
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateBackgroundLayerFrame()
        updateTickLayerFrame()
        updateTextLayerFrame()
    }
    
    private func backgroundPath() -> CGPath {
        let strokePath: UIBezierPath = .init(
            roundedRect: CGRect(
                x: 0,
                y: 0,
                width: config.size.width,
                height: config.size.height
            ),
            cornerRadius: config.size.height / 2
        )
        return strokePath.cgPath
    }
    private func drawBackgroundLayer() {
        backgroundLayer.path = backgroundPath()
        if isSelected {
            let selectedBackgroundColor = config.selectedBackgroundColor
            let selectedBackgroudDarkColor = config.selectedBackgroudDarkColor
            if isHighlighted {
                backgroundLayer.fillColor = PhotoManager.isDark ?
                selectedBackgroudDarkColor.withAlphaComponent(0.4).cgColor :
                selectedBackgroundColor.withAlphaComponent(0.4).cgColor
            }else {
                backgroundLayer.fillColor = PhotoManager.isDark ?
                selectedBackgroudDarkColor.cgColor :
                selectedBackgroundColor.cgColor
            }
            backgroundLayer.lineWidth = 0
        }else {
            backgroundLayer.lineWidth = config.borderWidth
            let backgroundColor = config.backgroundColor
            let darkBackgroundColor = config.darkBackgroundColor
            let borderColor = config.borderColor
            let borderDarkColor = config.borderDarkColor
            if isHighlighted {
                backgroundLayer.fillColor = PhotoManager.isDark ?
                darkBackgroundColor.withAlphaComponent(0.4).cgColor :
                backgroundColor.withAlphaComponent(0.4).cgColor
                backgroundLayer.strokeColor = PhotoManager.isDark ?
                borderDarkColor.withAlphaComponent(0.4).cgColor :
                borderColor.withAlphaComponent(0.4).cgColor
            }else {
                backgroundLayer.fillColor = PhotoManager.isDark ? darkBackgroundColor.cgColor : backgroundColor.cgColor
                backgroundLayer.strokeColor = PhotoManager.isDark ? borderDarkColor.cgColor : borderColor.cgColor
            }
        }
    }
    private func drawTextLayer() {
        if config.style != .number {
            textLayer.isHidden = true
            return
        }
        if !isSelected {
            textLayer.string = nil
        }
        
        let font: UIFont = .mediumPingFang(ofSize: config.titleFontSize)
        textLayer.font = CGFont(font.fontName as CFString)
        textLayer.fontSize = config.titleFontSize
        let color = PhotoManager.isDark ? config.titleDarkColor : config.titleColor
        textLayer.foregroundColor = isHighlighted ? color.withAlphaComponent(0.4).cgColor : color.cgColor
    }
    
    private func tickPath() -> CGPath {
        let tickPath: UIBezierPath = .init()
        tickPath.move(to: CGPoint(x: scale(8), y: config.size.height * 0.5 + scale(1)))
        tickPath.addLine(to: CGPoint(x: config.size.width * 0.5 - scale(2), y: config.size.height - scale(8)))
        tickPath.addLine(to: CGPoint(x: config.size.width - scale(7), y: scale(9)))
        return tickPath.cgPath
    }
    private func drawTickLayer() {
        if config.style != .tick {
            tickLayer.isHidden = true
            return
        }
        tickLayer.isHidden = !isSelected
        tickLayer.path = tickPath()
        tickLayer.lineWidth = config.tickWidth
        let color = PhotoManager.isDark ? config.tickDarkColor : config.tickColor
        tickLayer.strokeColor = isHighlighted ? color.withAlphaComponent(0.4).cgColor : color.cgColor
        tickLayer.fillColor = UIColor.clear.cgColor
    }
    
    public func updateLayers() {
        updateBackgroundLayerFrame()
        updateTickLayerFrame()
        updateTextLayerFrame()
        
        drawBackgroundLayer()
        drawTextLayer()
        drawTickLayer()
    }
    
    private func updateBackgroundLayerFrame() {
        backgroundLayer.frame = CGRect(
            x: (width - config.size.width) / 2,
            y: (height - config.size.height) / 2,
            width: config.size.width,
            height: config.size.height
        )
    }
    
    private func updateTickLayerFrame() {
        guard config.style == .tick else {
            return
        }
        tickLayer.frame = CGRect(
            x: (width - config.size.width) / 2,
            y: (height - config.size.height) / 2,
            width: config.size.width,
            height: config.size.height
        )
    }
    
    private func updateTextLayerFrame() {
        let font: UIFont = .mediumPingFang(ofSize: config.titleFontSize)
        var textHeight: CGFloat
        var textWidth: CGFloat
        if textSize.equalTo(CGSize.zero) {
            textHeight = text.height(ofFont: font, maxWidth: CGFloat(MAXFLOAT))
            textWidth = text.width(ofFont: font, maxHeight: textHeight)
        }else {
            textHeight = textSize.height
            textWidth = textSize.width
        }
        textLayer.frame = CGRect(
            x: (width - textWidth) * 0.5,
            y: (height - textHeight) * 0.5,
            width: textWidth,
            height: textHeight
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func scale(_ numerator: CGFloat) -> CGFloat {
        return numerator / 30 * height
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isUserInteractionEnabled && CGRect(x: -15, y: -15, width: width + 30, height: height + 30).contains(point) {
            return self
        }
        return super.hitTest(point, with: event)
    }
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                drawBackgroundLayer()
                drawTextLayer()
                drawTickLayer()
            }
        }
    }
}
