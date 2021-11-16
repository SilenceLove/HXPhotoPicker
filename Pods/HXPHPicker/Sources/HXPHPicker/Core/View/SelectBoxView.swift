//
//  SelectBoxView.swift
//  HXPHPickerExample
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
    var textSize: CGSize = CGSize.zero
    public lazy var config: SelectBoxConfiguration = .init()
    
    lazy var backgroundLayer: CAShapeLayer = {
        let backgroundLayer = CAShapeLayer.init()
        backgroundLayer.contentsScale = UIScreen.main.scale
        return backgroundLayer
    }()
    lazy var textLayer: CATextLayer = {
        let textLayer = CATextLayer.init()
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.alignmentMode = .center
        textLayer.isWrapped = true
        return textLayer
    }()
    lazy var tickLayer: CAShapeLayer = {
        let tickLayer = CAShapeLayer.init()
        tickLayer.lineJoin = .round
        tickLayer.contentsScale = UIScreen.main.scale
        return tickLayer
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(backgroundLayer)
        layer.addSublayer(textLayer)
        layer.addSublayer(tickLayer)
    }
    
    private func backgroundPath() -> CGPath {
        let strokePath = UIBezierPath(
            roundedRect: CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            ),
            cornerRadius: height / 2
        )
        return strokePath.cgPath
    }
    private func drawBackgroundLayer() {
        backgroundLayer.path = backgroundPath()
        if isSelected {
            backgroundLayer.fillColor = PhotoManager.isDark ?
                config.selectedBackgroudDarkColor.cgColor :
                config.selectedBackgroundColor.cgColor
            backgroundLayer.lineWidth = 0
        }else {
            backgroundLayer.lineWidth = config.borderWidth
            backgroundLayer.fillColor = PhotoManager.isDark ?
                config.darkBackgroundColor.cgColor :
                config.backgroundColor.cgColor
            backgroundLayer.strokeColor = PhotoManager.isDark ?
                config.borderDarkColor.cgColor :
                config.borderColor.cgColor
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
        
        let font = UIFont.mediumPingFang(ofSize: config.titleFontSize)
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
        textLayer.font = CGFont(font.fontName as CFString)
        textLayer.fontSize = config.titleFontSize
        textLayer.foregroundColor = PhotoManager.isDark ? config.titleDarkColor.cgColor : config.titleColor.cgColor
    }
    
    private func tickPath() -> CGPath {
        let tickPath = UIBezierPath.init()
        tickPath.move(to: CGPoint(x: scale(8), y: height * 0.5 + scale(1)))
        tickPath.addLine(to: CGPoint(x: width * 0.5 - scale(2), y: height - scale(8)))
        tickPath.addLine(to: CGPoint(x: width - scale(7), y: scale(9)))
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
        tickLayer.strokeColor = PhotoManager.isDark ? config.tickDarkColor.cgColor : config.tickColor.cgColor
        tickLayer.fillColor = UIColor.clear.cgColor
    }
    
    public func updateLayers() {
        backgroundLayer.frame = bounds
        if config.style == .tick {
            tickLayer.frame = bounds
        }
        drawBackgroundLayer()
        drawTextLayer()
        drawTickLayer()
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
