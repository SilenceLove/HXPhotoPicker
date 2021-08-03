//
//  EditorStickerView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/20.
//

import UIKit

protocol EditorStickerViewDelegate: AnyObject {
    func stickerView(touchBegan stickerView: EditorStickerView)
    func stickerView(touchEnded stickerView: EditorStickerView)
    func stickerView(_ stickerView: EditorStickerView, moveToCenter rect: CGRect) -> Bool
    func stickerView(_ stickerView: EditorStickerView, minScale itemSize: CGSize) -> CGFloat
    func stickerView(_ stickerView: EditorStickerView, maxScale itemSize: CGSize) -> CGFloat
    func stickerView(_ stickerView: EditorStickerView, updateStickerText item: EditorStickerItem)
}

class EditorStickerView: UIView {
    weak var delegate: EditorStickerViewDelegate?
    var scale: CGFloat = 1 {
        didSet {
            for subView in subviews {
                if let itemView = subView as? EditorStickerItemView {
                    itemView.scale = scale
                }
            }
        }
    }
    var touching: Bool = false
    var enabled: Bool {
        get {
            isUserInteractionEnabled
        }
        set {
            if !newValue {
                deselectedSticker()
            }
            isUserInteractionEnabled = newValue
        }
    }
    var count: Int {
        subviews.count
    }
    
