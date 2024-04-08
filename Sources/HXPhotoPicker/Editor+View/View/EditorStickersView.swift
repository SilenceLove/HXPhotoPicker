//
//  EditorStickersView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/1/20.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

protocol EditorStickersViewDelegate: AnyObject {
    func stickerView(touchBegan stickerView: EditorStickersView)
    func stickerView(touchEnded stickerView: EditorStickersView)
    func stickerView(_ stickerView: EditorStickersView, moveToCenter itemView: EditorStickersItemView) -> Bool
    func stickerView(_ stickerView: EditorStickersView, minScale itemSize: CGSize) -> CGFloat
    func stickerView(_ stickerView: EditorStickersView, maxScale itemSize: CGSize) -> CGFloat
    func stickerView(_ stickerView: EditorStickersView, didTapStickerItem itemView: EditorStickersItemView)
    func stickerView(_ stickerView: EditorStickersView, shouldRemoveItem itemView: EditorStickersItemView)
    func stickerView(_ stickerView: EditorStickersView, didRemoveItem itemView: EditorStickersItemView)
    
    func stickerView(_ stickerView: EditorStickersView, shouldAddAudioItem audio: EditorStickerAudio) -> Bool
    
    func stickerView(itemCenter stickerView: EditorStickersView) -> CGPoint?
    func stickerView(_ stickerView: EditorStickersView, resetItemViews itemViews: [EditorStickersItemBaseView])
    
    func stickerView(rotateVideo stickerView: EditorStickersView)
    func stickerView(resetVideoRotate stickerView: EditorStickersView)
}

class EditorStickersView: UIView, EditorStickersItemViewDelegate {
    weak var delegate: EditorStickersViewDelegate?
    var scale: CGFloat = 1 {
        didSet {
            for subView in subviews {
                if let itemView = subView as? EditorStickersItemView {
                    itemView.scale = scale
                }
            }
        }
    }
    var isTouching: Bool = false
    var isEnabled: Bool {
        get { isUserInteractionEnabled }
        set {
            if !newValue { deselectedSticker() }
            isUserInteractionEnabled = newValue
        }
    }
    var count: Int { subviews.count }
    var selectView: EditorStickersItemView? {
        willSet {
            if let selectView = selectView,
               let selectSuperView = selectView.superview,
               selectSuperView == UIApplication._keyWindow {
                endDragging(selectView)
            }
        }
    }
    var isVideoMark: Bool = false
    var mirrorScale: CGPoint = .init(x: 1, y: 1) {
        didSet {
            for subView in subviews {
                if let itemView = subView as? EditorStickersItemView {
                    itemView.initialMirrorScale = itemView.editMirrorScale
                }
            }
        }
    }
    var isShowTrash: Bool = true
    var angle: CGFloat = 0
    
