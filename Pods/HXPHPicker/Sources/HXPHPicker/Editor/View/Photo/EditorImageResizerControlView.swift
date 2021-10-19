//
//  EditorImageResizerControlView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/22.
//

import UIKit

protocol EditorImageResizerControlViewDelegate: AnyObject {
    func controlView(beganChanged controlView: EditorImageResizerControlView, _ rect: CGRect)
    func controlView(endChanged controlView: EditorImageResizerControlView, _ rect: CGRect)
    func controlView(didChanged controlView: EditorImageResizerControlView, _ rect: CGRect)
}

class EditorImageResizerControlView: UIView {
    weak var delegate: EditorImageResizerControlViewDelegate?
    
    lazy var topControl: UIView = {
        let view = UIView.init()
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureRecognizerHandler(pan:)))
        view.addGestureRecognizer(pan)
        return view
    }()
    lazy var bottomControl: UIView = {
        let view = UIView.init()
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureRecognizerHandler(pan:)))
        view.addGestureRecognizer(pan)
        return view
    }()
    lazy var leftControl: UIView = {
        let view = UIView.init()
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureRecognizerHandler(pan:)))
        view.addGestureRecognizer(pan)
        return view
    }()
    lazy var rightControl: UIView = {
        let view = UIView.init()
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureRecognizerHandler(pan:)))
        view.addGestureRecognizer(pan)
        return view
    }()
    lazy var leftTopControl: UIView = {
        let view = UIView.init()
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureRecognizerHandler(pan:)))
        view.addGestureRecognizer(pan)
        return view
    }()
    lazy var rightTopControl: UIView = {
        let view = UIView.init()
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureRecognizerHandler(pan:)))
        view.addGestureRecognizer(pan)
        return view
    }()
    lazy var rightBottomControl: UIView = {
        let view = UIView.init()
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureRecognizerHandler(pan:)))
        view.addGestureRecognizer(pan)
        return view
    }()
    lazy var leftBottomControl: UIView = {
        let view = UIView.init()
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureRecognizerHandler(pan:)))
        view.addGestureRecognizer(pan)
        return view
    }()
    
    /// 固定比例
    var fixedRatio: Bool = false
    var aspectRatio: CGSize = .zero
    var maxImageresizerFrame: CGRect = .zero
    var imageresizerFrame: CGRect = .zero
    var currentFrame: CGRect = .zero
    var panning: Bool = false
    var controls: [ UIGestureRecognizer ] = []
    init() {
        super.init(frame: .zero)
        addSubview(topControl)
        addSubview(bottomControl)
        addSubview(leftControl)
        addSubview(rightControl)
        addSubview(leftTopControl)
        addSubview(leftBottomControl)
        addSubview(rightTopControl)
        addSubview(rightBottomControl)
        controls.append(topControl.gestureRecognizers!.first!)
        controls.append(bottomControl.gestureRecognizers!.first!)
        controls.append(leftControl.gestureRecognizers!.first!)
        controls.append(rightControl.gestureRecognizers!.first!)
        controls.append(leftTopControl.gestureRecognizers!.first!)
        controls.append(leftBottomControl.gestureRecognizers!.first!)
        controls.append(rightTopControl.gestureRecognizers!.first!)
        controls.append(rightBottomControl.gestureRecognizers!.first!)
    }
    
    func changeControl(enabled: Bool, index: Int) {
        for (item, control) in controls.enumerated() where item != index {
            (control as? UIPanGestureRecognizer)?.isEnabled = enabled
        }
    }
    func topControlHandler(_ point: CGPoint) {
        var rectX = currentFrame.minX
        var rectY = currentFrame.minY
        var rectW = currentFrame.width
        var rectH = currentFrame.height
        let widthRatio = aspectRatio.width / aspectRatio.height
        let heightRatio = aspectRatio.height / aspectRatio.width
        rectH -= point.y
        rectY += point.y
        if rectH < 50 {
            rectH = 50
            rectY = currentFrame.maxY - 50
        }
        if rectY < maxImageresizerFrame.minY {
            rectY = maxImageresizerFrame.minY
            rectH = currentFrame.maxY - maxImageresizerFrame.minY
        }
        if fixedRatio && !aspectRatio.equalTo(.zero) {
            var w = rectH * widthRatio
            if currentFrame.width > currentFrame.height {
                if rectH < 50 {
                    rectH = 50
                    rectY = currentFrame.maxY - rectH
                    w = rectH * widthRatio
                }
            }else {
                if w < 50 {
                    w = 50
                    rectH = w * heightRatio
                    rectY = currentFrame.maxY - rectH
                }
            }
            rectX = currentFrame.minX + (rectW - w) * 0.5
            rectW = w
            if rectX < maxImageresizerFrame.minX {
                rectX = maxImageresizerFrame.minX
            }
            if rectX + rectW > maxImageresizerFrame.maxX {
                rectX = maxImageresizerFrame.maxX - rectW
            }
            if rectW >= maxImageresizerFrame.width {
                rectX = maxImageresizerFrame.minX
                rectW = maxImageresizerFrame.width
                let h = rectW * heightRatio
                rectY += (rectH - h) * 0.5
                rectH = h
                let minY = currentFrame.maxY - rectH
                if rectY < minY {
                    rectY = minY
                }
            }
        }
        frame = CGRect(x: rectX, y: rectY, width: rectW, height: rectH)
    }
    func leftControlHandler(_ point: CGPoint) {
        var rectX = currentFrame.minX
        var rectY = currentFrame.minY
        var rectW = currentFrame.width
        var rectH = currentFrame.height
        let widthRatio = aspectRatio.width / aspectRatio.height
        let heightRatio = aspectRatio.height / aspectRatio.width
        rectX += point.x
        rectW -= point.x
        if rectW < 50 {
            rectW = 50
            rectX = currentFrame.maxX - 50
        }
        if rectX < maxImageresizerFrame.minX {
            rectX = maxImageresizerFrame.minX
            rectW = currentFrame.maxX - maxImageresizerFrame.minX
        }
        if fixedRatio && !aspectRatio.equalTo(.zero) {
            var h = rectW * heightRatio
            if currentFrame.width > currentFrame.height {
                if h < 50 {
                    h = 50
                    rectW = h * widthRatio
                    rectX = currentFrame.maxX - rectW
                }
            }else {
                if rectW < 50 {
                    rectW = 50
                    rectX = currentFrame.maxX - rectW
                    h = rectW * heightRatio
                }
            }
            rectY = currentFrame.minY + (rectH - h) * 0.5
            rectH = h
            if rectY < maxImageresizerFrame.minY {
                rectY = maxImageresizerFrame.minY
            }
            if rectY + rectH > maxImageresizerFrame.maxY {
                rectY = maxImageresizerFrame.maxY - rectH
            }
            if rectH >= maxImageresizerFrame.height {
                rectY = maxImageresizerFrame.minY
                rectH = maxImageresizerFrame.height
                let w = rectH * widthRatio
                rectX += (rectW - w) * 0.5
                rectW = w
                let minX = currentFrame.maxX - rectW
                if rectX < minX {
                    rectX = minX
                }
            }
        }
        frame = CGRect(x: rectX, y: rectY, width: rectW, height: rectH)
    }
    func rightControlHandler(_ point: CGPoint) {
        var rectX = currentFrame.minX
        var rectY = currentFrame.minY
        var rectW = currentFrame.width
        var rectH = currentFrame.height
        let widthRatio = aspectRatio.width / aspectRatio.height
        let heightRatio = aspectRatio.height / aspectRatio.width
        rectW += point.x
        if rectW < 50 {
            rectW = 50
        }
        if rectW > maxImageresizerFrame.maxX - currentFrame.minX {
            rectW = maxImageresizerFrame.maxX - currentFrame.minX
        }
        if fixedRatio && !aspectRatio.equalTo(.zero) {
            var h = rectW * heightRatio
            if currentFrame.width > currentFrame.height {
                if h < 50 {
                    h = 50
                    rectW = h * widthRatio
                }
            }else {
                if rectW < 50 {
                    rectW = 50
                    h = rectW * heightRatio
                }
            }
            rectY = currentFrame.minY + (rectH - h) * 0.5
            rectH = h
            if rectY < maxImageresizerFrame.minY {
                rectY = maxImageresizerFrame.minY
            }
            if rectY + rectH > maxImageresizerFrame.maxY {
                rectY = maxImageresizerFrame.maxY - rectH
            }
            if rectH >= maxImageresizerFrame.height {
                rectY = maxImageresizerFrame.minY
                rectH = maxImageresizerFrame.height
                let w = rectH * widthRatio
                rectX += (rectW - w) * 0.5
                rectW = w
                let maxX = currentFrame.minX + rectW
                if rectX + rectW > maxX {
                    rectX = maxX - rectW
                }
            }
        }
        frame = CGRect(x: rectX, y: rectY, width: rectW, height: rectH)
    }
    func bottomControlHandler(_ point: CGPoint) {
        var rectX = currentFrame.minX
        var rectY = currentFrame.minY
        var rectW = currentFrame.width
        var rectH = currentFrame.height
        let widthRatio = aspectRatio.width / aspectRatio.height
        let heightRatio = aspectRatio.height / aspectRatio.width
        rectH += point.y
        if rectH < 50 {
            rectH = 50
        }
        if rectH > maxImageresizerFrame.maxY - currentFrame.minY {
            rectH = maxImageresizerFrame.maxY - currentFrame.minY
        }
        if fixedRatio && !aspectRatio.equalTo(.zero) {
            var w = rectH * widthRatio
            if currentFrame.width > currentFrame.height {
                if rectH < 50 {
                    rectH = 50
                    w = rectH * widthRatio
                }
            }else {
                if w < 50 {
                    w = 50
                    rectH = w * heightRatio
                }
            }
            rectX = currentFrame.minX + (rectW - w) * 0.5
            rectW = w
            if rectX < maxImageresizerFrame.minX {
                rectX = maxImageresizerFrame.minX
            }
            if rectX + rectW > maxImageresizerFrame.maxX {
                rectX = maxImageresizerFrame.maxX - rectW
            }
            if rectW >= maxImageresizerFrame.width {
                rectX = maxImageresizerFrame.minX
                rectW = maxImageresizerFrame.width
                let h = rectW * heightRatio
                rectY += (rectH - h) * 0.5
                rectH = h
                let maxY = currentFrame.minY + rectH
                if rectY + rectH > maxY {
                    rectY = maxY - rectH
                }
            }
        }
        frame = CGRect(x: rectX, y: rectY, width: rectW, height: rectH)
    }
    func leftTopControlHandler(_ point: CGPoint) {
        var rectX = currentFrame.minX
        var rectY = currentFrame.minY
        var rectW = currentFrame.width
        var rectH = currentFrame.height
        let widthRatio = aspectRatio.width / aspectRatio.height
        let heightRatio = aspectRatio.height / aspectRatio.width
        if fixedRatio && !aspectRatio.equalTo(.zero) {
            if aspectRatio.width > aspectRatio.height {
                rectW -= point.x
                rectH = rectW * heightRatio
            }else {
                rectH -= point.y
                rectW = rectH * widthRatio
            }
            if currentFrame.width > currentFrame.height {
                if rectH < 50 {
                    rectH = 50
                    rectW = rectH * widthRatio
                }
            }else {
                if rectW < 50 {
                    rectW = 50
                    rectH = rectW * heightRatio
                }
            }
            if rectW > currentFrame.maxX - maxImageresizerFrame.minX {
                rectW = currentFrame.maxX - maxImageresizerFrame.minX
                rectH = rectW * heightRatio
            }
            if rectH > currentFrame.maxY - maxImageresizerFrame.minY {
                rectH = currentFrame.maxY - maxImageresizerFrame.minY
                rectW = rectH * widthRatio
            }
            rectX = currentFrame.maxX - rectW
            rectY = currentFrame.maxY - rectH
        }else {
            rectX += point.x
            rectY += point.y
            rectW -= point.x
            rectH -= point.y
            if rectW < 50 {
                rectW = 50
                rectX = currentFrame.maxX - 50
            }
            if rectH < 50 {
                rectH = 50
                rectY = currentFrame.maxY - 50
            }
            if rectX < maxImageresizerFrame.minX {
                rectX = maxImageresizerFrame.minX
                rectW = currentFrame.maxX - maxImageresizerFrame.minX
            }
            if rectY < maxImageresizerFrame.minY {
                rectY = maxImageresizerFrame.minY
                rectH = currentFrame.maxY - maxImageresizerFrame.minY
            }
        }
        frame = CGRect(x: rectX, y: rectY, width: rectW, height: rectH)
    }
    func leftBottomControlHandler(_ point: CGPoint) {
        var rectX = currentFrame.minX
        let rectY = currentFrame.minY
        var rectW = currentFrame.width
        var rectH = currentFrame.height
        let widthRatio = aspectRatio.width / aspectRatio.height
        let heightRatio = aspectRatio.height / aspectRatio.width
        if fixedRatio && !aspectRatio.equalTo(.zero) {
            if aspectRatio.width > aspectRatio.height {
                rectW -= point.x
                rectH = rectW * heightRatio
            }else {
                rectH += point.y
                rectW = rectH * widthRatio
            }
            if currentFrame.width > currentFrame.height {
                if rectH < 50 {
                    rectH = 50
                    rectW = rectH * widthRatio
                }
            }else {
                if rectW < 50 {
                    rectW = 50
                    rectH = rectW * heightRatio
                }
            }
            if rectW > currentFrame.maxX - maxImageresizerFrame.minX {
                rectW = currentFrame.maxX - maxImageresizerFrame.minX
                rectH = rectW * heightRatio
            }
            if rectH > maxImageresizerFrame.maxY - currentFrame.minY {
                rectH = maxImageresizerFrame.maxY - currentFrame.minY
                rectW = rectH * widthRatio
            }
            rectX = currentFrame.maxX - rectW
        }else {
            rectX += point.x
            rectW -= point.x
            rectH += point.y
            if rectW < 50 {
                rectW = 50
                rectX = currentFrame.maxX - 50
            }
            if rectH < 50 {
                rectH = 50
            }
            if rectX < maxImageresizerFrame.minX {
                rectX = maxImageresizerFrame.minX
                rectW = currentFrame.maxX - maxImageresizerFrame.minX
            }
            if rectH > maxImageresizerFrame.maxY - currentFrame.minY {
                rectH = maxImageresizerFrame.maxY - currentFrame.minY
            }
        }
        frame = CGRect(x: rectX, y: rectY, width: rectW, height: rectH)
    }
    func rightTopControlHandler(_ point: CGPoint) {
        let rectX = currentFrame.minX
        var rectY = currentFrame.minY
        var rectW = currentFrame.width
        var rectH = currentFrame.height
        let widthRatio = aspectRatio.width / aspectRatio.height
        let heightRatio = aspectRatio.height / aspectRatio.width
        if fixedRatio && !aspectRatio.equalTo(.zero) {
            if aspectRatio.width > aspectRatio.height {
                rectW += point.x
                rectH = rectW * heightRatio
            }else {
                rectH -= point.y
                rectW = rectH * widthRatio
            }
            if currentFrame.width > currentFrame.height {
                if rectH < 50 {
                    rectH = 50
                    rectW = rectH * widthRatio
                }
            }else {
                if rectW < 50 {
                    rectW = 50
                    rectH = rectW * heightRatio
                }
            }
            if rectW > maxImageresizerFrame.maxX - currentFrame.minX {
                rectW = maxImageresizerFrame.maxX - currentFrame.minX
                rectH = rectW * heightRatio
            }
            rectY = currentFrame.maxY - rectH
            if rectY < maxImageresizerFrame.minY {
                rectY = maxImageresizerFrame.minY
                rectH = currentFrame.maxY - maxImageresizerFrame.minY
                rectW = rectH * widthRatio
            }
        }else {
            rectW += point.x
            rectY += point.y
            rectH -= point.y
            if rectW < 50 {
                rectW = 50
            }
            if rectH < 50 {
                rectH = 50
                rectY = currentFrame.maxY - 50
            }
            if rectW > maxImageresizerFrame.maxX - currentFrame.minX {
                rectW = maxImageresizerFrame.maxX - currentFrame.minX
            }
            if rectY < maxImageresizerFrame.minY {
                rectY = maxImageresizerFrame.minY
                rectH = currentFrame.maxY - maxImageresizerFrame.minY
            }
        }
        frame = CGRect(x: rectX, y: rectY, width: rectW, height: rectH)
    }
    func rightBottomControlHandler(_ point: CGPoint) {
        let rectX = currentFrame.minX
        let rectY = currentFrame.minY
        var rectW = currentFrame.width
        var rectH = currentFrame.height
        let widthRatio = aspectRatio.width / aspectRatio.height
        let heightRatio = aspectRatio.height / aspectRatio.width
        if fixedRatio && !aspectRatio.equalTo(.zero) {
            if aspectRatio.width > aspectRatio.height {
                rectW += point.x
                rectH = rectW * heightRatio
            }else {
                rectH += point.y
                rectW = rectH * widthRatio
            }
            if currentFrame.width > currentFrame.height {
                if rectH < 50 {
                    rectH = 50
                    rectW = rectH * widthRatio
                }
            }else {
                if rectW < 50 {
                    rectW = 50
                    rectH = rectW * heightRatio
                }
            }
            if rectW > maxImageresizerFrame.maxX - currentFrame.minX {
                rectW = maxImageresizerFrame.maxX - currentFrame.minX
                rectH = rectW * heightRatio
            }
            if rectH > maxImageresizerFrame.maxY - currentFrame.minY {
                rectH = maxImageresizerFrame.maxY - currentFrame.minY
                rectW = rectH * widthRatio
            }
        }else {
            rectW += point.x
            rectH += point.y
            if rectW < 50 {
                rectW = 50
            }
            if rectH < 50 {
                rectH = 50
            }
            if rectW > maxImageresizerFrame.maxX - currentFrame.minX {
                rectW = maxImageresizerFrame.maxX - currentFrame.minX
            }
            if rectH > maxImageresizerFrame.maxY - currentFrame.minY {
                rectH = maxImageresizerFrame.maxY - currentFrame.minY
            }
        }
        frame = CGRect(x: rectX, y: rectY, width: rectW, height: rectH)
    }
    
    @objc func panGestureRecognizerHandler(pan: UIPanGestureRecognizer) {
        let view = pan.view
        let point = pan.translation(in: view)
        if pan.state == .began {
            changeControl(enabled: false, index: controls.firstIndex(of: pan)!)
            panning = true
            delegate?.controlView(beganChanged: self, frame)
            currentFrame = self.frame
        }
        if view == topControl {
            topControlHandler(point)
        }else if view == leftControl {
            leftControlHandler(point)
        }else if view == rightControl {
            rightControlHandler(point)
        }else if view == bottomControl {
            bottomControlHandler(point)
        }else if view == leftTopControl {
            leftTopControlHandler(point)
        }else if view == leftBottomControl {
            leftBottomControlHandler(point)
        }else if view == rightTopControl {
            rightTopControlHandler(point)
        }else if view == rightBottomControl {
            rightBottomControlHandler(point)
        }
        delegate?.controlView(didChanged: self, frame)
        if pan.state == .cancelled || pan.state == .ended || pan.state == .failed {
            delegate?.controlView(endChanged: self, frame)
            panning = false
            changeControl(enabled: true, index: controls.firstIndex(of: pan)!)
        }
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !isUserInteractionEnabled {
            return nil
        }
        if topControl.frame.contains(point) {
            return topControl
        }else if leftControl.frame.contains(point) {
            return leftControl
        }else if rightControl.frame.contains(point) {
            return rightControl
        }else if bottomControl.frame.contains(point) {
            return bottomControl
        }else if leftTopControl.frame.contains(point) {
            return leftTopControl
        }else if leftBottomControl.frame.contains(point) {
            return leftBottomControl
        }else if rightTopControl.frame.contains(point) {
            return rightTopControl
        }else if rightBottomControl.frame.contains(point) {
            return rightBottomControl
        }
        return nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let lineMarign: CGFloat = 20
        topControl.frame = CGRect(x: lineMarign, y: -lineMarign, width: width - lineMarign * 2, height: lineMarign * 2)
        leftControl.frame = CGRect(
            x: -lineMarign,
            y: lineMarign,
            width: lineMarign * 2,
            height: height - lineMarign * 2
        )
        rightControl.frame = CGRect(
            x: width - lineMarign,
            y: lineMarign,
            width: lineMarign * 2,
            height: height - lineMarign * 2
        )
        bottomControl.frame = CGRect(
            x: lineMarign,
            y: height - lineMarign,
            width: width - lineMarign * 2,
            height: lineMarign * 2
        )
        leftTopControl.frame = CGRect(
            x: -lineMarign,
            y: -lineMarign,
            width: lineMarign * 2,
            height: lineMarign * 2
        )
        leftBottomControl.frame = CGRect(
            x: -lineMarign,
            y: height - lineMarign,
            width: lineMarign * 2,
            height: lineMarign * 2
        )
        rightTopControl.frame = CGRect(
            x: width - lineMarign,
            y: -lineMarign,
            width: lineMarign * 2,
            height: lineMarign * 2
        )
        rightBottomControl.frame = CGRect(
            x: width - lineMarign,
            y: height - lineMarign,
            width: lineMarign * 2,
            height: lineMarign * 2
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
