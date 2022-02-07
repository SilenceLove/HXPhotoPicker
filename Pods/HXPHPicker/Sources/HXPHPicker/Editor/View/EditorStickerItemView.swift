//
//  EditorStickerItemView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/20.
//

import UIKit

protocol EditorStickerItemViewDelegate: AnyObject {
    func stickerItemView(shouldTouchBegan itemView: EditorStickerItemView) -> Bool
    func stickerItemView(didTouchBegan itemView: EditorStickerItemView)
    func stickerItemView(touchEnded itemView: EditorStickerItemView)
    func stickerItemView(_ itemView: EditorStickerItemView, updateStickerText item: EditorStickerItem)
    func stickerItemView(_ itemView: EditorStickerItemView, tapGestureRecognizerNotInScope point: CGPoint)
    func stickerItemView(_ itemView: EditorStickerItemView, panGestureRecognizerChanged panGR: UIPanGestureRecognizer)
    func stickerItemView(panGestureRecognizerEnded itemView: EditorStickerItemView) -> Bool
    func stickerItemView(_ itemView: EditorStickerItemView, moveToCenter rect: CGRect) -> Bool
    func stickerItemView(_ itemView: EditorStickerItemView, maxScale itemSize: CGSize) -> CGFloat
    func stickerItemView(_ itemView: EditorStickerItemView, minScale itemSize: CGSize) -> CGFloat
}

class EditorStickerItemView: UIView {
    weak var delegate: EditorStickerItemViewDelegate?
    lazy var contentView: EditorStickerContentView = {
        let view = EditorStickerContentView(item: item)
        view.center = center
        return view
    }()
    lazy var externalBorder: CALayer = {
        let externalBorder = CALayer()
        externalBorder.shadowOpacity = 0.3
        externalBorder.shadowOffset = CGSize(width: 0, height: 0)
        externalBorder.shadowRadius = 1
        externalBorder.shouldRasterize = true
        externalBorder.rasterizationScale = UIScreen.main.scale
        return externalBorder
    }()
    var item: EditorStickerItem
    var isEnabled: Bool = true {
        didSet {
            isUserInteractionEnabled = isEnabled
            contentView.isUserInteractionEnabled = isEnabled
        }
    }
    var isDelete: Bool = false
    var scale: CGFloat
    var touching: Bool = false
    var isSelected: Bool = false {
        willSet {
            if isSelected == newValue {
                return
            }
            if item.music == nil {
                externalBorder.cornerRadius = newValue ? 1 / scale : 0
                externalBorder.borderWidth = newValue ? 1 / scale : 0
            }
            isUserInteractionEnabled = newValue
            
            if newValue {
                update(size: contentView.item.frame.size)
            }else {
                firstTouch = false
            }
        }
    }
    var itemMargin: CGFloat = 20
    
    var initialScale: CGFloat = 1
    var initialPoint: CGPoint = .zero
    var initialRadian: CGFloat = 0
    var initialAngle: CGFloat = 0
    var initialMirrorType: EditorImageResizerView.MirrorType = .none
    
