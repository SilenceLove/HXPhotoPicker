//
//  EditorStickersItemView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/4/13.
//

import UIKit

protocol EditorStickersItemViewDelegate: AnyObject {
    func stickerItemView(shouldTouchBegan itemView: EditorStickersItemView) -> Bool
    func stickerItemView(didTouchBegan itemView: EditorStickersItemView)
    func stickerItemView(touchEnded itemView: EditorStickersItemView)
    func stickerItemView(_ itemView: EditorStickersItemView, didTapSticker item: EditorStickerItem)
    func stickerItemView(_ itemView: EditorStickersItemView, tapGestureRecognizerNotInScope point: CGPoint)
    func stickerItemView(_ itemView: EditorStickersItemView, panGestureRecognizerChanged panGR: UIPanGestureRecognizer)
    func stickerItemView(panGestureRecognizerEnded itemView: EditorStickersItemView) -> Bool
    func stickerItemView(moveToCenter itemView: EditorStickersItemView) -> Bool
    func stickerItemView(itemCenter itemView: EditorStickersItemView) -> CGPoint
    func stickerItemView(_ itemView: EditorStickersItemView, maxScale itemSize: CGSize) -> CGFloat
    func stickerItemView(_ itemView: EditorStickersItemView, minScale itemSize: CGSize) -> CGFloat
    func stickerItemView(didDeleteClick itemView: EditorStickersItemView)
    func stickerItemView(didDragScale itemView: EditorStickersItemView)
}
class EditorStickersItemView: EditorStickersItemBaseView {
    weak var delegate: EditorStickersItemViewDelegate?
    private var mirrorView: UIView!
    private var externalBorder: CALayer!
    
    var contentView: EditorStickersContentView!
    var deleteBtn: UIButton!
    var scaleBtn: UIImageView!
    
    var isEnabled: Bool = true {
        didSet {
            isUserInteractionEnabled = isEnabled
            contentView.isUserInteractionEnabled = isEnabled
        }
    }
    var isDelete: Bool = false
    var scale: CGFloat
    var touching: Bool = false
    
    override var isSelected: Bool {
        willSet {
            if !item.isAudio {
                let borderWidth: CGFloat = newValue ? 1 / scale : 0
                let borderRadius: CGFloat = newValue ? 1 / scale : 0
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                if externalBorder.borderWidth != borderWidth {
                    externalBorder.borderWidth = borderWidth
                }
                if externalBorder.cornerRadius != borderRadius {
                    externalBorder.cornerRadius = borderRadius
                }
                CATransaction.commit()
                deleteBtn.isHidden = !newValue
                scaleBtn.isHidden = !newValue
            }
            if isSelected == newValue {
                return
            }
            isUserInteractionEnabled = newValue
            if newValue {
                update(size: contentView.item.frame.size)
            }else {
                firstTouch = false
            }
        }
    }
    var didRemoveFromSuperview: ((EditorStickersItemView) -> Void)?
    var initialMirrorScale: CGPoint = .init(x: 1, y: 1)
    var editMirrorScale: CGPoint = .init(x: 1, y: 1)
    var radian: CGFloat = 0
    var pinchScale: CGFloat = 1
    var mirrorScale: CGPoint = .init(x: 1, y: 1)
    var firstTouch: Bool = false
    
    private var itemMargin: CGFloat = 20
    private var initialScale: CGFloat = 1
    private var initialPoint: CGPoint = .zero
    private var initialRadian: CGFloat = 0
    
    private var initialScalePoint: CGPoint = .zero
    private var scaleR: CGFloat = 1
    private var scaleA: CGFloat = 0
    
    private var lastTransform: CGAffineTransform = .identity
    private var lastMirrorTransform: CGAffineTransform = .identity
    private var lastScaleTransform: CGAffineTransform = .identity
    
    init(
        item: EditorStickerItem,
        scale: CGFloat
    ) {
        self.scale = scale
        let rect = CGRect(
            x: 0,
            y: 0,
            width: item.frame.width,
            height: item.frame.height
        )
        super.init(frame: rect)
        self.item = item
        initViews()
        mirrorView.frame = bounds
        addSubview(mirrorView)
        let margin = itemMargin / scale
        externalBorder.frame = CGRect(
            x: -margin * 0.5,
            y: -margin * 0.5,
            width: width + margin,
            height: height + margin
        )
        layer.addSublayer(externalBorder)
        contentView.scale = scale
        mirrorView.addSubview(contentView)
        if !item.isAudio {
            externalBorder.borderColor = UIColor.white.cgColor
            addSubview(deleteBtn)
            addSubview(scaleBtn)
        }
        deleteBtn.center = .init(x: externalBorder.frame.minX, y: externalBorder.frame.minY)
        scaleBtn.center = .init(x: externalBorder.frame.width, y: externalBorder.frame.height)
        initGestures()
    }
    
