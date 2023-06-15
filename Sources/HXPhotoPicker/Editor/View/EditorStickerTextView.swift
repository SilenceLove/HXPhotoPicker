//
//  EditorStickerTextView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/7/22.
//

import UIKit

class EditorStickerTextView: UIView {
    let config: EditorConfiguration.Text
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.layoutManager.delegate = self
        textView.textContainerInset = UIEdgeInsets(top: 15, left: 15 + UIDevice.leftMargin, bottom: 15, right: 15 + UIDevice.rightMargin)
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
            collectionView.scrollToItem(
                at: IndexPath(item: currentSelectedIndex, section: 0),
                at: .centeredHorizontally,
                animated: true
            )
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
        collectionView.register(
            EditorStickerTextViewCell.self,
            forCellWithReuseIdentifier: "EditorStickerTextViewCellID"
        )
        return collectionView
    }()
    
    var typingAttributes: [NSAttributedString.Key: Any] = [:]
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
    
    init(
        config: EditorConfiguration.Text,
        stickerText: EditorStickerText?
    ) {
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
                    collectionView.selectItem(
                        at: IndexPath(item: currentSelectedIndex, section: 0),
                        animated: true,
                        scrollPosition: .centeredHorizontally
                    )
                }
            }else {
                if index == 0 {
                    changeTextColor(color: color)
                    currentSelectedColor = color
                    currentSelectedIndex = index
                    collectionView.selectItem(
                        at: IndexPath(item: currentSelectedIndex, section: 0),
                        animated: true,
                        scrollPosition: .centeredHorizontally
                    )
                }
            }
        }
        if textButton.isSelected {
            drawTextBackgroudColor()
        }
    }
    
    func addKeyboardNotificaition() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillAppearance),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillDismiss),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
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
        textButton.frame = CGRect(
            x: UIDevice.leftMargin,
            y: height - (
                keyboardFrame.equalTo(.zero) ?
                UIDevice.bottomMargin + 50 :
                    50 + keyboardFrame.height
            ),
            width: 50,
            height: 50
        )
        collectionView.frame = CGRect(
            x: textButton.frame.maxX,
            y: textButton.y,
            width: width - textButton.width,
            height: 50
        )
        textView.frame = CGRect(x: 10, y: 0, width: width - 20, height: textButton.y)
        textView.textContainerInset = UIEdgeInsets(top: 15, left: 15 + UIDevice.leftMargin, bottom: 15, right: 15 + UIDevice.rightMargin)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

class EditorStickerTextViewCell: UICollectionViewCell {
    lazy var colorBgView: UIView = {
        let view = UIView.init()
        view.size = CGSize(width: 22, height: 22)
        view.layer.cornerRadius = 11
        view.layer.masksToBounds = true
        view.addSubview(imageView)
        return view
    }()
    
    lazy var imageView: UIImageView = {
        let view = UIImageView(image: "hx_editor_brush_color_custom".image)
        view.isHidden = true
        
        let bgLayer = CAShapeLayer()
        bgLayer.contentsScale = UIScreen.main.scale
        bgLayer.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        bgLayer.fillColor = UIColor.white.cgColor
        let bgPath = UIBezierPath(
            roundedRect: CGRect(x: 1.5, y: 1.5, width: 19, height: 19),
            cornerRadius: 19 * 0.5
        )
        bgLayer.path = bgPath.cgPath
        view.layer.addSublayer(bgLayer)

        let maskLayer = CAShapeLayer()
        maskLayer.contentsScale = UIScreen.main.scale
        maskLayer.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        let maskPath = UIBezierPath(rect: bgLayer.bounds)
        maskPath.append(
            UIBezierPath(
                roundedRect: CGRect(x: 3, y: 3, width: 16, height: 16),
                cornerRadius: 8
            ).reversing()
        )
        maskLayer.path = maskPath.cgPath
        view.layer.mask = maskLayer
        return view
    }()
    
    lazy var colorView: UIView = {
        let view = UIView.init()
        view.size = CGSize(width: 16, height: 16)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    var colorHex: String! {
        didSet {
            imageView.isHidden = true
            guard let colorHex = colorHex else { return }
            let color = colorHex.color
            if color.isWhite {
                colorBgView.backgroundColor = "#dadada".color
            }else {
                colorBgView.backgroundColor = .white
            }
            colorView.backgroundColor = color
        }
    }
    
    var customColor: PhotoEditorBrushCustomColor? {
        didSet {
            guard let customColor = customColor else {
                return
            }
            imageView.isHidden = false
            colorView.backgroundColor = customColor.color
        }
    }
    
    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.colorBgView.transform = self.isSelected ? .init(scaleX: 1.25, y: 1.25) : .identity
                self.colorView.transform = self.isSelected ? .init(scaleX: 1.3, y: 1.3) : .identity
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(colorBgView)
        contentView.addSubview(colorView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        colorBgView.center = CGPoint(x: width / 2, y: height / 2)
        imageView.frame = colorBgView.bounds
        colorView.center = CGPoint(x: width / 2, y: height / 2)
    }
}

struct PhotoEditorBrushCustomColor {
    var isFirst: Bool = true
    var isSelected: Bool = false
    var color: UIColor
}
