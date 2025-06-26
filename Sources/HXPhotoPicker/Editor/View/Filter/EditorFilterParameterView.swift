//
//  EditorFilterParameterView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/21.
//

import UIKit

protocol EditorFilterParameterViewDelegate: AnyObject {
    func filterParameterView(
        _ filterParameterView: EditorFilterParameterView,
        didChanged model: PhotoEditorFilterParameterInfo
    )
    func filterParameterView(
        didStart filterParameterView: EditorFilterParameterView
    )
    func filterParameterView(
        didEnded filterParameterView: EditorFilterParameterView
    )
}

class EditorFilterParameterView: UIView {
    
    enum `Type` {
        case filter
        case edit(type: EditorFilterEditModel.`Type`)
    }
    
    weak var delegate: EditorFilterParameterViewDelegate?
    
    private var bgView: UIVisualEffectView!
    private var titleLb: UILabel!
    private var flowLayout: UICollectionViewFlowLayout!
    private var collectionView: UICollectionView!
    
    var type: `Type` = .filter
    
    var title: String? {
        didSet {
            titleLb.text = title
        }
    }
    
    var models: [PhotoEditorFilterParameterInfo] = [] {
        didSet {
            updateContentFrame()
            collectionView.reloadData()
        }
    }
    
    let sliderColor: UIColor
    
    init(sliderColor: UIColor) {
        self.sliderColor = sliderColor
        super.init(frame: .zero)
        initViews()
        addSubview(bgView)
    }
    