    private func initViews() {
        mirrorView = UIView()
        
        if item.isAudio {
            contentView = EditorStickersContentAudioView(item: item)
        }else {
            contentView = EditorStickersContentImageView(item: item)
        }
        contentView.center = center
        
        externalBorder = CALayer()
        externalBorder.shadowOpacity = 0.3
        externalBorder.shadowOffset = CGSize(width: 0, height: 0)
        externalBorder.shadowRadius = 1
        externalBorder.contentsScale = UIScreen._scale
        
        deleteBtn = UIButton(type: .custom)
        deleteBtn.setBackgroundImage(.imageResource.editor.sticker.delete.image, for: .normal)
        deleteBtn.addTarget(self, action: #selector(didDeleteButtonClick), for: .touchUpInside)
        deleteBtn.isHidden = true
        
        let image: UIImage?
        if !item.isAudio {
            image = .imageResource.editor.sticker.scale.image
        }else {
            image = .imageResource.editor.sticker.rotate.image
        }
        scaleBtn = UIImageView(image: image)
        scaleBtn.isUserInteractionEnabled = true
        scaleBtn.addGestureRecognizer(
            PhotoPanGestureRecognizer(
                target: self,
                action: #selector(dragScaleButtonClick(pan:))
            )
        )
        scaleBtn.isHidden = true
    }
    
    private func initGestures() {
        contentView.isUserInteractionEnabled = true
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(contentViewTapClick(tapGR:)))
        contentView.addGestureRecognizer(tapGR)
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(contentViewPanClick(panGR:)))
        contentView.addGestureRecognizer(panGR)
        if !item.isAudio {
            let pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(contentViewPinchClick(pinchGR:)))
            contentView.addGestureRecognizer(pinchGR)
        }
        let rotationGR = UIRotationGestureRecognizer(
            target: self,
            action: #selector(contentViewRotationClick(rotationGR:))
        )
        contentView.addGestureRecognizer(rotationGR)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview == nil {
            didRemoveFromSuperview?(self)
        }
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if bounds.contains(point) {
            return contentView
        }
        return view
    }
    
    @objc
    private func didDeleteButtonClick() {
        delegate?.stickerItemView(didDeleteClick: self)
    }
    
    @objc
    private func dragScaleButtonClick(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            touching = true
            firstTouch = true
            delegate?.stickerItemView(didDragScale: self)
            initialScalePoint = convert(scaleBtn.center, to: superview)
            let point = CGPoint(x: initialScalePoint.x - centerX, y: initialScalePoint.y - centerY)
            scaleR = sqrt(point.x * point.x + point.y * point.y)
            scaleA = atan2(point.y, point.x)
            
            initialScale = pinchScale
            initialRadian = radian
        case .changed:
            let point = pan.translation(in: superview)
            let p = CGPoint(x: initialScalePoint.x + point.x - centerX, y: initialScalePoint.y + point.y - centerY)
            let r = sqrt(p.x * p.x + p.y * p.y)
            let arg = atan2(p.y, p.x)
            if !item.isAudio {
                update(
                    pinchScale: initialScale * r / scaleR,
                    rotation: initialRadian + arg - scaleA,
                    isPinch: true,
                    isWindow: true
                )
            }else {
                update(
                    pinchScale: initialScale,
                    rotation: initialRadian + arg - scaleA,
                    isPinch: true,
                    isWindow: true
                )
            }
        case .ended, .cancelled, .failed:
            if !touching {
                return
            }
            touching = false
            firstTouch = false
            let moveToCenter = delegate?.stickerItemView(moveToCenter: self)
            let itemCenter = delegate?.stickerItemView(itemCenter: self)
            delegate?.stickerItemView(touchEnded: self)
            if let moveToCenter = moveToCenter,
                let itemCenter = itemCenter,
               moveToCenter {
                UIView.animate(withDuration: 0.25) {
                    self.center = itemCenter
                }
            }
        default:
            break
        }
    }
    @objc
    private func contentViewTapClick(tapGR: UITapGestureRecognizer) {
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
        if firstTouch && isSelected && item.isText && !touching {
            delegate?.stickerItemView(self, didTapSticker: item)
        }
        firstTouch = true
    }
    
    @objc
    private func contentViewPanClick(panGR: UIPanGestureRecognizer) {
        if isDelete {
            return
        }
        if let shouldTouch = delegate?.stickerItemView(shouldTouchBegan: self), !shouldTouch {
            return
        }
        switch panGR.state {
        case .began:
            touching = true
            firstTouch = true
            delegate?.stickerItemView(didTouchBegan: self)
            isSelected = true
            initialPoint = self.center
            deleteBtn.isHidden = true
            scaleBtn.isHidden = true
        case .changed:
            let point = panGR.translation(in: superview)
            center = CGPoint(x: initialPoint.x + point.x, y: initialPoint.y + point.y)
            delegate?.stickerItemView(self, panGestureRecognizerChanged: panGR)
        case .ended, .cancelled, .failed:
            if !touching {
                return
            }
            touching = false
            let moveToCenter = delegate?.stickerItemView(moveToCenter: self)
            let itemCenter = delegate?.stickerItemView(itemCenter: self)
            var isDelete = false
            if let panIsDelete = delegate?.stickerItemView(panGestureRecognizerEnded: self) {
                isDelete = panIsDelete
            }
            self.delegate?.stickerItemView(touchEnded: self)
            if let moveToCenter = moveToCenter,
                let itemCenter = itemCenter,
               moveToCenter,
               !isDelete {
                UIView.animate(withDuration: 0.25) {
                    self.center = itemCenter
                }
            }
            if isSelected {
                deleteBtn.isHidden = false
                scaleBtn.isHidden = false
            }
        default:
            break
        }
    }
    
    @objc
    private func contentViewPinchClick(pinchGR: UIPinchGestureRecognizer) {
        if isDelete {
            return
        }
        if let shouldTouch = delegate?.stickerItemView(shouldTouchBegan: self), !shouldTouch {
            return
        }
        switch pinchGR.state {
        case .began:
            if !item.isAudio {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                externalBorder.borderWidth = 0
                CATransaction.commit()
            }
            touching = true
            firstTouch = true
            delegate?.stickerItemView(didTouchBegan: self)
            isSelected = true
            initialScale = pinchScale
            deleteBtn.isHidden = true
            scaleBtn.isHidden = true
            update(pinchScale: initialScale * pinchGR.scale, isPinch: true, isWindow: true)
        case .changed:
            update(pinchScale: initialScale * pinchGR.scale, isPinch: true, isWindow: true)
        case .ended, .cancelled, .failed:
            touching = false
            if !item.isAudio {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                externalBorder.borderWidth = 1 / scale
                CATransaction.commit()
            }
            delegate?.stickerItemView(touchEnded: self)
            if isSelected {
                deleteBtn.isHidden = false
                scaleBtn.isHidden = false
            }
        default:
            break
        }
        if pinchGR.state == .began && pinchGR.state == .changed {
            pinchGR.scale = 1
        }
    }
    
    @objc
    private func contentViewRotationClick(rotationGR: UIRotationGestureRecognizer) {
        if isDelete {
            return
        }
        if let shouldTouch = delegate?.stickerItemView(shouldTouchBegan: self), !shouldTouch {
            return
        }
        switch rotationGR.state {
        case .began:
            firstTouch = true
            touching = true
            isSelected = true
            delegate?.stickerItemView(didTouchBegan: self)
            initialRadian = radian
            rotationGR.rotation = 0
            deleteBtn.isHidden = true
            scaleBtn.isHidden = true
        case .changed:
            radian = initialRadian + rotationGR.rotation
            update(pinchScale: pinchScale, rotation: radian, isWindow: true)
        case .ended, .cancelled, .failed:
            if !touching {
                return
            }
            touching = false
            delegate?.stickerItemView(touchEnded: self)
            rotationGR.rotation = 0
            if isSelected {
                deleteBtn.isHidden = false
                scaleBtn.isHidden = false
            }
        default:
            break
        }
    }
    
    func update(
        pinchScale: CGFloat,
        rotation: CGFloat? = nil,
        isInitialize: Bool = false,
        isPinch: Bool = false,
        isWindow: Bool = false
    ) {
        if let rotation = rotation {
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
        mirrorView.transform = .identity
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
        mirrorView.frame = bounds
        let borderFrame = CGRect(
            x: -margin * 0.5,
            y: -margin * 0.5,
            width: width + margin,
            height: height + margin
        )
        if !externalBorder.frame.equalTo(borderFrame) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            externalBorder.frame = borderFrame
            CATransaction.commit()
        }
        
        contentView.center = CGPoint(x: rect.width * 0.5, y: rect.height * 0.5)
        transform = transform.rotated(by: radian)
        if isWindow {
            mirrorView.transform = mirrorView.transform.scaledBy(x: initialMirrorScale.x, y: initialMirrorScale.y)
        }else {
            mirrorView.transform = mirrorView.transform.scaledBy(x: mirrorScale.x, y: mirrorScale.y)
        }
        
        if isSelected && !item.isAudio {
            let borderWidth: CGFloat = touching ? 1 : 1 / scale
            let borderRadius: CGFloat = touching ? 1 : 1 / scale
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if externalBorder.borderWidth != borderWidth {
                externalBorder.borderWidth = borderWidth
            }
            if externalBorder.cornerRadius != borderRadius {
                externalBorder.cornerRadius = borderRadius
            }
            CATransaction.commit()
        }
        if isWindow {
            deleteBtn.size = .init(width: 40, height: 40)
            scaleBtn.size = .init(width: 40, height: 40)
            deleteBtn.center = .init(x: -margin * 0.5, y: -margin * 0.5)
            scaleBtn.center = .init(x: bounds.width + margin * 0.5, y: bounds.height + margin * 0.5)
            scaleBtn.transform = .identity
        }else {
            deleteBtn.size = .init(width: 40 / scale, height: 40 / scale)
            scaleBtn.size = .init(width: 40 / scale, height: 40 / scale)
            let mirrorScale = CGPoint(
                x: self.mirrorScale.x * editMirrorScale.x,
                y: self.mirrorScale.y * editMirrorScale.y
            )
            if mirrorScale.x == -1 && mirrorScale.y == -1 {
                scaleBtn.center = .init(x: -margin * 0.5, y: -margin * 0.5)
                deleteBtn.center = .init(x: bounds.width + margin * 0.5, y: bounds.height + margin * 0.5)
                scaleBtn.transform = .identity
            }else if mirrorScale.x == -1 {
                deleteBtn.center = .init(x: bounds.width + margin * 0.5, y: -margin * 0.5)
                scaleBtn.center = .init(x: -margin * 0.5, y: bounds.height + margin * 0.5)
                scaleBtn.transform = .init(scaleX: -1, y: 1)
            }else if mirrorScale.y == -1 {
                deleteBtn.center = .init(x: -margin * 0.5, y: bounds.height + margin * 0.5)
                scaleBtn.center = .init(x: bounds.width + margin * 0.5, y: -margin * 0.5)
                scaleBtn.transform = .init(scaleX: 1, y: -1)
            }else {
                deleteBtn.center = .init(x: -margin * 0.5, y: -margin * 0.5)
                scaleBtn.center = .init(x: bounds.width + margin * 0.5, y: bounds.height + margin * 0.5)
                scaleBtn.transform = .identity
            }
        }

    }
    
    func update(item: EditorStickerItem) {
        self.item = item
        contentView.update(item: item)
        update(size: item.frame.size)
    }
    
    func update(text: EditorStickerText) {
        if !item.isText {
            return
        }
        item.type = .text(text)
        if let width = superview?.width {
            item.frame = item.itemFrame(width)
        }
        contentView.update(item: item)
        update(size: item.frame.size)
    }
    
    func update(size: CGSize, isWindow: Bool = false) {
        let center = self.center
        var frame = frame
        frame.size = CGSize(width: size.width, height: size.height)
        self.frame = frame
        mirrorView.frame = bounds
        self.center = center
        let margin = itemMargin / scale
        let borderFrame = CGRect(
            x: -margin * 0.5,
            y: -margin * 0.5,
            width: width + margin,
            height: height + margin
        )
        if !externalBorder.frame.equalTo(borderFrame) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            externalBorder.frame = borderFrame
            CATransaction.commit()
        }
        contentView.transform = .identity
        transform = .identity
        mirrorView.transform = .identity
        
        contentView.size = size
        contentView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        update(
            pinchScale: pinchScale,
            rotation: radian,
            isWindow: isWindow
        )
    }
    func resetRotaion(isWindow: Bool = false) {
        update(
            pinchScale: pinchScale,
            rotation: radian,
            isWindow: isWindow
        )
    }
    
    func videoReset(_ isReset: Bool) {
        var currentTransform: CGAffineTransform = .identity
        var currentMirrorTransform: CGAffineTransform = .identity
        var currentScaleTransform: CGAffineTransform = .identity
        if isReset {
            currentTransform = lastTransform
            currentMirrorTransform = lastMirrorTransform
            currentScaleTransform = lastScaleTransform
        }else {
            lastTransform = transform
            lastMirrorTransform = mirrorView.transform
            lastScaleTransform = contentView.transform
        }
        
        transform = .identity
        mirrorView.transform = .identity
        contentView.transform = currentScaleTransform
        var rect = frame
        rect.origin.x += (rect.width - contentView.width) / 2
        rect.origin.y += (rect.height - contentView.height) / 2
        rect.size.width = contentView.width
        rect.size.height = contentView.height
        frame = rect
        mirrorView.frame = bounds
        contentView.center = CGPoint(x: rect.width * 0.5, y: rect.height * 0.5)
        transform = currentTransform
        mirrorView.transform = currentMirrorTransform
    }
    
    func videoResetAudio(_ isReset: Bool) {
        var currentTransform: CGAffineTransform = .identity
        var currentMirrorTransform: CGAffineTransform = .identity
        if isReset {
            currentTransform = lastTransform
            currentMirrorTransform = lastMirrorTransform
        }else {
            lastTransform = transform
            lastMirrorTransform = mirrorView.transform
        }
        transform = currentTransform
        mirrorView.transform = currentMirrorTransform
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
