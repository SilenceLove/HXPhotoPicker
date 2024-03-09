//
//  EditorView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/12.
//

import UIKit
import AVFoundation

open class EditorView: UIScrollView {
    
    public weak var editDelegate: EditorViewDelegate?
    
    /// The URL configuration after editing, the default is under tmp
    /// Please set a different URL each time you edit to prevent the existing data from being overwritten
    /// If editing a GIF, please set the URL of the gif suffix
    /// 编辑之后的URL配置，默认在tmp下
    /// 每次编辑时请设置不同URL，防止之前存在的数据被覆盖
    /// 如果编辑的是GIF，请设置gif后缀的URL
    public var urlConfig: EditorURLConfig? {
        didSet { adjusterView.urlConfig = urlConfig }
    }
    
    /// Content margins (enter/exit editing state, there will be no shrink/zoom animation)
    /// Edits are reset every time you set
    /// 内容边距（进入/退出 编辑状态，不会有 缩小/放大 动画）
    /// 每次设置都会重置编辑内容
    open override var contentInset: UIEdgeInsets {
        didSet {
            resetState()
            setContent()
        }
    }
    
    /// Margin in editing state (entering/exiting editing state, there will be shrink/enlarge animation)
    /// Edits are reset every time you set
    /// 编辑状态下的边距（进入/退出 编辑状态，会有 缩小/放大 动画）
    /// 每次设置都会重置编辑内容 
    public var editContentInset: ((EditorView) -> UIEdgeInsets)? {
        didSet {
            resetState()
            setContent()
        }
    }
    
    /// Mask color, must be consistent with the background of the parent view
    /// 遮罩颜色，必须与父视图的背景一致
    public var maskColor: UIColor = .black {
        didSet {
            if maskColor != .clear {
                adjusterView.maskColor = maskColor
            }
        }
    }
    
    public var contentCompletionHandler: ((EditorView) -> Void)?
    
    /// 是否可以双指缩放大小
    public var isCanZoomScale: Bool = true {
        didSet {
            pinchGestureRecognizer?.isEnabled = isCanZoomScale
        }
    }
    
    public var innerZoomScale: CGFloat = 1 {
        didSet {
            if !isCanZoomScale {
                adjusterView.zoomScale = innerZoomScale
            }
        }
    }
    
    open override var backgroundColor: UIColor? {
        didSet {
            guard let backgroundColor = backgroundColor, backgroundColor != .clear else {
                return
            }
            maskColor = backgroundColor
        }
    }
    
    // MARK: initialize
    public init() {
        super.init(frame: .zero)
        initView()
    }
    
    public init(
        _ image: UIImage,
        adjustmentData: EditAdjustmentData? = nil
    ) {
        super.init(frame: .zero)
        initView()
        setImage(image)
        if let data = adjustmentData {
            setAdjustmentData(data)
        }
    }
    public init(
        _ imageData: Data,
        adjustmentData: EditAdjustmentData? = nil
    ) {
        super.init(frame: .zero)
        initView()
        setImageData(imageData)
        if let data = adjustmentData {
            setAdjustmentData(data)
        }
    }
    public init(
        _ avAsset: AVAsset,
        adjustmentData: EditAdjustmentData? = nil
    ) {
        super.init(frame: .zero)
        initView()
        setAVAsset(avAsset)
        if let data = adjustmentData {
            setAdjustmentData(data)
        }
    }
    
    open override var zoomScale: CGFloat {
        didSet { adjusterView.zoomScale = zoomScale }
    }
    
    // MARK: private
    var allowZoom: Bool = true
    var editSize: CGSize = .zero
    var editState: State = .normal
    var contentScale: CGFloat {
        adjusterView.contentScale
    }
    var layoutContent: Bool = true
    var reloadContent: Bool = false
    var operates: [Operate] = []
    var reloadOperates: [Operate] = []
     
    var adjusterView: EditorAdjusterView!
    
    // MARK: layoutViews
    open override func layoutSubviews() {
        super.layoutSubviews()
        if !layoutContent && reloadContent && type == .image {
            reloadContent = false
            layoutContent = true
        }
        if layoutContent {
            if contentScale == 0 {
                reloadContent = true
                layoutContent = false
                return
            }
            setContent()
            if !operates.isEmpty || !reloadOperates.isEmpty {
                adjusterView.layoutIfNeeded()
            }
            operatesHandler()
            layoutContent = false
        }
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == adjusterView.containerView {
            if isDrawEnabled {
                return adjusterView.contentView.drawView
            }
            if isMosaicEnabled {
                return adjusterView.contentView.mosaicView
            }
        }
        return view
    }
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if isDrawEnabled, drawType == .canvas {
            return adjusterView.point(inside: point, with: event)
        }
        return super.point(inside: point, with: event)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: private
extension EditorView {
    
    private func initView() {
        delegate = self
        minimumZoomScale = 1.0
        maximumZoomScale = 10.0
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        clipsToBounds = false
        scrollsToTop = false
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
        adjusterView = EditorAdjusterView(maskColor: maskColor)
        adjusterView.delegate = self
        adjusterView.setContentInsets = { [weak self] in
            guard let self = self, let insets = self.editContentInset?(self) else {
                return .zero
            }
            return insets
        }
        addSubview(adjusterView)
    }
    
