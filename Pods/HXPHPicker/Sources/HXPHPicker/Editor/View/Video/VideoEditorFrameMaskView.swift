//
//  VideoEditorFrameMaskView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

protocol VideoEditorFrameMaskViewDelegate: AnyObject {
    func frameMaskView(validRectDidChanged frameMaskView: VideoEditorFrameMaskView)
    func frameMaskView(validRectEndChanged frameMaskView: VideoEditorFrameMaskView)
}

class VideoEditorFrameMaskView: UIView {
    let imageWidth: CGFloat = 8
    var validRectX: CGFloat {
        30 + UIDevice.leftMargin
    }
    
    weak var delegate: VideoEditorFrameMaskViewDelegate?
    var validRect: CGRect = .zero {
        didSet {
            leftControl.frame = CGRect(x: validRect.minX - imageWidth * 0.5, y: 0, width: imageWidth, height: height)
            rightControl.frame = CGRect(x: validRect.maxX - imageWidth * 0.5, y: 0, width: imageWidth, height: height)
            drawMaskLayer()
        }
    }
    var minWidth: CGFloat = 0
    lazy var maskLayer: CAShapeLayer = {
        let maskLayer = CAShapeLayer.init()
        maskLayer.contentsScale = UIScreen.main.scale
        return maskLayer
    }()
    lazy var restrictionLayer: CAShapeLayer = {
        let restrictionLayer = CAShapeLayer.init()
        restrictionLayer.contentsScale = UIScreen.main.scale
        restrictionLayer.lineWidth = 4
        restrictionLayer.fillColor = UIColor.clear.cgColor
        restrictionLayer.strokeColor = UIColor.white.cgColor
        return restrictionLayer
    }()
    lazy var controlLayer: CAShapeLayer = {
        let controlLayer = CAShapeLayer.init()
        controlLayer.contentsScale = UIScreen.main.scale
        controlLayer.lineWidth = imageWidth
        controlLayer.fillColor = UIColor.clear.cgColor
        controlLayer.strokeColor = UIColor.white.cgColor
        return controlLayer
    }()
    lazy var gripMaskLayer: CAShapeLayer = {
        let gripMaskLayer = CAShapeLayer.init()
        gripMaskLayer.contentsScale = UIScreen.main.scale
        gripMaskLayer.lineWidth = 1
        gripMaskLayer.fillColor = UIColor.clear.cgColor
        gripMaskLayer.strokeColor = UIColor.lightGray.cgColor
        return gripMaskLayer
    }()
    
    func drawMaskLayer() {
        let maskPath = UIBezierPath(rect: bounds)
        maskPath.append(
            UIBezierPath(
                rect: CGRect(
                    x: validRect.minX + 4,
                    y: validRect.minY + 2,
                    width: validRect.width - 8,
                    height: validRect.height - 4
                )
            ).reversing()
        )
        maskLayer.path = maskPath.cgPath
        
        let restrictionpath = UIBezierPath.init(rect: validRect)
        restrictionLayer.path = restrictionpath.cgPath
        
        let controlPath = UIBezierPath.init()
        controlPath.move(to: CGPoint(x: validRect.minX, y: validRect.minY - 2))
        controlPath.addLine(to: CGPoint(x: validRect.minX, y: validRect.maxY + 2))
        controlPath.move(to: CGPoint(x: validRect.maxX, y: validRect.minY - 2))
        controlPath.addLine(to: CGPoint(x: validRect.maxX, y: validRect.maxY + 2))
        controlLayer.path = controlPath.cgPath
        
        let gripPath = UIBezierPath.init()
        gripPath.move(to: CGPoint(x: validRect.minX - 1.5, y: validRect.midY - 4))
        gripPath.addLine(to: CGPoint(x: validRect.minX - 1.5, y: validRect.midY + 4))
        gripPath.move(to: CGPoint(x: validRect.minX + 1.5, y: validRect.midY - 4))
        gripPath.addLine(to: CGPoint(x: validRect.minX + 1.5, y: validRect.midY + 4))
        
        gripPath.move(to: CGPoint(x: validRect.maxX - 1.5, y: validRect.midY - 4))
        gripPath.addLine(to: CGPoint(x: validRect.maxX - 1.5, y: validRect.midY + 4))
        gripPath.move(to: CGPoint(x: validRect.maxX + 1.5, y: validRect.midY - 4))
        gripPath.addLine(to: CGPoint(x: validRect.maxX + 1.5, y: validRect.midY + 4))
        gripMaskLayer.path = gripPath.cgPath
    }
    
    lazy var leftControl: UIView = {
        let leftControl = UIView.init()
        leftControl.tag = 0
        let panGR = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureRecognizerAction(panGR:)))
        leftControl.addGestureRecognizer(panGR)
        return leftControl
    }()
    lazy var rightControl: UIView = {
        let rightControl = UIView.init()
        rightControl.tag = 1
        let panGR = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureRecognizerAction(panGR:)))
        rightControl.addGestureRecognizer(panGR)
        return rightControl
    }()
    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        layer.mask = maskLayer
        layer.addSublayer(restrictionLayer)
        layer.addSublayer(controlLayer)
        layer.addSublayer(gripMaskLayer)
        addSubview(leftControl)
        addSubview(rightControl)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func panGestureRecognizerAction(panGR: UIPanGestureRecognizer) {
        var point = panGR.location(in: self)
        var rect = validRect
         
        let minX = imageWidth * 0.5 + validRectX
        
        switch panGR.view?.tag {
        case 0:
            if point.x < minX {
                point.x = minX
            }else {
                if rightControl.x - point.x - imageWidth * 0.5 <= minWidth {
                    point.x = rightControl.x - minWidth - imageWidth * 0.5
                }
            }
            point.y = 0
            
            rect.size.width = rect.maxX - point.x
            rect.origin.x = point.x
        case 1:
            let maxX = width - imageWidth * 0.5 - validRectX
            if point.x > maxX {
                point.x = maxX
            }else {
                if point.x - leftControl.frame.maxX - imageWidth * 0.5 <= minWidth {
                    point.x = leftControl.frame.maxX + minWidth + imageWidth * 0.5
                }
            }
            point.y = 0
            rect.size.width = point.x - rect.origin.x
        default:
            break
        }
        switch panGR.state {
        case .began, .changed:
            delegate?.frameMaskView(validRectDidChanged: self)
        case .ended, .cancelled:
            delegate?.frameMaskView(validRectEndChanged: self)
        default:
            break
        }
        validRect = rect
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var leftRect = leftControl.frame
        leftRect.origin.x -= imageWidth * 2
        leftRect.size.width += imageWidth * 4
        var rightRect = rightControl.frame
        rightRect.origin.x -= imageWidth * 2
        rightRect.size.width += imageWidth * 4
        if leftRect.contains(point) {
            return leftControl
        }
        if rightRect.contains(point) {
            return rightControl
        }
        return nil
    }
}