    init(item: EditorStickerItem, scale: CGFloat) {
        self.item = item
        self.scale = scale
        let rect = CGRect(x: 0, y: 0, width: item.frame.width, height: item.frame.height)
        super.init(frame: rect)
        let margin = itemMargin / scale
        externalBorder.frame = CGRect(
            x: -margin * 0.5,
            y: -margin * 0.5,
            width: width + margin,
            height: height + margin
        )
        layer.addSublayer(externalBorder)
        contentView.scale = scale
        addSubview(contentView)
        if item.music == nil {
            externalBorder.borderColor = UIColor.white.cgColor
        }
//        layer.shadowOpacity = 0.3
//        layer.shadowOffset = CGSize(width: 0, height: 0)
//        layer.shadowRadius = 1
        initGestures()
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if bounds.contains(point) {
            return contentView
        }
        return view
    }
    func invalidateTimer() {
        self.contentView.invalidateTimer()
    }
    func initGestures() {
        contentView.isUserInteractionEnabled = true
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(contentViewTapClick(tapGR:)))
        contentView.addGestureRecognizer(tapGR)
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(contentViewPanClick(panGR:)))
        contentView.addGestureRecognizer(panGR)
        if item.music == nil {
            let pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(contentViewPinchClick(pinchGR:)))
            contentView.addGestureRecognizer(pinchGR)
        }
        let rotationGR = UIRotationGestureRecognizer(
            target: self,
            action: #selector(contentViewRotationClick(rotationGR:))
        )
        contentView.addGestureRecognizer(rotationGR)
    }
    
    @objc func contentViewTapClick(tapGR: UITapGestureRecognizer) {
        if isDelete {
            return
        }
        if let shouldTouch = delegate?.stickerItemView(shouldTouchBegan: self), !shouldTouch {
            return
        }
        let point = tapGR.location(in: self)
        if !contentView.frame.contains(point) {
            delegate?.stickerItemView(self, tapGestureRecognizerNotInScope: point)
            isSelected = false
            return
        }
        if firstTouch && isSelected && item.text != nil && !touching {
            delegate?.stickerItemView(self, updateStickerText: item)
        }
        firstTouch = true
    }
    @objc func contentViewPanClick(panGR: UIPanGestureRecognizer) {
        if isDelete {
            return
        }
        if let shouldTouch = delegate?.stickerItemView(shouldTouchBegan: self), !shouldTouch {
            return
        }
        switch panGR.state {
        case .began:
//            layer.shadowOpacity = 0
            touching = true
            firstTouch = true
            delegate?.stickerItemView(didTouchBegan: self)
            isSelected = true
            initialPoint = self.center
        case .changed:
            let point = panGR.translation(in: superview)
            center = CGPoint(x: initialPoint.x + point.x, y: initialPoint.y + point.y)
            delegate?.stickerItemView(self, panGestureRecognizerChanged: panGR)
        case .ended, .cancelled, .failed:
//            layer.shadowOpacity = 0.3
            touching = false
            var isDelete = false
            if let panIsDelete = delegate?.stickerItemView(panGestureRecognizerEnded: self) {
                isDelete = panIsDelete
            }
            self.delegate?.stickerItemView(touchEnded: self)
            let rect = convert(contentView.frame, to: superview?.viewController?.view)
            if let moveToCenter = delegate?.stickerItemView(self, moveToCenter: rect), !isDelete {
                let keyWindow = UIApplication.shared.keyWindow
                if let view = keyWindow, moveToCenter,
                   let viewCenter = superview?.convert(
                    CGPoint(x: view.width * 0.5, y: view.height * 0.5),
                    from: view
                   ) {
                    UIView.animate(withDuration: 0.25) {
                        self.center = viewCenter
                    }
                }
            }
        default:
            break
        }
    }
    @objc func contentViewPinchClick(pinchGR: UIPinchGestureRecognizer) {
        if isDelete {
            return
        }
        if let shouldTouch = delegate?.stickerItemView(shouldTouchBegan: self), !shouldTouch {
            return
        }
        switch pinchGR.state {
        case .began:
//            layer.shadowOpacity = 0
            touching = true
            firstTouch = true
            delegate?.stickerItemView(didTouchBegan: self)
            isSelected = true
            initialScale = pinchScale
            update(pinchScale: initialScale * pinchGR.scale, isPinch: true, isMirror: true)
        case .changed:
            update(pinchScale: initialScale * pinchGR.scale, isPinch: true, isMirror: true)
        case .ended, .cancelled, .failed:
//            layer.shadowOpacity = 0.3
            touching = false
            delegate?.stickerItemView(touchEnded: self)
        default:
            break
        }
        if pinchGR.state == .began && pinchGR.state == .changed {
            pinchGR.scale = 1
        }
    }
    @objc func contentViewRotationClick(rotationGR: UIRotationGestureRecognizer) {
        if isDelete {
            return
        }
        if let shouldTouch = delegate?.stickerItemView(shouldTouchBegan: self), !shouldTouch {
            return
        }
        switch rotationGR.state {
        case .began:
//            layer.shadowOpacity = 0
            firstTouch = true
            touching = true
            isSelected = true
            delegate?.stickerItemView(didTouchBegan: self)
            initialRadian = radian
            rotationGR.rotation = 0
        case .changed:
            if let superView = superview, superView is EditorStickerView {
                if superMirrorType == .none {
                    if mirrorType == .horizontal {
                        radian = initialRadian - rotationGR.rotation
                    }else {
                        radian = initialRadian + rotationGR.rotation
                    }
                }else {
                    if mirrorType == .horizontal {
                        radian = initialRadian - rotationGR.rotation
                    }else {
                        radian = initialRadian + rotationGR.rotation
                    }
                }
            }else {
                if superMirrorType == .none {
                    if mirrorType == .horizontal {
                        radian = initialRadian - rotationGR.rotation
                    }else {
                        radian = initialRadian + rotationGR.rotation
                    }
                }else {
                    if mirrorType == .horizontal {
                        radian = initialRadian - rotationGR.rotation
                    }else {
                        radian = initialRadian + rotationGR.rotation
                    }
                }
            }
            update(pinchScale: pinchScale, rotation: radian, isMirror: true)
        case .ended, .cancelled, .failed:
//            layer.shadowOpacity = 0.3
            touching = false
            delegate?.stickerItemView(touchEnded: self)
            rotationGR.rotation = 0
        default:
            break
        }
    }
    var firstTouch: Bool = false
    var radian: CGFloat = 0
    var pinchScale: CGFloat = 1
    var mirrorType: EditorImageResizerView.MirrorType = .none
    var superMirrorType: EditorImageResizerView.MirrorType = .none
    var superAngle: CGFloat = 0
    func update(pinchScale: CGFloat,
                rotation: CGFloat = CGFloat(MAXFLOAT),
                isInitialize: Bool = false,
                isPinch: Bool = false,
                isMirror: Bool = false) {
        if rotation != CGFloat(MAXFLOAT) {
            radian = rotation
        }
        var minScale = 0.2 / scale
        var maxScale = 3.0 / scale
        if let min = delegate?.stickerItemView(self, minScale: item.frame.size) {
            minScale = min / scale
        }
        if let max = delegate?.stickerItemView(self, maxScale: item.frame.size) {
            maxScale = max / scale
        }
        if isInitialize {
            self.pinchScale = pinchScale
        }else {
            if isPinch {
                if pinchScale > maxScale {
                    if pinchScale < initialScale {
                        self.pinchScale = pinchScale
                    }else {
                        if initialScale < maxScale {
                            self.pinchScale = min(max(pinchScale, minScale), maxScale)
                        }else {
                            self.pinchScale = initialScale
                        }
                    }
                }else if pinchScale < minScale {
                    if pinchScale > initialScale {
                        self.pinchScale = pinchScale
                    }else {
                        if minScale < initialScale {
                            self.pinchScale = min(max(pinchScale, minScale), maxScale)
                        }else {
                            self.pinchScale = initialScale
                        }
                    }
                }else {
                    self.pinchScale = min(max(pinchScale, minScale), maxScale)
                }
            }else {
                self.pinchScale = pinchScale
            }
        }
        transform = .identity
        var margin = itemMargin / scale
        if touching {
            margin *= scale
            contentView.transform = .init(scaleX: self.pinchScale * scale, y: self.pinchScale * scale)
        }else {
            contentView.transform = .init(scaleX: self.pinchScale, y: self.pinchScale)
        }
        var rect = frame
        rect.origin.x += (rect.width - contentView.width) / 2
        rect.origin.y += (rect.height - contentView.height) / 2
        rect.size.width = contentView.width
        rect.size.height = contentView.height
        frame = rect
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        externalBorder.frame = CGRect(
            x: -margin * 0.5,
            y: -margin * 0.5,
            width: width + margin,
            height: height + margin
        )
        CATransaction.commit()
        
        contentView.center = CGPoint(x: rect.width * 0.5, y: rect.height * 0.5)
        if isMirror {
            if let superView = superview, superView is EditorStickerView {
                if superMirrorType == .none {
                    if mirrorType == .horizontal {
                        transform = transform.scaledBy(x: -1, y: 1)
                    }
                }else {
                    if mirrorType == .none {
                        transform = transform.scaledBy(x: -1, y: 1)
                    }
                }
            }else {
                if superMirrorType == .none {
                    if mirrorType == .horizontal {
                        if superAngle.truncatingRemainder(dividingBy: 180) != 0 {
                            transform = transform.scaledBy(x: 1, y: -1)
                        }else {
                            transform = transform.scaledBy(x: -1, y: 1)
                        }
                    }
                }else {
                    if mirrorType == .horizontal {
                        transform = transform.scaledBy(x: -1, y: 1)
                    }else {
                        if superAngle.truncatingRemainder(dividingBy: 180) != 0 {
                            transform = transform.scaledBy(x: -1, y: -1)
                        }else {
                            transform = transform.scaledBy(x: 1, y: 1)
                        }
                    }
                }
            }
        }
        transform = transform.rotated(by: radian)
        if isSelected && item.music == nil {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if touching {
                externalBorder.borderWidth = 1
                externalBorder.cornerRadius = 1
            }else {
                externalBorder.borderWidth = 1 / scale
                externalBorder.cornerRadius = 1 / scale
            }
            CATransaction.commit()
        }
    }
    func update(item: EditorStickerItem) {
        self.item = item
        contentView.update(item: item)
        update(size: item.frame.size, isMirror: true)
    }
    func update(size: CGSize, isMirror: Bool = false) {
        let center = self.center
        var frame = frame
        frame.size = CGSize(width: size.width, height: size.height)
        self.frame = frame
        self.center = center
        let margin = itemMargin / scale
        externalBorder.frame = CGRect(
            x: -margin * 0.5,
            y: -margin * 0.5,
            width: width + margin,
            height: height + margin
        )
        contentView.transform = .identity
        transform = .identity
        
        contentView.size = size
        contentView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        update(pinchScale: pinchScale, rotation: radian, isMirror: isMirror)
    }
    func resetRotaion() {
        update(pinchScale: pinchScale, rotation: radian, isMirror: true)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
