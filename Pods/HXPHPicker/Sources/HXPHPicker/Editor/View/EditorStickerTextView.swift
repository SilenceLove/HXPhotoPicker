//
//  EditorStickerTextView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/22.
//

import UIKit

class EditorStickerTextView: UIView {
    let config: PhotoEditorConfiguration.TextConfig
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.layoutManager.delegate = self
        textView.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        textView.contentInset = .zero
        
        textView.becomeFirstResponder()
        return textView
    }()
    
    var text: String {
        textView.text
    }
    
    lazy var textButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage("hx_editor_photo_text_normal".image, for: .normal)
        button.setImage("hx_editor_photo_text_selected".image, for: .selected)
        button.addTarget(self, action: #selector(didTextButtonClick(button:)), for: .touchUpInside)
        return button
    }()
    var currentSelectedIndex: Int = 0 {
        didSet {
            collectionView.scrollToItem(at: IndexPath(item: currentSelectedIndex, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    var currentSelectedColor: UIColor = .clear
    @objc func didTextButtonClick(button: UIButton) {
        button.isSelected = !button.isSelected
        showBackgroudColor = button.isSelected
        useBgColor = currentSelectedColor
        if button.isSelected {
            if currentSelectedColor.isWhite {
                changeTextColor(color: .black)
            }else {
                changeTextColor(color: .white)
            }
        }else {
            changeTextColor(color: currentSelectedColor)
        }
    }
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.itemSize = CGSize(width: 37, height: 37)
        return flowLayout
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(PhotoEditorBrushColorViewCell.self, forCellWithReuseIdentifier: "EditorStickerTextViewCellID")
        return collectionView
    }()
    
    var typingAttributes: [NSAttributedString.Key : Any] = [:]
    var stickerText: EditorStickerText?
    
    var showBackgroudColor: Bool = false
    var useBgColor: UIColor = .clear
    var textIsDelete: Bool = false
    var textLayer: EditorStickerTextLayer?
    var rectArray: [CGRect] = []
    var blankWidth: CGFloat = 22
    var layerRadius: CGFloat = 8
    var keyboardFrame: CGRect = .zero
    var maxIndex: Int = 0
    
    init(config: PhotoEditorConfiguration.TextConfig,
         stickerText: EditorStickerText?) {
        self.config = config
        self.stickerText = stickerText
        super.init(frame: .zero)
        addSubview(textView)
        addSubview(textButton)
        addSubview(collectionView)
        setupTextConfig()
        setupStickerText()
        setupTextColors()
        addKeyboardNotificaition()
    }
    
    func setupStickerText() {
        if let text = stickerText {
            showBackgroudColor = text.showBackgroud
            textView.text = text.text
            textButton.isSelected = text.showBackgroud
        }
        setupTextAttributes()
    }
    
    func setupTextConfig() {
        textView.tintColor = config.tintColor
        textView.font = config.font
    }
    
    func setupTextAttributes() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        let attributes = [NSAttributedString.Key.font: config.font,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        typingAttributes = attributes
        textView.attributedText = NSAttributedString(string: stickerText?.text ?? "", attributes: attributes)
    }
    
    func setupTextColors() {
        for (index, colorHex) in config.colors.enumerated() {
            let color = colorHex.color
            if let text = stickerText {
                if color == text.textColor {
                    if text.showBackgroud {
                        if color.isWhite {
                            changeTextColor(color: .black)
                        }else {
                            changeTextColor(color: .white)
                        }
                        useBgColor = color
                    }else {
                        changeTextColor(color: color)
                    }
                    currentSelectedColor = color
                    currentSelectedIndex = index
                    collectionView.selectItem(at: IndexPath(item: currentSelectedIndex, section: 0), animated: true, scrollPosition: .centeredHorizontally)
                }
            }else {
                if index == 0 {
                    changeTextColor(color: color)
                    currentSelectedColor = color
                    currentSelectedIndex = index
                    collectionView.selectItem(at: IndexPath(item: currentSelectedIndex, section: 0), animated: true, scrollPosition: .centeredHorizontally)
                }
            }
        }
        if textButton.isSelected {
            drawTextBackgroudColor()
        }
    }
    
    func addKeyboardNotificaition() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppearance), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDismiss), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillAppearance(notifi: Notification) {
        guard let info = notifi.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        self.keyboardFrame = keyboardFrame
        UIView.animate(withDuration: duration) {
            self.layoutSubviews()
        }
    }
    
    @objc func keyboardWillDismiss(notifi: Notification) {
        guard let info = notifi.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }
        keyboardFrame = .zero
        UIView.animate(withDuration: duration) {
            self.layoutSubviews()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12 + UIDevice.rightMargin)
        textButton.frame = CGRect(x: UIDevice.leftMargin, y: height - (keyboardFrame.equalTo(.zero) ?  UIDevice.bottomMargin + 50 : 50 + keyboardFrame.height), width: 50, height: 50)
        collectionView.frame = CGRect(x: textButton.frame.maxX, y: textButton.y, width: width - textButton.width, height: 50)
        textView.frame = CGRect(x: 10, y: 0, width: width - 20, height: textButton.y)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

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
        for (index, _) in rectArray.enumerated() {
            if index > 0 {
                maxIndex = index
                processRect(index: index)
            }
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
    
    func drawBackgroundPath(rects: [CGRect]) -> UIBezierPath {
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
                bezierPath?.addArc(withCenter: CGPoint(x: loctionX + layerRadius, y: loctionY + layerRadius), radius: layerRadius, startAngle: CGFloat.pi, endAngle: 1.5 * CGFloat.pi, clockwise: true)
                bezierPath?.addLine(to: CGPoint(x: rect.maxX - layerRadius, y: loctionY))
                bezierPath?.addArc(withCenter: CGPoint(x: rect.maxX - layerRadius, y: loctionY + layerRadius), radius: layerRadius, startAngle: 1.5 * CGFloat.pi, endAngle: 0, clockwise: true)
            }else {
                let lastRect = rectArray[index - 1]
                var nextRect: CGRect?
                if lastRect.maxX > rect.maxX {
                    if index + 1 < rectArray.count {
                        nextRect = rectArray[index + 1]
                        if nextRect!.width > blankWidth && nextRect!.maxX > rect.maxX{
                            half = true
                        }
                    }
                    if half {
                        let radius = (nextRect!.minY - lastRect.maxY) / 2
                        let centerY = nextRect!.minY - radius
                        bezierPath?.addArc(withCenter: CGPoint(x: rect.maxX + radius, y: centerY), radius: radius, startAngle: -CGFloat.pi * 0.5, endAngle: -CGFloat.pi * 1.5, clockwise: false)
                    }else {
                        bezierPath?.addArc(withCenter: CGPoint(x: rect.maxX + layerRadius, y: lastRect.maxY + layerRadius), radius: layerRadius, startAngle: -CGFloat.pi * 0.5, endAngle: -CGFloat.pi, clockwise: false)
                    }
                }else if lastRect.maxX == rect.maxX {
                    bezierPath?.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - layerRadius))
                }else {
                    bezierPath?.addArc(withCenter: CGPoint(x: rect.maxX - layerRadius, y: rect.minY + layerRadius), radius: layerRadius, startAngle: CGFloat.pi * 1.5, endAngle: 0, clockwise: true)
                }
            }
            var hasNext = false
            if index + 1 < rectArray.count {
                let nextRect = rectArray[index + 1]
                if nextRect.width > blankWidth {
                    if rect.maxX > nextRect.maxX {
                        let point = CGPoint(x: rect.maxX, y: rect.maxY - layerRadius)
                        if let currentPoint = bezierPath?.currentPoint, point.equalTo(currentPoint) {
                            bezierPath?.addArc(withCenter: CGPoint(x: rect.maxX - layerRadius, y: rect.maxY - layerRadius), radius: layerRadius, startAngle: 0, endAngle: CGFloat.pi * 0.5, clockwise: true)
                        }else {
                            bezierPath?.addLine(to: point)
                            bezierPath?.addArc(withCenter: CGPoint(x: rect.maxX - layerRadius, y: rect.maxY - layerRadius), radius: layerRadius, startAngle: 0, endAngle: CGFloat.pi * 0.5, clockwise: true)
                        }
                        bezierPath?.addLine(to: CGPoint(x: nextRect.maxX + layerRadius, y: rect.maxY))
                    }else if rect.maxX == nextRect.maxX {
                        bezierPath?.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                    }else {
                        if !half {
                            let point = CGPoint(x: rect.maxX, y: nextRect.minY - layerRadius)
                            if let currentPoint = bezierPath?.currentPoint, point.equalTo(currentPoint) {
                                bezierPath?.addArc(withCenter: CGPoint(x: currentPoint.x + layerRadius, y: currentPoint.y), radius: layerRadius, startAngle: -CGFloat.pi, endAngle: -CGFloat.pi * 1.5, clockwise: false)
                            }else {
                                bezierPath?.addLine(to: point)
                                bezierPath?.addArc(withCenter: CGPoint(x: rect.maxX + layerRadius, y: nextRect.minY - layerRadius), radius: layerRadius, startAngle: -CGFloat.pi, endAngle: -CGFloat.pi * 1.5, clockwise: false)
                            }
                        }
                        bezierPath?.addLine(to: CGPoint(x: nextRect.maxX - layerRadius, y: nextRect.minY))
                    }
                    hasNext = true
                }
            }
            if !hasNext {
                bezierPath?.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - layerRadius))
                bezierPath?.addArc(withCenter: CGPoint(x: rect.maxX - layerRadius, y: rect.maxY - layerRadius), radius: layerRadius, startAngle: 0, endAngle: CGFloat.pi * 0.5, clockwise: true)
                bezierPath?.addLine(to: CGPoint(x: rect.minX + layerRadius, y: rect.maxY))
                bezierPath?.addArc(withCenter: CGPoint(x: rect.minX + layerRadius, y: rect.maxY - layerRadius), radius: layerRadius, startAngle: CGFloat.pi * 0.5, endAngle: CGFloat.pi, clockwise: true)
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
                usedRect = CGRect(x: usedRect.minX - 6, y: usedRect.minY - 8, width: usedRect.width + 12, height: usedRect.height + 8)
            }else {
                usedRect = CGRect(x: usedRect.minX - 6, y: usedRect.minY - 8, width: usedRect.width + 12, height: usedRect.height + 16)
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
                    textLayer?.frame = CGRect(x: 15, y: 15, width: path.bounds.width, height: textView.contentSize.height)
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

extension EditorStickerTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textView.typingAttributes = typingAttributes
        if textIsDelete {
            drawTextBackgroudColor()
            textIsDelete = false
        }
        if !textView.text.isEmpty {
            if textView.text.count > config.maximumLimitTextLength &&
                config.maximumLimitTextLength > 0 {
                let text = textView.text[..<config.maximumLimitTextLength]
                textView.text = text
            }
        }else {
            textLayer?.frame = .zero
        }
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.isEmpty {
            textIsDelete = true
        }
        return true
    }
}

extension EditorStickerTextView: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        if layoutFinishedFlag {
            drawTextBackgroudColor()
        }
    }
}

extension EditorStickerTextView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        config.colors.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditorStickerTextViewCellID", for: indexPath) as! PhotoEditorBrushColorViewCell
        cell.colorHex = config.colors[indexPath.item]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if currentSelectedIndex == indexPath.item {
            return
        }
        collectionView.deselectItem(at: IndexPath(item: currentSelectedIndex, section: 0), animated: true)
        let color = config.colors[indexPath.item].color
        currentSelectedColor = color
        currentSelectedIndex = indexPath.item
        if showBackgroudColor {
            useBgColor = color
            if color.isWhite {
                changeTextColor(color: .black)
            }else {
                changeTextColor(color: .white)
            }
        }else {
            changeTextColor(color: color)
        }
    }
}

class EditorStickerTextLayer: CAShapeLayer {
}