    var selectView: EditorStickerItemView? {
        willSet {
            if let selectView = selectView,
               let selectSuperView = selectView.superview,
               selectSuperView == UIApplication.shared.keyWindow {
                readdItemView(itemView: selectView)
            }
        }
    }
    lazy var trashView: EditorStickerTrashView = {
        let view = EditorStickerTrashView(frame: CGRect(x: 0, y: 0, width: 180, height: 80))
        view.centerX = UIScreen.main.bounds.width * 0.5
        view.y = UIScreen.main.bounds.height
        view.alpha = 0
        return view
    }()
    var trashViewDidRemove: Bool = false
    var trashViewIsVisible: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        isUserInteractionEnabled = true
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if touching {
            return view
        }
        if let view = view, view is EditorStickerContentView {
            if let selectView = selectView {
                var rect = selectView.frame
                rect = CGRect(x: rect.minX - 35, y: rect.minY - 35, width: rect.width + 70, height: rect.height + 70)
                if rect.contains(point) {
                    return selectView.contentView
                }
            }
            if let itemView = view.superview as? EditorStickerItemView {
                if itemView != selectView {
                    deselectedSticker()
                }
                itemView.isSelected = true
                bringSubviewToFront(itemView)
                itemView.resetRotaion()
                selectView = itemView
            }
        }else {
            if let selectView = selectView {
                var rect = selectView.frame
                rect = CGRect(x: rect.minX - 35, y: rect.minY - 35, width: rect.width + 70, height: rect.height + 70)
                if rect.contains(point) {
                    return selectView.contentView
                }
            }
            deselectedSticker()
        }
        return view
    }
    
    func update(item: EditorStickerItem) {
        selectView?.update(item: item)
    }
    
    var beforeItemArg: CGFloat = 0
    var currentItemArg: CGFloat = 0
    var addWindowCompletion: Bool = false
    var angle: CGFloat = 0
    var currentItemDegrees: CGFloat = 0
    var hasImpactFeedback: Bool = false
    var mirrorType: EditorImageResizerView.MirrorType = .none {
        willSet {
            for subView in subviews {
                if let itemView = subView as? EditorStickerItemView {
                    if newValue == .none {
                        if mirrorType == .horizontal {
                            if itemView.mirrorType == .none {
                                itemView.mirrorType = .horizontal
                            }else {
                                itemView.mirrorType = .none
                            }
                        }
                    }else {
                        if mirrorType == .none {
                            if itemView.mirrorType == .none {
                                itemView.mirrorType = .horizontal
                            }else {
                                itemView.mirrorType = .none
                            }
                        }
                    }
                    itemView.superMirrorType = newValue
                    itemView.superAngle = angle
                }
            }
        }
    }
    
    @discardableResult
    func add(sticker item: EditorStickerItem, isSelected: Bool) -> EditorStickerItemView {
        selectView?.isSelected = false
        let itemView = EditorStickerItemView.init(item: item, scale: scale)
        itemView.delegate = self
        var pScale: CGFloat
        if item.text == nil {
            let ratio: CGFloat = 0.5
            var width = self.width * self.scale
            var height = self.height * self.scale
            if width > UIScreen.main.bounds.width {
                width = UIScreen.main.bounds.width
            }
            if height > UIScreen.main.bounds.height {
                height = UIScreen.main.bounds.height
            }
            pScale = min(ratio * width / itemView.width, ratio * height / itemView.height)
        }else {
            pScale = min(min(self.width * self.scale - 40, itemView.width) / itemView.width, min(self.height * self.scale - 40, itemView.height) / itemView.height)
        }
        itemView.superAngle = angle
        itemView.superMirrorType = mirrorType
        var radians = angleRadians()
        if mirrorType == .none {
            radians = -radians
        }else {
            if angle.truncatingRemainder(dividingBy: 180) == 0 {
                radians = -radians
            }
        }
        itemView.isSelected = isSelected
        if let keyWindow = UIApplication.shared.keyWindow {
            itemView.center = convert(keyWindow.center, from: keyWindow)
        }
        itemView.firstTouch = isSelected
        addSubview(itemView)
        itemView.update(pinchScale: pScale / self.scale, rotation: radians, isMirror: true)
        if isSelected {
            selectView = itemView
        }
        return itemView
    }
    func deselectedSticker() {
        selectView?.isSelected = false
        selectView = nil
    }
    func removeAllSticker() {
        deselectedSticker()
        for subView in subviews {
            if let itemView = subView as? EditorStickerItemView {
                itemView.removeFromSuperview()
            }
        }
    }
    func resetItemView(itemView: EditorStickerItemView) {
        if addWindowCompletion {
            addWindowCompletion = false
            readdItemView(itemView: itemView)
        }
    }
    func readdItemView(itemView: EditorStickerItemView) {
        let arg = itemView.radian - currentItemArg
        if let rect = UIApplication.shared.keyWindow?.convert(itemView.frame, to: self) {
            itemView.frame = rect
        }
        addSubview(itemView)
        if mirrorType == .none {
            itemView.update(pinchScale: itemView.pinchScale, rotation: itemView.radian - currentItemDegrees, isMirror: true)
        }else {
            itemView.update(pinchScale: itemView.pinchScale, rotation: beforeItemArg + arg, isMirror: true)
        }
    }
    
    func windowAdd(itemView : EditorStickerItemView) {
        beforeItemArg = itemView.radian
        addWindowCompletion = true
        let radians = angleRadians()
        currentItemDegrees = radians
        let rect = convert(itemView.frame, to: UIApplication.shared.keyWindow)
        itemView.frame = rect
        UIApplication.shared.keyWindow?.addSubview(itemView)
        if mirrorType == .none {
            itemView.update(pinchScale: itemView.pinchScale, rotation: itemView.radian + radians, isMirror: true)
        }else {
            if itemView.mirrorType == .horizontal {
                itemView.update(pinchScale: itemView.pinchScale, rotation: itemView.radian + radians, isMirror: true)
            }else {
                if angle.truncatingRemainder(dividingBy: 180) != 0 {
                    itemView.update(pinchScale: itemView.pinchScale, rotation: itemView.radian + radians, isMirror: true)
                }else {
                    itemView.update(pinchScale: itemView.pinchScale, rotation: itemView.radian - radians, isMirror: true)
                }
            }
        }
        currentItemArg = itemView.radian
    }
    
    func mirrorTransForm(radians: CGFloat) -> CGAffineTransform {
        let transfrom = CGAffineTransform(scaleX: -1, y: 1)
        switch radians {
        case 0:
            return transfrom
        case CGFloat.pi / 2, -CGFloat.pi / 2:
            return transfrom.rotated(by: CGFloat.pi / 2)
        case CGFloat.pi, -CGFloat.pi:
            return transfrom.rotated(by: CGFloat.pi)
        case CGFloat.pi / 2 * 3, -CGFloat.pi / 2 * 3:
            return transfrom.rotated(by: -CGFloat.pi / 2)
        default:
            return transfrom
        }
    }
    
    func angleRadians() -> CGFloat {
        switch angle {
        case 90:
            return CGFloat.pi / 2
        case -90:
            return -CGFloat.pi / 2
        case 180:
            return CGFloat.pi
        case -180:
            return -CGFloat.pi
        case 270:
            return CGFloat.pi / 2 * 3
        case -270:
            return -CGFloat.pi / 2 * 3
        default:
            return 0
        }
    }
    
    func showTrashView() {
        trashViewDidRemove = false
        trashViewIsVisible = true
        UIView.animate(withDuration: 0.25) {
            self.trashView.y = UIScreen.main.bounds.height - UIDevice.bottomMargin - 20 - self.trashView.height
            self.trashView.alpha = 1
        } completion: { _ in
            if !self.trashViewIsVisible {
                self.trashView.y = UIScreen.main.bounds.height
                self.trashView.alpha = 0
            }
        }
    }
    
    @objc func hideTrashView() {
        trashViewIsVisible = false
        trashViewDidRemove = true
        UIView.animate(withDuration: 0.25) {
            self.trashView.y = UIScreen.main.bounds.height
            self.trashView.alpha = 0
            self.selectView?.alpha = 1
        } completion: { _ in
            if !self.trashViewIsVisible {
                self.trashView.removeFromSuperview()
                self.trashView.inArea = false
            }else {
                self.trashView.y = UIScreen.main.bounds.height - UIDevice.bottomMargin - 20 - self.trashView.height
                self.trashView.alpha = 1
            }
        }

    }
    
    func stickerData() -> EditorStickerData? {
        var datas: [EditorStickerItemData] = []
        for subView in subviews {
            if let itemView = subView as? EditorStickerItemView {
                let centerScale = CGPoint(x: itemView.centerX / width, y: itemView.centerY / height)
                let itemData = EditorStickerItemData(item: itemView.item, pinchScale: itemView.pinchScale, rotation: itemView.radian, centerScale: centerScale, mirrorType: itemView.mirrorType, superMirrorType: itemView.superMirrorType, superAngel: itemView.superAngle)
                datas.append(itemData)
            }
        }
        if datas.isEmpty {
            return nil
        }
        let stickerData = EditorStickerData(items: datas, mirrorType: mirrorType, angel: angle)
        return stickerData
    }
    func setStickerData(stickerData: EditorStickerData, viewSize: CGSize) {
        mirrorType = stickerData.mirrorType
        angle = stickerData.angel
        for itemData in stickerData.items {
            let itemView = add(sticker: itemData.item, isSelected: false)
            itemView.mirrorType = itemData.mirrorType
            itemView.superMirrorType = itemData.superMirrorType
            itemView.superAngle = itemData.superAngel
            itemView.update(pinchScale: itemData.pinchScale, rotation: itemData.rotation, isInitialize: true, isMirror: true)
            itemView.center = CGPoint(x: viewSize.width * itemData.centerScale.x, y: viewSize.height * itemData.centerScale.y)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorStickerView: EditorStickerItemViewDelegate {
    func stickerItemView(_ itemView: EditorStickerItemView, updateStickerText item: EditorStickerItem) {
        delegate?.stickerView(self, updateStickerText: item)
    }
    
    func stickerItemView(shouldTouchBegan itemView: EditorStickerItemView) -> Bool {
        if let selectView = selectView, itemView != selectView {
            return false
        }
        return true
    }
    
    func stickerItemView(didTouchBegan itemView: EditorStickerItemView) {
        touching = true
        delegate?.stickerView(touchBegan: self)
        if let selectView = selectView, selectView != itemView {
            selectView.isSelected = false
            self.selectView = itemView
        }else if selectView == nil {
            selectView = itemView
        }
        if !addWindowCompletion {
            windowAdd(itemView: itemView)
        }
        if !trashViewIsVisible {
            UIApplication.shared.keyWindow?.addSubview(trashView)
            showTrashView()
        }
    }
    
    func stickerItemView(touchEnded itemView: EditorStickerItemView) {
        delegate?.stickerView(touchEnded: self)
        if let selectView = selectView, selectView != itemView {
            selectView.isSelected = false
            self.selectView = itemView
        }else if selectView == nil {
            selectView = itemView
        }
        resetItemView(itemView: itemView)
        if trashViewIsVisible {
            hideTrashView()
        }
        touching = false
    }
    func stickerItemView(_ itemView: EditorStickerItemView, tapGestureRecognizerNotInScope point: CGPoint) {
        if let selectView = selectView, itemView == selectView {
            self.selectView = nil
            let cPoint = itemView.convert(point, to: self)
            for subView in subviews {
                if let itemView = subView as? EditorStickerItemView {
                    if itemView.frame.contains(cPoint) {
                        itemView.isSelected = true
                        self.selectView = itemView
                        bringSubviewToFront(itemView)
                        itemView.resetRotaion()
                        return
                    }
                }
            }
        }
    }
    
    func stickerItemView(_ itemView: EditorStickerItemView, panGestureRecognizerChanged panGR: UIPanGestureRecognizer) {
        let point = panGR.location(in: UIApplication.shared.keyWindow)
        if trashView.frame.contains(point) && !trashViewDidRemove {
            trashView.inArea = true
            if !hasImpactFeedback {
                UIView.animate(withDuration: 0.25) {
                    self.selectView?.alpha = 0.4
                }
                perform(#selector(hideTrashView), with: nil, afterDelay: 1.2)
                let shake = UIImpactFeedbackGenerator(style: .medium)
                shake.prepare()
                shake.impactOccurred()
                hasImpactFeedback = true
            }
        }else {
            UIView.animate(withDuration: 0.2) {
                self.selectView?.alpha = 1
            }
            UIView.cancelPreviousPerformRequests(withTarget: self)
            hasImpactFeedback = false
            trashView.inArea = false
        }
    }
    func stickerItemView(_ itemView: EditorStickerItemView, moveToCenter rect: CGRect) -> Bool {
        if let moveToCenter = delegate?.stickerView(self, moveToCenter: rect) {
            return moveToCenter
        }
        return false
    }
    func stickerItemView(panGestureRecognizerEnded itemView: EditorStickerItemView) -> Bool {
        let inArea = trashView.inArea
        if inArea {
            addWindowCompletion = false
            trashView.inArea = false
            UIView.animate(withDuration: 0.25) {
                itemView.alpha = 0
            } completion: { _ in
                itemView.removeFromSuperview()
            }
            selectView = nil
        }else {
            if let selectView = selectView, selectView != itemView {
                selectView.isSelected = false
                self.selectView = itemView
            }else if selectView == nil {
                selectView = itemView
            }
            resetItemView(itemView: itemView)
        }
        if addWindowCompletion {
            hideTrashView()
        }
        return inArea
    }
    func stickerItemView(_ itemView: EditorStickerItemView, maxScale itemSize: CGSize) -> CGFloat {
        if let maxScale = delegate?.stickerView(self, maxScale: itemSize) {
            return maxScale
        }
        return 5
    }
    
    func stickerItemView(_ itemView: EditorStickerItemView, minScale itemSize: CGSize) -> CGFloat {
        if let minScale = delegate?.stickerView(self, minScale: itemSize) {
            return minScale
        }
        return 0.2
    }
}

struct EditorStickerData: Codable {
    let items: [EditorStickerItemData]
    let mirrorType: EditorImageResizerView.MirrorType
    let angel: CGFloat
}

struct EditorStickerItemData: Codable {
    let item: EditorStickerItem
    let pinchScale: CGFloat
    let rotation: CGFloat
    let centerScale: CGPoint
    let mirrorType: EditorImageResizerView.MirrorType
    let superMirrorType: EditorImageResizerView.MirrorType
    let superAngel: CGFloat
}