    private var trashView: EditorStickersTrashView!
    private var trashViewDidRemove: Bool = false
    private var trashViewIsVisible: Bool = false
    private var isDragging: Bool = false
    private var beforeItemArg: CGFloat = 0
    private var currentItemArg: CGFloat = 0
    private var currentItemDegrees: CGFloat = 0
    private var hasImpactFeedback: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        clipsToBounds = true
        isUserInteractionEnabled = true
    }
    private func initViews() {
        trashView = EditorStickersTrashView(frame: CGRect(x: 0, y: 0, width: 180, height: 80))
        trashView.centerX = UIDevice.screenSize.width * 0.5
        trashView.y = UIDevice.screenSize.height
        trashView.alpha = 0
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !isEnabled {
            return nil
        }
        let view = super.hitTest(point, with: event)
        if isTouching {
            return view
        }
        if let view = view, view is EditorStickersContentView {
            if let selectView = selectView {
                let rect = selectView.frame
                if rect.contains(point) {
                    selectView.isSelected = true
                    return selectView.contentView
                }
                let deleteRect = selectView.convert(selectView.deleteBtn.frame, to: self)
                if deleteRect.contains(point) {
                    return selectView.deleteBtn
                }
                let scaleRect = selectView.convert(selectView.scaleBtn.frame, to: self)
                if scaleRect.contains(point) {
                    return selectView.scaleBtn
                }
            }
            if let itemView = view.superview?.superview as? EditorStickersItemView,
               !itemView.isDelete {
                if itemView != selectView {
                    deselectedSticker()
                    itemView.isSelected = true
                    bringSubviewToFront(itemView)
                    itemView.resetRotaion()
                    selectView = itemView
                }
            }
        }else {
            if let selectView = selectView {
                let rect = selectView.frame
                if rect.contains(point) {
                    return selectView.contentView
                }
                let deleteRect = selectView.convert(selectView.deleteBtn.frame, to: self)
                if deleteRect.contains(point) {
                    return selectView.deleteBtn
                }
                let scaleRect = selectView.convert(selectView.scaleBtn.frame, to: self)
                if scaleRect.contains(point) {
                    return selectView.scaleBtn
                }
                deselectedSticker()
            }else {
                let lastView = subviews.filter {
                    let rect = $0.frame
                    return rect.contains(point)
                }.last
                if let lastView = lastView as? EditorStickersItemView {
                    if lastView != selectView {
                        deselectedSticker()
                        lastView.isSelected = true
                        bringSubviewToFront(lastView)
                        lastView.resetRotaion()
                        selectView = lastView
                    }
                }else {
                    deselectedSticker()
                }
            }
        }
        return view
    }
    
    func getStickerItem() -> Item? {
        var datas: [Item.Info] = []
        for case let itemView as EditorStickersItemView in subviews {
            let centerScale = CGPoint(x: itemView.centerX / width, y: itemView.centerY / height)
            let itemData = Item.Info(
                item: itemView.item,
                pinchScale: itemView.pinchScale,
                rotation: itemView.radian,
                centerScale: centerScale,
                mirrorScale: itemView.mirrorScale,
                editMirrorScale: itemView.editMirrorScale,
                initialMirrorScale: itemView.initialMirrorScale
            )
            datas.append(itemData)
        }
        let stickerData = Item(
            items: datas,
            mirrorScale: mirrorScale,
            angel: angle
        )
        return stickerData
    }
    func setStickerItem(_ item: Item?, viewSize: CGSize) {
        guard let item = item else {
            return
        }
        angle = item.angel
        mirrorScale = item.mirrorScale
        var itemViews: [EditorStickersItemBaseView] = []
        for itemData in item.items {
            if let audio = itemData.item.audio,
               let isShould = delegate?.stickerView(self, shouldAddAudioItem: audio),
               !isShould {
                continue
            }
            let itemView = add(sticker: itemData.item, isSelected: false, viewWidth: viewSize.width)
            itemView.mirrorScale = itemData.mirrorScale
            itemView.editMirrorScale = itemData.editMirrorScale
            itemView.initialMirrorScale = itemData.initialMirrorScale
            itemView.update(
                pinchScale: itemData.pinchScale,
                rotation: itemData.rotation,
                isInitialize: true,
                isPinch: true
            )
            itemView.center = CGPoint(
                x: viewSize.width * itemData.centerScale.x,
                y: viewSize.height * itemData.centerScale.y
            )
            itemViews.append(itemView)
        }
        if itemViews.isEmpty {
            return
        }
        delegate?.stickerView(self, resetItemViews: itemViews)
    }
    func getStickerInfo() -> [Info] {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        delegate?.stickerView(rotateVideo: self)
        var infos: [Info] = []
        for case let itemView as EditorStickersItemView in subviews {
            let image: UIImage?
            if let imageData = itemView.item.imageData {
                #if canImport(Kingfisher)
                image = DefaultImageProcessor.default.process(
                    item: .data(imageData),
                    options: .init([])
                )!
                #else
                image = UIImage(data: imageData)
                #endif
            }else {
                image = itemView.item.image
            }
            
            var audioInfo: AudioInfo?
            if let audio = itemView.item.audio {
                audioInfo = .init(
                    fontSizeScale: 25.0 / width,
                    animationSizeScale: CGSize(
                        width: 20 / width,
                        height: 15 / height
                    ),
                    audio: audio
                )
            }
            let infoScale = itemView.pinchScale
            itemView.videoReset(false)
            let frameScale: Info.FrameScale = .init(
                center: .init(
                    x: itemView.centerX / width,
                    y: itemView.centerY / height
                ),
                size: .init(
                    width: itemView.width / width,
                    height: itemView.height / height
                )
            )
            itemView.videoReset(true)
            let info = Info(
                image: image,
                isText: itemView.item.isText,
                frameScale: frameScale,
                angel: itemView.radian.angle,
                mirrorScale: itemView.mirrorScale,
                scale: infoScale,
                viewSize: size,
                audio: audioInfo
            )
            infos.append(info)
        }
        delegate?.stickerView(resetVideoRotate: self)
        CATransaction.commit()
        return infos
    }
    
    @discardableResult
    func add(
        sticker item: EditorStickerItem,
        isSelected: Bool,
        viewWidth: CGFloat = 0
    ) -> EditorStickersItemView {
        isVideoMark = false
        selectView?.isSelected = false
        var item = item
        if viewWidth > 0 {
            item.frame = item.itemFrame(viewWidth)
        }else {
            item.frame = item.itemFrame(width)
        }
        let itemView = EditorStickersItemView(
            item: item,
            scale: scale
        )
        itemView.delegate = self
        var pScale: CGFloat
        if !item.isText && !item.isAudio {
            let ratio: CGFloat = 0.5
            var width = self.width * self.scale
            var height = self.height * self.scale
            if width > UIDevice.screenSize.width {
                width = UIDevice.screenSize.width
            }
            if height > UIDevice.screenSize.height {
                height = UIDevice.screenSize.height
            }
            pScale = min(ratio * width / itemView.width, ratio * height / itemView.height)
        }else if item.isText {
            pScale = min(
                min(
                    self.width * self.scale - 40,
                    itemView.width
                ) / itemView.width,
                min(
                    self.height * self.scale - 40,
                    itemView.height
                ) / itemView.height
            )
        }else {
            pScale = 1
        }
        itemView.mirrorScale = mirrorScale
        let radians = -angle.radians
        itemView.isSelected = isSelected
        if let center = delegate?.stickerView(itemCenter: self) {
            itemView.center = center
        }else {
            if let keyWindow = UIApplication._keyWindow {
                itemView.center = convert(keyWindow.center, from: keyWindow)
            }
        }
        itemView.firstTouch = isSelected
        addSubview(itemView)
        itemView.update(pinchScale: pScale / self.scale, rotation: radians)
        if isSelected {
            selectView = itemView
        }
        itemView.didRemoveFromSuperview = { [weak self] in
            if self?.selectView == $0 {
                self?.deselectedSticker()
            }
        }
        return itemView
    }
    func deselectedSticker() {
        if selectView != nil {
            isVideoMark = false
            selectView?.isSelected = false
            selectView = nil
        }
    }
    
    func removeSticker(at itemView: EditorStickersItemBaseView) {
        for case let subView as EditorStickersItemView in subviews where subView == itemView {
            if subView == selectView {
                deselectedSticker()
            }
            subView.removeFromSuperview()
            break
        }
    }
    
    func removeAllSticker() {
        deselectedSticker()
        for case let subView as EditorStickersItemView in subviews {
            subView.removeFromSuperview()
        }
    }
    func resetItemView(itemView: EditorStickersItemView) {
        isVideoMark = false
        if isDragging {
            endDragging(itemView)
        }
    }
    
    func update(item: EditorStickerItem) {
        isVideoMark = false
        selectView?.update(item: item)
    }
    
    func update(text: EditorStickerText) {
        isVideoMark = false
        selectView?.update(text: text)
    }
    
    func startDragging(_ itemView: EditorStickersItemView) {
        isVideoMark = false
        isDragging = true
        beforeItemArg = itemView.radian
        let radians = angle.radians
        currentItemDegrees = radians
        if itemView.superview != UIApplication._keyWindow {
            let rect = convert(itemView.frame, to: UIApplication._keyWindow)
            itemView.frame = rect
            UIApplication._keyWindow?.addSubview(itemView)
        }
        let rotation: CGFloat
        if itemView.mirrorScale.x * itemView.mirrorScale.y == 1 {
            if itemView.initialMirrorScale.x * itemView.initialMirrorScale.y == 1 {
                rotation = itemView.radian + radians
            }else {
                rotation = -itemView.radian - radians
            }
        }else {
            if itemView.initialMirrorScale.x * itemView.initialMirrorScale.y == 1 {
                rotation = -itemView.radian - radians
            }else {
                rotation = itemView.radian + radians
            }
        }
        itemView.update(
            pinchScale: itemView.pinchScale,
            rotation: rotation,
            isWindow: true
        )
        currentItemArg = itemView.radian
    }
    
    func endDragging(_ itemView: EditorStickersItemView) {
        isVideoMark = false
        isDragging = false
        guard let superview = itemView.superview,
              superview != self else {
            return
        }
        let arg = itemView.radian - currentItemArg
        if superview == UIApplication._keyWindow {
            let rect = superview.convert(itemView.frame, to: self)
            itemView.frame = rect
        }
        addSubview(itemView)
        let rotation: CGFloat
        if itemView.mirrorScale.x * itemView.mirrorScale.y == 1 {
            if itemView.initialMirrorScale.x * itemView.initialMirrorScale.y == 1 {
                rotation = itemView.radian - currentItemDegrees
            }else {
                rotation = -itemView.radian - currentItemDegrees
            }
        }else {
            if itemView.initialMirrorScale.x * itemView.initialMirrorScale.y == 1 {
                rotation = beforeItemArg - arg
            }else {
                rotation = beforeItemArg + arg
            }
        }
        itemView.update(
            pinchScale: itemView.pinchScale,
            rotation: rotation
        )
    }
    
    func mirrorVerticallyHandler() {
        mirrorHandler(.init(x: -1, y: 1))
    }
    func mirrorHorizontallyHandler() {
        mirrorHandler(.init(x: 1, y: -1))
    }
    func mirrorHandler(_ scale: CGPoint) {
        isVideoMark = false
        for subView in subviews {
            if let itemView = subView as? EditorStickersItemView {
                let transform = CGAffineTransform(
                    scaleX: itemView.editMirrorScale.x,
                    y: itemView.editMirrorScale.y
                ).scaledBy(x: scale.x, y: scale.y)
                itemView.editMirrorScale = .init(x: transform.a, y: transform.d)
            }
        }
    }
    func initialMirror(_ scale: CGPoint) {
        for subView in subviews {
            if let itemView = subView as? EditorStickersItemView {
                let transform = CGAffineTransform(
                    scaleX: itemView.editMirrorScale.x,
                    y: itemView.editMirrorScale.y
                ).scaledBy(x: scale.x, y: scale.y)
                itemView.editMirrorScale = .init(x: transform.a, y: transform.d)
            }
        }
    }
    func resetMirror() {
        isVideoMark = false
        for subView in subviews {
            if let itemView = subView as? EditorStickersItemView {
                itemView.editMirrorScale = itemView.initialMirrorScale
            }
        }
    }
    
    func showTrashView() {
        trashViewDidRemove = false
        trashViewIsVisible = true
        let viewSize = UIDevice.screenSize
        UIView.animate(withDuration: 0.25) {
            self.trashView.centerX = viewSize.width * 0.5
            self.trashView.y = viewSize.height - UIDevice.bottomMargin - 20 - self.trashView.height
            self.trashView.alpha = 1
        } completion: { _ in
            if !self.trashViewIsVisible {
                self.trashView.y = viewSize.height
                self.trashView.alpha = 0
            }
        }
    }
    
    @objc
    func hideTrashView() {
        if !trashViewIsVisible {
            return
        }
        trashViewIsVisible = false
        trashViewDidRemove = true
        let viewSize = UIDevice.screenSize
        UIView.animate(withDuration: 0.25) {
            self.trashView.centerX = viewSize.width * 0.5
            self.trashView.y = viewSize.height
            self.trashView.alpha = 0
            self.selectView?.alpha = 1
        } completion: { _ in
            if !self.trashViewIsVisible {
                self.trashView.removeFromSuperview()
                self.trashView.inArea = false
            }else {
                self.trashView.y = viewSize.height - UIDevice.bottomMargin - 20 - self.trashView.height
                self.trashView.alpha = 1
            }
        }
    }
    
    func stickerItemView(
        _ itemView: EditorStickersItemView,
        didTapSticker item: EditorStickerItem
    ) {
        delegate?.stickerView(self, didTapStickerItem: itemView)
    }
    
    func stickerItemView(shouldTouchBegan itemView: EditorStickersItemView) -> Bool {
        if let selectView = selectView, itemView != selectView {
            return false
        }
        return true
    }
    
    func stickerItemView(didTouchBegan itemView: EditorStickersItemView) {
        isTouching = true
        delegate?.stickerView(touchBegan: self)
        if let selectView = selectView, selectView != itemView {
            selectView.isSelected = false
            self.selectView = itemView
        }else if selectView == nil {
            selectView = itemView
        }
        if !isDragging {
            startDragging(itemView)
        }
        if !trashViewIsVisible && (isShowTrash || itemView.item.isAudio) {
            UIApplication._keyWindow?.addSubview(trashView)
            showTrashView()
        }
    }
    
    func stickerItemView(didDragScale itemView: EditorStickersItemView) {
        delegate?.stickerView(touchBegan: self)
        if !isDragging {
            startDragging(itemView)
        }
    }
    
    func stickerItemView(touchEnded itemView: EditorStickersItemView) {
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
        isTouching = false
    }
    func stickerItemView(_ itemView: EditorStickersItemView, tapGestureRecognizerNotInScope point: CGPoint) {
        if let selectView = selectView, itemView == selectView {
            if isDragging {
                endDragging(selectView)
            }else {
                deselectedSticker()
            }
            let cPoint = itemView.convert(point, to: self)
            for subView in subviews.reversed() {
                if let itemView = subView as? EditorStickersItemView {
                    if itemView.frame.contains(cPoint) {
                        itemView.isSelected = true
                        self.selectView = itemView
                        bringSubviewToFront(itemView)
                        return
                    }
                }
            }
        }
    }
    
    func stickerItemView(
        _ itemView: EditorStickersItemView,
        panGestureRecognizerChanged panGR: UIPanGestureRecognizer
    ) {
        if !isShowTrash && !itemView.item.isAudio {
            return
        }
        let point = panGR.location(in: UIApplication._keyWindow)
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
                trashView.layer.removeAnimation(forKey: "trashView.transform.scale")
                let animaiton = CAKeyframeAnimation(keyPath: "transform.scale")
                animaiton.duration = 0.3
                animaiton.values = [1.05, 0.95, 1.025, 0.975, 1]
                trashView.layer.add(animaiton, forKey: "trashView.transform.scale")
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
    func stickerItemView(moveToCenter itemView: EditorStickersItemView) -> Bool {
        delegate?.stickerView(self, moveToCenter: itemView) ?? false
    }
    func stickerItemView(panGestureRecognizerEnded itemView: EditorStickersItemView) -> Bool {
        if !isShowTrash && !itemView.item.isAudio {
            if let selectView = selectView, selectView != itemView {
                selectView.isSelected = false
                self.selectView = itemView
            }else if selectView == nil {
                selectView = itemView
            }
            resetItemView(itemView: itemView)
            return false
        }
        let inArea = trashView.inArea
        if inArea {
            isDragging = false
            trashView.inArea = false
            itemView.isDelete = true
            itemView.isEnabled = false
            UIView.animate(withDuration: 0.25) {
                itemView.alpha = 0
            } completion: { _ in
                itemView.removeFromSuperview()
                self.delegate?.stickerView(self, didRemoveItem: itemView)
            }
            selectView = nil
            delegate?.stickerView(self, shouldRemoveItem: itemView)
        }else {
            if let selectView = selectView, selectView != itemView {
                selectView.isSelected = false
                self.selectView = itemView
            }else if selectView == nil {
                selectView = itemView
            }
            resetItemView(itemView: itemView)
        }
        if isDragging {
            hideTrashView()
        }
        return inArea
    }
    func stickerItemView(_ itemView: EditorStickersItemView, maxScale itemSize: CGSize) -> CGFloat {
        if let maxScale = delegate?.stickerView(self, maxScale: itemSize) {
            return maxScale
        }
        return 5
    }
    
    func stickerItemView(_ itemView: EditorStickersItemView, minScale itemSize: CGSize) -> CGFloat {
        if let minScale = delegate?.stickerView(self, minScale: itemSize) {
            return minScale
        }
        return 0.2
    }
    
    func stickerItemView(itemCenter itemView: EditorStickersItemView) -> CGPoint {
        if let center = delegate?.stickerView(itemCenter: self) {
            return center
        }else {
            if let keyWindow = UIApplication._keyWindow {
                return convert(keyWindow.center, from: keyWindow)
            }
        }
        return .zero
    }
    
    func stickerItemView(didDeleteClick itemView: EditorStickersItemView) {
        if itemView == selectView {
            deselectedSticker()
        }
        
        delegate?.stickerView(self, shouldRemoveItem: itemView)
        itemView.removeFromSuperview()
        delegate?.stickerView(self, didRemoveItem: itemView)
    }
    
    struct Item: Codable {
        let items: [Info]
        let mirrorScale: CGPoint
        let angel: CGFloat
        
        struct Info: Codable {
            let item: EditorStickerItem
            let pinchScale: CGFloat
            let rotation: CGFloat
            let centerScale: CGPoint
            let mirrorScale: CGPoint
            let editMirrorScale: CGPoint
            let initialMirrorScale: CGPoint
        }
    }
    
    struct AudioInfo {
        let fontSizeScale: CGFloat
        let animationSizeScale: CGSize
        let audio: EditorStickerAudio
    }
    
    struct Info {
        let image: UIImage?
        let isText: Bool
        let frameScale: FrameScale
        let angel: CGFloat
        let mirrorScale: CGPoint
        let scale: CGFloat
        let viewSize: CGSize
        let audio: AudioInfo?
        
        struct FrameScale {
            let center: CGPoint
            let size: CGSize
        }
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