    func updateContentSize() {
        let viewWidth = width - contentInset.left - contentInset.right
        let viewHeight = height - contentInset.top - contentInset.bottom
        let contentWidth = viewWidth
        var contentHeight: CGFloat
        if editSize.equalTo(.zero) {
            contentHeight = contentWidth / contentScale
        }else {
            contentHeight = editSize.height
        }
        let contentX: CGFloat = 0
        var contentY: CGFloat = 0
        if contentHeight < viewHeight {
            contentY = (viewHeight - contentHeight) * 0.5
            adjusterView.setFrame(
                CGRect(x: 0, y: -contentY, width: viewWidth, height: viewHeight),
                maxRect: bounds,
                contentInset: contentInset
            )
        }else {
            adjusterView.setFrame(
                .init(x: 0, y: 0, width: viewWidth, height: viewHeight),
                maxRect: bounds,
                contentInset: contentInset
            )
        }
        contentSize = CGSize(width: contentWidth, height: contentHeight)
        adjusterView.frame = CGRect(x: contentX, y: contentY, width: contentWidth, height: contentHeight)
    }
    
    func setCustomMaskFrame(_ isReset: Bool) {
        let viewWidth = width - contentInset.left - contentInset.right
        let viewHeight = height - contentInset.top - contentInset.bottom
        let contentWidth = viewWidth
        var contentHeight: CGFloat
        if editSize.equalTo(.zero) {
            contentHeight = contentWidth / contentScale
        }else {
            contentHeight = editSize.height
        }
        var contentY: CGFloat = 0
        if contentHeight < viewHeight {
            contentY = (viewHeight - contentHeight) * 0.5
            adjusterView.setCustomMaskFrame(
                CGRect(x: 0, y: -contentY, width: viewWidth, height: viewHeight),
                maxRect: bounds,
                contentInset: contentInset
            )
        }else {
            if !isReset {
                adjusterView.setCustomMaskFrame(
                    .init(x: 0, y: 0, width: viewWidth, height: contentHeight),
                    maxRect: .init(x: 0, y: 0, width: width, height: contentHeight),
                    contentInset: contentInset
                )
            }else {
                adjusterView.setCustomMaskFrame(
                    .init(x: 0, y: 0, width: viewWidth, height: viewHeight),
                    maxRect: bounds,
                    contentInset: contentInset
                )
            }
        }
    }
    
    func setContent() {
        if size.equalTo(.zero) || contentScale == 0 {
            layoutContent = true
            return
        }
        layoutContent = false
        updateContentSize()
        adjusterView.setContent()
        adjusterView.setMaskRect()
        resetEdit()
        
        if !operates.isEmpty {
            operatesHandler()
        }
        contentCompletionHandler?(self)
    }
    
    func resetZoomScale(
        _ animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        if editState == .normal {
            allowZoom = true
        }
        if animated {
            UIView.animate {
                if self.zoomScale != 1 {
                    self.zoomScale = 1
                }
            } completion: { _ in
                self.allowZoom = self.editState == .normal
                completion?()
            }
        }else {
            if zoomScale != 1 {
                zoomScale = 1
            }
            allowZoom = editState == .normal
            completion?()
        }
        setContentOffset(
            CGPoint(x: -contentInset.left, y: -contentInset.top),
            animated: false
        )
    }
    
    func resetState() {
        if maskImage != nil {
            maskImage = nil
        }
        editSize = .zero
        adjusterView.state = .edit
        adjusterView.resetAll()
        if editState == .normal {
            adjusterView.state = .normal
            resetZoomScale(false)
        }
        undoAllDraw()
        undoAllMosaic()
    }
    
    func resetEdit() {
        if editState == .edit {
            adjusterView.startEdit(false)
            if adjusterView.isRoundMask {
                isFixedRatio = true
                adjusterView.setAspectRatio(.init(width: 1, height: 1), resetRound: false, animated: false)
            }
        }else {
            adjusterView.resetScrollContent()
        }
    }
    
    func operatesHandler() {
    o: for operate in operates {
            switch operate {
            case .setData(let data):
                setAdjustmentData(data)
                break o
            default:
                break
            }
        }
    o: for operate in reloadOperates {
            switch operate {
            case .setData(let data):
                setAdjustmentData(data)
                break o
            default:
                break
            }
        }
        for operate in operates {
            operateHandler(operate)
        }
        for operate in reloadOperates {
            operateHandler(operate)
        }
        operates.removeAll()
        reloadOperates.removeAll()
    }
    
    func operateHandler(_ operate: Operate) {
        switch operate {
        case .startEdit(let completion):
            startEdit(false, completion: completion)
        case .finishEdit(let completion):
            finishEdit(false, completion: completion)
        case .cancelEdit(let completion):
            cancelEdit(false, completion: completion)
        case .rotate(let angle, let completion):
            rotate(angle, animated: false, completion: completion)
        case .rotateLeft(let completion):
            rotateLeft(false, completion: completion)
        case .rotateRight(let completion):
            rotateRight(false, completion: completion)
        case .mirrorHorizontally(let completion):
            mirrorHorizontally(false, completion: completion)
        case .mirrorVertically(let completion):
            mirrorVertically(false, completion: completion)
        case .reset(let completion):
            reset(false, completion: completion)
        case .setRoundMask(let isRound):
            setRoundMask(isRound, animated: false)
        default:
            break
        }
    }
    
    func updateEditSize() {
        if editSize == .zero {
            return
        }
        let viewWidth = width - contentInset.left - contentInset.right
        let controlScale = editSize.height / editSize.width
        let rectW = viewWidth
        let rectH = viewWidth * controlScale
        editSize = .init(width: rectW, height: rectH)
    }
}