    private func initViews() {
        titleLb = UILabel()
        titleLb.textColor = .white
        titleLb.textAlignment = .center
        titleLb.font = .systemFont(ofSize: 15)
        titleLb.adjustsFontSizeToFitWidth = true
        
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        collectionView = HXCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.register(
            EditorFilterParameterViewCell.self,
            forCellWithReuseIdentifier: "EditorFilterParameterViewCell"
        )
        
        let visualEffect: UIBlurEffect = .init(style: .dark)
        bgView = .init(effect: visualEffect)
        bgView.contentView.addSubview(titleLb)
        bgView.contentView.addSubview(collectionView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if bgView.frame.equalTo(bounds) {
            return
        }
        bgView.frame = bounds
        updateContentFrame()
    }
    
    private func updateContentFrame() {
        if UIDevice.isPortrait {
            flowLayout.scrollDirection = .horizontal
            titleLb.frame = .init(x: 0, y: 10, width: width, height: 20)
            collectionView.x = 0
            collectionView.width = width
            if models.count == 1 {
                flowLayout.itemSize = .init(width: collectionView.width, height: 60)
                collectionView.height = 60
                collectionView.centerY = 25 + (height - UIDevice.bottomMargin - 30) * 0.5
            }else {
                flowLayout.itemSize = .init(width: collectionView.width, height: 40)
                collectionView.height = CGFloat(models.count) * 40
                collectionView.centerY = 30 + (height - UIDevice.bottomMargin - 30) * 0.5
            }
        }else {
            flowLayout.scrollDirection = .vertical
            titleLb.frame = .init(x: 0, y: UIDevice.topMargin, width: width - UIDevice.rightMargin, height: 44)
            collectionView.y = titleLb.frame.maxY
            collectionView.height = height - collectionView.y
            if models.count == 1 {
                collectionView.width = 60
                flowLayout.itemSize = .init(width: 60, height: collectionView.height)
            }else {
                collectionView.width = min(CGFloat(40 * models.count), 150 + UIDevice.rightMargin)
                flowLayout.itemSize = .init(width: 40, height: collectionView.height)
            }
            if collectionView.width < titleLb.width {
                collectionView.centerX = titleLb.centerX
            }else {
                collectionView.x = 0
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorFilterParameterView: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        models.count
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorFilterParameterViewCell",
            for: indexPath
        ) as! EditorFilterParameterViewCell
        cell.model = models[indexPath.row]
        cell.sliderColor = sliderColor
        cell.sliderDidChanged = { [weak self] model in
            guard let self = self else { return }
            self.delegate?.filterParameterView(self, didChanged: model)
        }
        cell.sliderDidStart = { [weak self] in
            guard let self = self else { return }
            self.delegate?.filterParameterView(didStart: self)
        }
        cell.sliderDidEnded = { [weak self] in
            guard let self = self else { return }
            self.delegate?.filterParameterView(didEnded: self)
        }
        return cell
    }
}

class EditorFilterParameterViewCell: UICollectionViewCell, ParameterSliderViewDelegate {
    private var titleLb: UILabel!
    private var slider: ParameterSliderView!
    private var numberLb: UILabel!
    private var resetBtn: ExpandButton!
    
    var sliderDidStart: (() -> Void)?
    var sliderDidEnded: (() -> Void)?
    var sliderDidChanged: ((PhotoEditorFilterParameterInfo) -> Void)?
    
    var model: PhotoEditorFilterParameterInfo? {
        didSet {
            guard let model = model else {
                return
            }
            slider.type = model.sliderType
            slider.setValue(CGFloat(model.value), isAnimation: false)
            numberLb.text = String(Int(slider.value * 100))
            titleLb.text = model.parameter.title
        }
    }
    
    var sliderColor: UIColor? {
        didSet {
            guard let sliderColor = sliderColor else {
                return
            }
            slider.progressColor = sliderColor.withAlphaComponent(0.3)
            slider.trackColor = sliderColor
        }
    }
    
    var value: CGFloat {
        get { slider.value }
        set { 
            slider.setValue(newValue, isAnimation: false)
            sliderView(slider, didChangedValue: slider.value, state: .touchDown)
            sliderView(slider, didChangedValue: slider.value, state: .changed)
            sliderView(slider, didChangedValue: slider.value, state: .touchUpInSide)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        initViews()
        contentView.addSubview(titleLb)
        contentView.addSubview(slider)
        contentView.addSubview(resetBtn)
        contentView.addSubview(numberLb)
    }
    private func initViews() {
        titleLb = UILabel()
        titleLb.textColor = .white
        titleLb.textAlignment = .center
        titleLb.font = .systemFont(ofSize: 15)
        titleLb.adjustsFontSizeToFitWidth = true
        
        resetBtn = ExpandButton(type: .system)
        resetBtn.setImage(.imageResource.editor.filter.reset.image, for: .normal)
        resetBtn.size = resetBtn.currentImage?.size ?? .zero
        resetBtn.tintColor = .white
        resetBtn.addTarget(self, action: #selector(didResetButtonClick), for: .touchUpInside)
        
        slider = ParameterSliderView()
        slider.value = 1
        slider.delegate = self
        
        numberLb = UILabel()
        numberLb.text = "100"
        numberLb.textColor = .white
        numberLb.font = .systemFont(ofSize: 15)
        numberLb.textAlignment = .center
    }
    
    @objc
    func didResetButtonClick() {
        value = CGFloat(model?.parameter.defaultValue ?? 0)
    }
    
    func sliderView(
        _ sliderView: ParameterSliderView,
        didChangedValue value: CGFloat,
        state: ParameterSliderView.Event
    ) {
        if state == .touchDown {
            sliderDidStart?()
        }
        numberLb.text = String(Int(sliderView.value * 100))
        model?.value = Float(sliderView.value)
        if sliderView.value == 0 {
            model?.isNormal = true
        }else {
            model?.isNormal = false
        }
        if let model = model {
            sliderDidChanged?(model)
        }
        if state == .touchUpInSide {
            sliderDidEnded?()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.isPortrait {
            titleLb.y = 0
            titleLb.x = 15 + UIDevice.leftMargin
            titleLb.width = titleLb.textWidth
            titleLb.height = height
            
            resetBtn.x = width - UIDevice.rightMargin - resetBtn.width - 15
            numberLb.x = UIDevice.leftMargin + 10
            numberLb.width = 40
            numberLb.height = numberLb.textHeight
            if model?.parameter.title != nil {
                numberLb.centerY = titleLb.frame.maxY + 10
                slider.x = UIDevice.leftMargin + 60
                slider.size = .init(width: width - slider.x * 2, height: 20)
                slider.centerY = numberLb.centerY
                resetBtn.centerY = slider.centerY
            }else {
                numberLb.centerY = height / 2
                
                slider.x = UIDevice.leftMargin + 60
                slider.width = width - slider.x * 2
                slider.height = 20
                slider.centerY = numberLb.centerY
                resetBtn.centerY = slider.centerY
            }
        }else {
            titleLb.x = 0
            titleLb.y = 15
            titleLb.width = width
            titleLb.height = titleLb.textHeight
             
            numberLb.height = 20
            numberLb.width = width
            numberLb.centerX = titleLb.centerX
            if model?.parameter.title != nil {
                numberLb.y = titleLb.frame.maxY + 10
            }else {
                numberLb.y = 15
            }
            resetBtn.y = height - UIDevice.bottomMargin - 15 - resetBtn.height
            slider.y = numberLb.frame.maxY + 20
            slider.width = 20
            slider.height = resetBtn.y - slider.y - 20
            slider.centerX = numberLb.centerX
            
            resetBtn.centerX = slider.centerX
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol ParameterSliderViewDelegate: AnyObject {
    func sliderView(
        _ sliderView: ParameterSliderView,
        didChangedValue value: CGFloat,
        state: ParameterSliderView.Event
    )
}

class ParameterSliderView: UIView {
    
    enum `Type`: Codable {
        case normal
        case center
    }
    
    enum Event {
        case touchDown
        case touchUpInSide
        case changed
    }
    
    weak var delegate: ParameterSliderViewDelegate?
    private var panGR: PhotoPanGestureRecognizer!
    private var thumbView: UIImageView!
    private var trackView: UIView!
    private var progressView: UIView!
    private var pointView: UIView!
    
    var value: CGFloat = 0
    var thumbViewFrame: CGRect = .zero
    var didImpactFeedback = false
    var trackColor: UIColor? {
        didSet {
            trackView.backgroundColor = trackColor
            pointView.backgroundColor = trackColor
        }
    }
    var progressColor: UIColor? {
        didSet {
            progressView.backgroundColor = progressColor
        }
    }
    var type: `Type` {
        didSet {
            pointView.isHidden = type == .normal
            layoutSubviews()
        }
    }
    
    init(type: `Type` = .normal) {
        self.type = type
        super.init(frame: .zero)
        initViews()
    }
    
    private func initViews() {
        progressView = UIView()
        progressView.backgroundColor = .white.withAlphaComponent(0.2)
        progressView.layer.masksToBounds = true
        progressView.layer.cornerRadius = 1
        addSubview(progressView)
        trackView = UIView()
        trackView.backgroundColor = .white
        trackView.layer.masksToBounds = true
        trackView.layer.cornerRadius = 1
        addSubview(trackView)
        pointView = UIView()
        pointView.backgroundColor = .white
        pointView.layer.masksToBounds = true
        pointView.layer.cornerRadius = 3
        pointView.isHidden = type == .normal
        addSubview(pointView)
        let imageSize = CGSize(width: 18, height: 18)
        thumbView = UIImageView(image: .image(for: .white, havingSize: imageSize, radius: 9))
        thumbView.size = imageSize
        addSubview(thumbView)
        panGR = PhotoPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerClick(pan:)))
        addGestureRecognizer(panGR)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let rect = CGRect(
            x: thumbView.x - 15,
            y: thumbView.y - 15,
            width: thumbView.width + 30,
            height: thumbView.height + 30
        )
        if rect.contains(point) {
            return thumbView
        }
        return super.hitTest(point, with: event)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.isPortrait {
            progressView.frame = CGRect(x: 0, y: (height - 3) * 0.5, width: width, height: 3)
            trackView.frame = CGRect(x: 0, y: (height - 3) * 0.5, width: width * value, height: 3)
            thumbView.centerY = height * 0.5
            if type == .normal {
                thumbView.centerX = width * value
            }else {
                trackView.width = width * 0.5 * value
                if value >= 0 {
                    trackView.x = width * 0.5
                }else {
                    trackView.x = width * 0.5 - trackView.width
                }
                thumbView.centerX = width * 0.5 + width * 0.5 * value
                pointView.size = .init(width: 6, height: 6)
                pointView.center = progressView.center
            }
        }else {
            progressView.frame = CGRect(x: (width - 3) * 0.5, y: 0, width: 3, height: height)
            trackView.frame = CGRect(x: (width - 3) * 0.5, y: 0, width: 3, height: height * value)
            thumbView.centerX = width * 0.5
            if type == .normal {
                thumbView.centerY = height * value
            }else {
                trackView.height = height * 0.5 * value
                if value >= 0 {
                    trackView.y = height * 0.5
                }else {
                    trackView.y = height * 0.5 - trackView.height
                }
                thumbView.centerY = height * 0.5 + height * 0.5 * value
                pointView.size = .init(width: 6, height: 6)
                pointView.center = progressView.center
            }
        }
    }
    
    func setValue(
        _ value: CGFloat,
        isAnimation: Bool
    ) {
        switch panGR.state {
        case .began, .changed, .ended:
            return
        default:
            break
        }
        if type == .normal {
            if value < 0 {
                self.value = 0
            }else if value > 1 {
                self.value = 1
            }else {
                self.value = value
            }
        }else {
            if value < -1 {
                self.value = -1
            }else if value > 1 {
                self.value = 1
            }else {
                self.value = value
            }
        }
        if UIDevice.isPortrait {
            let currentWidth = self.value * width
            if isAnimation {
                UIView.animate(
                    withDuration: 0.1,
                    delay: 0,
                    options: [
                        .curveLinear,
                        .allowUserInteraction
                    ]
                ) {
                    if self.type == .normal {
                        self.thumbView.centerX = self.width * self.value
                        self.trackView.width = currentWidth
                    }else {
                        self.trackView.width = self.width * 0.5 * value
                        if value >= 0 {
                            self.trackView.x = self.width * 0.5
                        }else {
                            self.trackView.x = self.width * 0.5 - self.trackView.width
                        }
                        self.thumbView.centerX = self.width * 0.5 + self.width * 0.5 * value
                    }
                }
            }else {
                if type == .normal {
                    thumbView.centerX = width * value
                    trackView.width = currentWidth
                }else {
                    trackView.width = width * 0.5 * value
                    if value >= 0 {
                        trackView.x = width * 0.5
                    }else {
                        trackView.x = width * 0.5 - trackView.width
                    }
                    thumbView.centerX = width * 0.5 + width * 0.5 * value
                }
            }
        }else {
            let currentHeight = self.value * height
            if isAnimation {
                UIView.animate(
                    withDuration: 0.1,
                    delay: 0,
                    options: [
                        .curveLinear,
                        .allowUserInteraction
                    ]
                ) {
                    if self.type == .normal {
                        self.thumbView.centerY = self.height * self.value
                        self.trackView.height = currentHeight
                    }else {
                        self.trackView.height = self.height * 0.5 * value
                        if value >= 0 {
                            self.trackView.y = self.height * 0.5
                        }else {
                            self.trackView.y = self.height * 0.5 - self.trackView.height
                        }
                        self.thumbView.centerY = self.height * 0.5 + self.height * 0.5 * value
                    }
                }
            }else {
                if type == .normal {
                    thumbView.centerY = height * value
                    trackView.height = currentHeight
                }else {
                    trackView.height = height * 0.5 * value
                    if value >= 0 {
                        trackView.y = height * 0.5
                    }else {
                        trackView.y = height * 0.5 - trackView.height
                    }
                    thumbView.centerY = height * 0.5 + height * 0.5 * value
                }
            }
        }
    }
    
    @objc func panGestureRecognizerClick(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            let point = pan.location(in: self)
            let rect = CGRect(
                x: thumbView.x - 20,
                y: thumbView.y - 20,
                width: thumbView.width + 40,
                height: thumbView.height + 40
            )
            if !rect.contains(point) {
                pan.isEnabled = false
                pan.isEnabled = true
                return
            }
            if thumbViewFrame.equalTo(.zero) {
                thumbViewFrame = thumbView.frame
            }
            delegate?.sliderView(self, didChangedValue: value, state: .touchDown)
        case .changed:
            let specifiedPoint = pan.translation(in: self)
            var rect = thumbViewFrame
            if UIDevice.isPortrait {
                rect.origin.x += specifiedPoint.x
                if rect.midX < 0 {
                    rect.origin.x = -thumbView.width * 0.5
                }
                if rect.midX > width {
                    rect.origin.x = width - thumbView.width * 0.5
                }
                if type == .normal {
                    value = rect.midX / width
                    if (value == 0 || value == 1) && !didImpactFeedback {
                        let shake = UIImpactFeedbackGenerator(style: .light)
                        shake.prepare()
                        shake.impactOccurred()
                        didImpactFeedback = true
                    }else {
                        if value != 0 && value != 1 {
                            didImpactFeedback = false
                        }
                    }
                    trackView.width = width * value
                }else {
                    let midWidth = width * 0.5
                    if rect.midX >= width * 0.5 {
                        value = (rect.midX - midWidth) / midWidth
                    }else {
                        value = -(1 - rect.midX / midWidth)
                    }
                    if value < 0.015 && value > -0.015 {
                        rect.origin.x = width * 0.5 - rect.width * 0.5
                        value = 0
                    }
                    trackView.width = width * 0.5 + width * 0.5 * value
                    if value >= 0 {
                        trackView.x = width * 0.5
                    }else {
                        trackView.x = width * 0.5 - trackView.width
                    }
                    if ((value < 0.015 && value > -0.015) || value == 1 || value == -1) && !didImpactFeedback {
                        let shake = UIImpactFeedbackGenerator(style: .medium)
                        shake.prepare()
                        shake.impactOccurred()
                        didImpactFeedback = true
                    }else {
                        if (value >= 0.015 || value <= -0.015) && value != 1 && value != -1 {
                            didImpactFeedback = false
                        }
                    }
                }
            }else {
                rect.origin.y += specifiedPoint.y
                if rect.midY < 0 {
                    rect.origin.y = -thumbView.height * 0.5
                }
                if rect.midY > height {
                    rect.origin.y = height - thumbView.height * 0.5
                }
                if type == .normal {
                    value = rect.midY / height
                    if (value == 0 || value == 1) && !didImpactFeedback {
                        let shake = UIImpactFeedbackGenerator(style: .light)
                        shake.prepare()
                        shake.impactOccurred()
                        didImpactFeedback = true
                    }else {
                        if value != 0 && value != 1 {
                            didImpactFeedback = false
                        }
                    }
                    trackView.height = height * value
                }else {
                    let midHeight = height * 0.5
                    if rect.midY >= height * 0.5 {
                        value = (rect.midY - midHeight) / midHeight
                    }else {
                        value = -(1 - rect.midY / midHeight)
                    }
                    if value < 0.015 && value > -0.015 {
                        rect.origin.y = height * 0.5 - rect.height * 0.5
                        value = 0
                    }
                    trackView.height = height * 0.5 + height * 0.5 * value
                    if value >= 0 {
                        trackView.y = height * 0.5
                    }else {
                        trackView.y = height * 0.5 - trackView.height
                    }
                    if ((value < 0.015 && value > -0.015) || value == 1 || value == -1) && !didImpactFeedback {
                        let shake = UIImpactFeedbackGenerator(style: .medium)
                        shake.prepare()
                        shake.impactOccurred()
                        didImpactFeedback = true
                    }else {
                        if (value >= 0.015 || value <= -0.015) && value != 1 && value != -1 {
                            didImpactFeedback = false
                        }
                    }
                }
            }
            thumbView.frame = rect
            delegate?.sliderView(self, didChangedValue: value, state: .changed)
        case .cancelled, .ended, .failed:
            thumbViewFrame = .zero
            delegate?.sliderView(self, didChangedValue: value, state: .touchUpInSide)
        default:
            break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
