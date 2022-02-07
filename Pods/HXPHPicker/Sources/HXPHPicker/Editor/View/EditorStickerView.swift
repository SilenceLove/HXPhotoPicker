//
//  EditorStickerView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/20.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

protocol EditorStickerViewDelegate: AnyObject {
    func stickerView(touchBegan stickerView: EditorStickerView)
    func stickerView(touchEnded stickerView: EditorStickerView)
    func stickerView(_ stickerView: EditorStickerView, moveToCenter rect: CGRect) -> Bool
    func stickerView(_ stickerView: EditorStickerView, minScale itemSize: CGSize) -> CGFloat
    func stickerView(_ stickerView: EditorStickerView, maxScale itemSize: CGSize) -> CGFloat
    func stickerView(_ stickerView: EditorStickerView, updateStickerText item: EditorStickerItem)
    func stickerView(didRemoveAudio stickerView: EditorStickerView)
}

extension EditorStickerViewDelegate {
    func stickerView(didRemoveAudio stickerView: EditorStickerView) {}
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
    weak var audioView: EditorStickerItemView?
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
            if let itemView = view.superview as? EditorStickerItemView,
               !itemView.isDelete {
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
    func add(
        sticker item: EditorStickerItem,
        isSelected: Bool
    ) -> EditorStickerItemView {
        selectView?.isSelected = false
        let itemView = EditorStickerItemView(item: item, scale: scale)
        itemView.delegate = self
        var pScale: CGFloat
        if item.text == nil && item.music == nil {
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
        }else if item.text != nil {
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
        itemView.initialAngle = angle
        itemView.initialMirrorType = mirrorType
        
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
        if item.music != nil {
            audioView = itemView
        }
        return itemView
    }
    func deselectedSticker() {
        selectView?.isSelected = false
        selectView = nil
    }
    func removeAudioView() {
        audioView?.invalidateTimer()
        audioView?.removeFromSuperview()
        audioView = nil
    }
    func removeAllSticker() {
        deselectedSticker()
        removeAudioView()
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
        guard let superview = itemView.superview,
              superview != self else {
            return
        }
        let arg = itemView.radian - currentItemArg
        if superview == UIApplication.shared.keyWindow {
            let rect = superview.convert(itemView.frame, to: self)
            itemView.frame = rect
        }
        addSubview(itemView)
        if mirrorType == .none {
            itemView.update(
                pinchScale: itemView.pinchScale,
                rotation: itemView.radian - currentItemDegrees,
                isMirror: true
            )
        }else {
            itemView.update(
                pinchScale: itemView.pinchScale,
                rotation: beforeItemArg + arg,
                isMirror: true
            )
        }
    }
    
    func windowAdd(itemView: EditorStickerItemView) {
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
                    itemView.update(
                        pinchScale: itemView.pinchScale,
                        rotation: itemView.radian + radians,
                        isMirror: true
                    )
                }else {
                    itemView.update(
                        pinchScale: itemView.pinchScale,
                        rotation: itemView.radian - radians,
                        isMirror: true
                    )
                }
            }
        }
        currentItemArg = itemView.radian
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
            self.trashView.centerX = UIScreen.main.bounds.width * 0.5
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
            self.trashView.centerX = UIScreen.main.bounds.width * 0.5
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
        var showLyric = false
        var LyricIndex = 0
        for (index, subView) in subviews.enumerated() {
            if let itemView = subView as? EditorStickerItemView {
                if itemView.item.music != nil {
                    showLyric = true
                    LyricIndex = index
                }
                let centerScale = CGPoint(x: itemView.centerX / width, y: itemView.centerY / height)
                let itemData = EditorStickerItemData(
                    item: itemView.item,
                    pinchScale: itemView.pinchScale,
                    rotation: itemView.radian,
                    centerScale: centerScale,
                    mirrorType: itemView.mirrorType,
                    superMirrorType: itemView.superMirrorType,
                    superAngel: itemView.superAngle,
                    initialAngle: itemView.initialAngle,
                    initialMirrorType: itemView.initialMirrorType
                )
                datas.append(itemData)
            }
        }
        if datas.isEmpty {
            return nil
        }
        let stickerData = EditorStickerData(
            items: datas,
            mirrorType: mirrorType,
            angel: angle,
            showLyric: showLyric,
            LyricIndex: LyricIndex
        )
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
            itemView.initialAngle = itemData.initialAngle
            itemView.initialMirrorType = itemData.initialMirrorType
            itemView.update(
                pinchScale: itemData.pinchScale,
                rotation: itemData.rotation,
                isInitialize: true,
                isMirror: true
            )
            itemView.center = CGPoint(
                x: viewSize.width * itemData.centerScale.x,
                y: viewSize.height * itemData.centerScale.y
            )
        }
    }
    func getStickerInfo() -> [EditorStickerInfo] {
        var infos: [EditorStickerInfo] = []
        for subView in subviews {
            if let itemView = subView as? EditorStickerItemView {
                let image: UIImage
                if let imageData = itemView.item.imageData {
                    #if canImport(Kingfisher)
                    image = DefaultImageProcessor.default.process(
                        item: .data(imageData),
                        options: .init([])
                    )!
                    #else
                    image = UIImage.init(data: imageData)!
                    #endif
                }else {
                    image = itemView.item.image
                }
                let music: EditorStickerInfoMusic?
                if let musicInfo = itemView.item.music {
                    music = .init(
                        fontSizeScale: 25.0 / width,
                        animationSizeScale: CGSize(
                            width: 20 / width,
                            height: 15 / height
                        ),
                        music: musicInfo
                    )
                }else {
                    music = nil
                }
                let info = EditorStickerInfo(
                    image: image,
                    isText: itemView.item.text != nil,
                    centerScale: CGPoint(x: itemView.centerX / width, y: itemView.centerY / height),
                    sizeScale: CGSize(
                        width: itemView.item.frame.width / width,
                        height: itemView.item.frame.height / height
                    ),
                    angel: itemView.radian,
                    scale: itemView.pinchScale,
                    viewSize: size,
                    music: music,
                    initialAngle: itemView.initialAngle,
                    initialMirrorType: itemView.initialMirrorType
                )
                infos.append(info)
            }
        }
        return infos
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct EditorStickerInfo {
    let image: UIImage
    let isText: Bool
    let centerScale: CGPoint
    let sizeScale: CGSize
    let angel: CGFloat
    let scale: CGFloat
    let viewSize: CGSize
    let music: EditorStickerInfoMusic?
    let initialAngle: CGFloat
    let initialMirrorType: EditorImageResizerView.MirrorType
}
struct EditorStickerInfoMusic {
    let fontSizeScale: CGFloat
    let animationSizeScale: CGSize
    let music: VideoEditorMusic?
}

struct EditorStickerData: Codable {
    let items: [EditorStickerItemData]
    let mirrorType: EditorImageResizerView.MirrorType
    let angel: CGFloat
    let showLyric: Bool
    let LyricIndex: Int
}

struct EditorStickerItemData: Codable {
    let item: EditorStickerItem
    let pinchScale: CGFloat
    let rotation: CGFloat
    let centerScale: CGPoint
    let mirrorType: EditorImageResizerView.MirrorType
    let superMirrorType: EditorImageResizerView.MirrorType
    let superAngel: CGFloat
    let initialAngle: CGFloat
    let initialMirrorType: EditorImageResizerView.MirrorType
}
