//
//  EditorStickerTextView+Draw.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

extension EditorStickerTextView {
    
    func createTextBackgroundLayer(path: CGPath) -> EditorStickerTextLayer {
        let textLayer = EditorStickerTextLayer()
        textLayer.path = path
        textLayer.lineWidth = 0
        let color = showBackgroudColor ? useBgColor.cgColor : UIColor.clear.cgColor
        textLayer.strokeColor = color
        textLayer.fillColor = color
        return textLayer
    }
    
    func changeTextColor(color: UIColor) {
        textView.textColor = color
        typingAttributes[NSAttributedString.Key.foregroundColor] = color
        textView.typingAttributes = typingAttributes
    }
    
    func preProccess() {
        maxIndex = 0
        if rectArray.count < 2 {
            return
        }
        for index in 0..<rectArray.count where index > 0 {
            maxIndex = index
            processRect(index: index)
        }
    }
    
    func processRect(index: Int) {
        if rectArray.count < 2 || index < 1 || index > maxIndex {
            return
        }
        var last = rectArray[index - 1]
        var cur = rectArray[index]
        if cur.width <= blankWidth || last.width <= blankWidth {
            return
        }
        var t1 = false
        var t2 = false
        if cur.minX > last.minX {
            if cur.minX - last.minX < 2 * layerRadius {
                cur = CGRect(x: last.minX, y: cur.minY, width: cur.width, height: cur.height)
                t1 = true
            }
        }else if cur.minX < last.minX {
            if last.minX - cur.minX < 2 * layerRadius {
                cur = CGRect(x: last.minX, y: cur.minY, width: cur.width, height: cur.height)
                t1 = true
            }
        }
        if cur.maxX > last.maxX {
            let poor = cur.maxX - last.maxX
            if poor < 2 * layerRadius {
                last = CGRect(x: last.minX, y: last.minY, width: cur.width, height: last.height)
                t2 = true
            }
        }
        if cur.maxX < last.maxX {
            let poor = last.maxX - cur.maxX
            if poor < 2 * layerRadius {
                cur = CGRect(x: cur.minX, y: cur.minY, width: last.width, height: cur.height)
                t1 = true
            }
        }
        if t1 {
            rectArray[index] = cur
            processRect(index: index + 1)
        }
        if t2 {
            rectArray[index - 1] = last
            processRect(index: index - 1)
        }
    }
    // swiftlint:disable function_body_length
    func drawBackgroundPath(rects: [CGRect]) -> UIBezierPath {
        // swiftlint:enable function_body_length
        self.rectArray = rects
        preProccess()
        let path = UIBezierPath()
        var bezierPath: UIBezierPath?
        var startPoint: CGPoint = .zero
        for (index, rect) in rectArray.enumerated() {
            if rect.width <= blankWidth {
                continue
            }
            let loctionX = rect.minX
            let loctionY = rect.minY
            var half = false
            if bezierPath == nil {
                bezierPath = .init()
                startPoint = CGPoint(x: loctionX, y: loctionY + layerRadius)
                bezierPath?.move(to: startPoint)
                bezierPath?.addArc(
                    withCenter: CGPoint(
                        x: loctionX + layerRadius,
                        y: loctionY + layerRadius
                    ),
                    radius: layerRadius,
                    startAngle: CGFloat.pi,
                    endAngle: 1.5 * CGFloat.pi,
                    clockwise: true
                )
                bezierPath?.addLine(to: CGPoint(x: rect.maxX - layerRadius, y: loctionY))
                bezierPath?.addArc(
                    withCenter: CGPoint(
                        x: rect.maxX - layerRadius,
                        y: loctionY + layerRadius
                    ),
                    radius: layerRadius,
                    startAngle: 1.5 * CGFloat.pi,
                    endAngle: 0,
                    clockwise: true
                )
            }else {
                let lastRect = rectArray[index - 1]
                var nextRect: CGRect?
                if lastRect.maxX > rect.maxX {
                    if index + 1 < rectArray.count {
                        nextRect = rectArray[index + 1]
                        if nextRect!.width > blankWidth &&
                            nextRect!.maxX > rect.maxX {
                            half = true
                        }
                    }
                    if half {
                        let radius = (nextRect!.minY - lastRect.maxY) / 2
                        let centerY = nextRect!.minY - radius
                        bezierPath?.addArc(
                            withCenter: CGPoint(
                                x: rect.maxX + radius,
                                y: centerY
                            ),
                            radius: radius,
                            startAngle: -CGFloat.pi * 0.5,
                            endAngle: -CGFloat.pi * 1.5,
                            clockwise: false
                        )
                    }else {
                        bezierPath?.addArc(
                            withCenter: CGPoint(
                                x: rect.maxX + layerRadius,
                                y: lastRect.maxY + layerRadius
                            ),
                            radius: layerRadius,
                            startAngle: -CGFloat.pi * 0.5,
                            endAngle: -CGFloat.pi,
                            clockwise: false
                        )
                    }
                }else if lastRect.maxX == rect.maxX {
                    bezierPath?.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - layerRadius))
                }else {
                    bezierPath?.addArc(
                        withCenter: CGPoint(
                            x: rect.maxX - layerRadius,
                            y: rect.minY + layerRadius
                        ),
                        radius: layerRadius,
                        startAngle: CGFloat.pi * 1.5,
                        endAngle: 0,
                        clockwise: true
                    )
                }
            }
            var hasNext = false
            if index + 1 < rectArray.count {
                let nextRect = rectArray[index + 1]
                if nextRect.width > blankWidth {
                    if rect.maxX > nextRect.maxX {
                        let point = CGPoint(x: rect.maxX, y: rect.maxY - layerRadius)
                        if let currentPoint = bezierPath?.currentPoint, point.equalTo(currentPoint) {
                            bezierPath?.addArc(
                                withCenter: CGPoint(
                                    x: rect.maxX - layerRadius,
                                    y: rect.maxY - layerRadius
                                ),
                                radius: layerRadius,
                                startAngle: 0,
                                endAngle: CGFloat.pi * 0.5,
                                clockwise: true
                            )
                        }else {
                            bezierPath?.addLine(to: point)
                            bezierPath?.addArc(
                                withCenter: CGPoint(
                                    x: rect.maxX - layerRadius,
                                    y: rect.maxY - layerRadius
                                ),
                                radius: layerRadius,
                                startAngle: 0,
                                endAngle: CGFloat.pi * 0.5,
                                clockwise: true
                            )
                        }
                        bezierPath?.addLine(to: CGPoint(x: nextRect.maxX + layerRadius, y: rect.maxY))
                    }else if rect.maxX == nextRect.maxX {
                        bezierPath?.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                    }else {
                        if !half {
                            let point = CGPoint(x: rect.maxX, y: nextRect.minY - layerRadius)
                            if let currentPoint = bezierPath?.currentPoint, point.equalTo(currentPoint) {
                                bezierPath?.addArc(
                                    withCenter: CGPoint(
                                        x: currentPoint.x + layerRadius,
                                        y: currentPoint.y
                                    ),
                                    radius: layerRadius,
                                    startAngle: -CGFloat.pi,
                                    endAngle: -CGFloat.pi * 1.5,
                                    clockwise: false
                                )
                            }else {
                                bezierPath?.addLine(to: point)
                                bezierPath?.addArc(
                                    withCenter: CGPoint(
                                        x: rect.maxX + layerRadius,
                                        y: nextRect.minY - layerRadius
                                    ),
                                    radius: layerRadius,
                                    startAngle: -CGFloat.pi,
                                    endAngle: -CGFloat.pi * 1.5,
                                    clockwise: false
                                )
                            }
                        }
                        bezierPath?.addLine(
                            to: CGPoint(
                                x: nextRect.maxX - layerRadius,
                                y: nextRect.minY
                            )
                        )
                    }
                    hasNext = true
                }
            }
            if !hasNext {
                bezierPath?.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - layerRadius))
                bezierPath?.addArc(
                    withCenter: CGPoint(
                        x: rect.maxX - layerRadius,
                        y: rect.maxY - layerRadius
                    ),
                    radius: layerRadius,
                    startAngle: 0,
                    endAngle: CGFloat.pi * 0.5,
                    clockwise: true
                )
                bezierPath?.addLine(to: CGPoint(x: rect.minX + layerRadius, y: rect.maxY))
                bezierPath?.addArc(
                    withCenter: CGPoint(
                        x: rect.minX + layerRadius,
                        y: rect.maxY - layerRadius
                    ),
                    radius: layerRadius,
                    startAngle: CGFloat.pi * 0.5,
                    endAngle: CGFloat.pi,
                    clockwise: true
                )
                bezierPath?.addLine(to: CGPoint(x: rect.minX, y: startPoint.y))
                if let bezierPath = bezierPath {
                    path.append(bezierPath)
                }
                bezierPath = nil
            }
        }
        return path
    }
    
    func drawTextBackgroudColor() {
        if textView.text.isEmpty {
            textLayer?.path = nil
            return
        }
        var rectArray: [CGRect] = []
        let layoutManager = textView.layoutManager
        let numberOfGlyphs = layoutManager.numberOfGlyphs
        var currentGlyph = 0
        while currentGlyph < numberOfGlyphs {
            var glyphRange = NSRange()
            var usedRect = layoutManager.lineFragmentUsedRect(forGlyphAt: currentGlyph, effectiveRange: &glyphRange)
            currentGlyph = NSMaxRange(glyphRange)
            var nextIsEmpty = true
            var lastLineIsEmpty = false
            if currentGlyph < numberOfGlyphs {
                let nextRange = layoutManager.range(ofNominallySpacedGlyphsContaining: currentGlyph)
                var nextLocation = nextRange.location
                var nextCount = nextLocation + nextRange.length
                if nextCount > text.count { nextCount = text.count }
                if nextLocation > nextCount { nextLocation = nextCount }
                if nextLocation + nextCount > 0 {
                    let nextString = text[nextLocation..<nextCount]
                    if !nextString.isEmpty || nextString != "\n" {
                        nextIsEmpty = false
                    }
                }
            }else {
                if text[text.index(before: text.endIndex)] == "\n" {
                    lastLineIsEmpty = true
                }
            }
            if !nextIsEmpty || lastLineIsEmpty {
                usedRect = CGRect(
                    x: usedRect.minX - 6,
                    y: usedRect.minY - 8,
                    width: usedRect.width + 12,
                    height: usedRect.height + 8
                )
            }else {
                usedRect = CGRect(
                    x: usedRect.minX - 6,
                    y: usedRect.minY - 8,
                    width: usedRect.width + 12,
                    height: usedRect.height + 16
                )
            }
            rectArray.append(usedRect)
        }
        let path = drawBackgroundPath(rects: rectArray)
        let color = showBackgroudColor ? useBgColor.cgColor : UIColor.clear.cgColor
        if let textLayer = textLayer {
            textLayer.path = path.cgPath
            textLayer.strokeColor = color
            textLayer.fillColor = color
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            textLayer.frame = CGRect(x: 15, y: 15, width: path.bounds.width, height: textView.contentSize.height)
            CATransaction.commit()
        }else {
            for subView in textView.subviews {
                if let textClass = NSClassFromString("_UITextContainerView"), subView.isKind(of: textClass) {
                    textLayer = createTextBackgroundLayer(path: path.cgPath)
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    textLayer?.frame = CGRect(
                        x: 15,
                        y: 15,
                        width: path.bounds.width,
                        height: textView.contentSize.height
                    )
                    CATransaction.commit()
                    subView.layer.insertSublayer(textLayer!, at: 0)
                    return
                }
            }
        }
    }
    
    func textMaximumWidth(view: UIView) -> CGFloat {
        let newSize = textView.sizeThatFits(view.size)
        return newSize.width
    }
    
    func textImage() -> UIImage? {
        textView.tintColor = .clear
        for subView in textView.subviews {
            if let textClass = NSClassFromString("_UITextContainerView"), subView.isKind(of: textClass) {
                let size = CGSize(width: textMaximumWidth(view: subView), height: subView.height)
                let image = subView.layer.convertedToImage(size: size)
                subView.layer.contents = nil
                return image
            }
        }
        return nil
    }
}
