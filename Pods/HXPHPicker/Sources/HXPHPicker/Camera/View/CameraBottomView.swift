//
//  CameraBottomView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit

protocol CameraBottomViewDelegate: AnyObject {
    func bottomView(beganTakePictures bottomView: CameraBottomView)
    func bottomView(beganRecording bottomView: CameraBottomView)
    func bottomView(endRecording bottomView: CameraBottomView)
    func bottomView(longPressDidBegan bottomView: CameraBottomView)
    func bottomView(_ bottomView: CameraBottomView, longPressDidChanged scale: CGFloat)
    func bottomView(longPressDidEnded bottomView: CameraBottomView)
    func bottomView(didBackButton bottomView: CameraBottomView)
    func bottomView(_ bottomView: CameraBottomView, didChangeTakeType takeType: CameraBottomViewTakeType)
}

class CameraBottomView: UIView {
    weak var delegate: CameraBottomViewDelegate?
    lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage("hx_camera_down_back".image, for: .normal)
        button.addTarget(self, action: #selector(didBackButtonClick), for: .touchUpInside)
        button.size = button.currentImage?.size ?? .zero
        button.tintColor = .white
        button.imageView?.tintColor = .white
        return button
    }()
    lazy var maskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(false)
        return layer
    }()
    lazy var takeMaskLayer: CAShapeLayer = {
        let takeLayer = CAShapeLayer()
        takeLayer.contentsScale = UIScreen.main.scale
        takeLayer.fillColor = UIColor.clear.cgColor
        takeLayer.lineWidth = 5
        takeLayer.strokeColor = color.cgColor
        takeLayer.isHidden = true
        return takeLayer
    }()
    lazy var takeBgView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .extraLight)
        let view = UIVisualEffectView(effect: effect)
        view.size = CGSize(width: 80, height: 80)
        view.layer.cornerRadius = view.width * 0.5
        view.layer.masksToBounds = true
        view.layer.addSublayer(takeMaskLayer)
        return view
    }()
    lazy var takeView: UIView = {
        let view = UIView()
        view.size = CGSize(width: 60, height: 60)
        view.backgroundColor = .white
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = view.width * 0.5
        view.layer.masksToBounds = true
        return view
    }()
    lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(tapGestureRecognizerClick(tap:))
        )
        tapGesture.isEnabled = false
        return tapGesture
    }()
    lazy var longPress: UILongPressGestureRecognizer = {
        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(longPressGestureRecognizerClick(longPress:))
        )
        longPress.isEnabled = false
        return longPress
    }()
    lazy var tipLb: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.mediumPingFang(ofSize: 14)
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.shadowColor = UIColor.black.withAlphaComponent(0.6)
        label.shadowOffset = CGSize(width: 0, height: 1)
        return label
    }()
    lazy var typeView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    lazy var photoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("照片".localized, for: .normal)
        button.setTitleColor(.white.withAlphaComponent(0.5), for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.addTarget(self, action: #selector(didPhotoButtonClick), for: .touchUpInside)
        return button
    }()
    @objc
    func didPhotoButtonClick() {
        if isTaking || isRecording {
            return
        }
        photoButton.isSelected = true
        videoButton.isSelected = false
        takeType = .photo
        delegate?.bottomView(self, didChangeTakeType: takeType)
    }
    lazy var videoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("视频".localized, for: .normal)
        button.setTitleColor(.white.withAlphaComponent(0.5), for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.addTarget(self, action: #selector(didVideoButtonClick), for: .touchUpInside)
        return button
    }()
    @objc
    func didVideoButtonClick() {
        if isTaking || isRecording {
            return
        }
        videoButton.isSelected = true
        photoButton.isSelected = false
        takeType = .video
        delegate?.bottomView(self, didChangeTakeType: takeType)
    }
    lazy var videoTimeLb: UILabel = {
        let label = UILabel()
        label.alpha = 0
        label.text = "00:00"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.mediumPingFang(ofSize: 16)
        label.numberOfLines = 0
        label.shadowColor = UIColor.black.withAlphaComponent(0.4)
        label.shadowOffset = CGSize(width: 0, height: 1)
        label.isUserInteractionEnabled = false
        return label
    }()
    var isGestureEnable: Bool = false {
        didSet {
            tapGesture.isEnabled = isGestureEnable
            longPress.isEnabled = isGestureEnable
        }
    }
    var isTaking: Bool = false
    var isRecording: Bool = false
    var longPressBeganPoint: CGPoint = .zero
    let color: UIColor
    let takePhotoMode: CameraConfiguration.TakePhotoMode
    var captureType: CameraController.CaptureType?
    var takeType: CameraBottomViewTakeType = .photo
    init(
        tintColor: UIColor,
        takePhotoMode: CameraConfiguration.TakePhotoMode
    ) {
        self.color = tintColor
        self.takePhotoMode = takePhotoMode
        super.init(frame: .zero)
        layer.addSublayer(maskLayer)
        addSubview(backButton)
        addSubview(takeBgView)
        addSubview(takeView)
        addSubview(tipLb)
        if takePhotoMode == .click {
            addSubview(typeView)
        }
        setTakeMaskLayerPath()
    }
    
    @objc
    func didBackButtonClick() {
        delegate?.bottomView(didBackButton: self)
    }
    
    func addGesture(for type: CameraController.CaptureType) {
        captureType = type
        switch type {
        case .photo:
            takeBgView.addGestureRecognizer(tapGesture)
            tipLb.text = "轻触拍照".localized
            if takePhotoMode == .click {
                photoButton.isSelected = true
                takeType = .photo
            }
        case .video:
            if takePhotoMode == .press {
                takeBgView.addGestureRecognizer(longPress)
                tipLb.text = "按住摄像".localized
            }else {
                takeMaskLayer.lineWidth = 10
                takeMaskLayer.strokeEnd = 1
                takeMaskLayer.isHidden = false
                takeBgView.layer.mask = takeMaskLayer
                takeBgView.addGestureRecognizer(tapGesture)
                videoButton.isSelected = true
                tipLb.text = "点击摄像".localized
                addSubview(videoTimeLb)
                takeType = .video
            }
        case .all:
            takeBgView.addGestureRecognizer(tapGesture)
            if takePhotoMode == .press {
                takeBgView.addGestureRecognizer(longPress)
                tipLb.text = "轻触拍照，按住摄像".localized
            }else {
                takeMaskLayer.lineWidth = 10
                takeMaskLayer.strokeEnd = 1
                takeMaskLayer.isHidden = false
                takeBgView.layer.mask = takeMaskLayer
                typeView.addSubview(photoButton)
                typeView.addSubview(videoButton)
                photoButton.contentHorizontalAlignment = .right
                videoButton.contentHorizontalAlignment = .left
                addSubview(videoTimeLb)
                layoutSubviews()
                didPhotoButtonClick()
            }
        }
    }
    
    @objc
    func tapGestureRecognizerClick(tap: UITapGestureRecognizer) {
        if takePhotoMode == .click {
            if photoButton.isSelected {
                if isTaking {
                    return
                }
                isTaking = true
                backButton.isUserInteractionEnabled = false
                UIView.animate(withDuration: 0.15) {
                    self.takeView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                } completion: { _ in
                    self.delegate?.bottomView(beganTakePictures: self)
                    UIView.animate(withDuration: 0.15) {
                        self.takeView.transform = .identity
                    } completion: { _ in
                        self.isTaking = false
                        self.backButton.isUserInteractionEnabled = true
                    }
                }
                return
            }
            if videoButton.isSelected {
                if isRecording {
                    delegate?.bottomView(longPressDidEnded: self)
                    backButton.isUserInteractionEnabled = true
                    stopRecord()
                    return
                }
                isRecording = true
                backButton.isUserInteractionEnabled = false
                delegate?.bottomView(longPressDidBegan: self)
                UIView.animate(withDuration: 0.25) {
                    self.takeView.backgroundColor = self.color
                    self.takeView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                } completion: { _ in
                    if self.isRecording {
                        self.delegate?.bottomView(beganRecording: self)
                    }
                }
            }
            return
        }
        if isTaking || isRecording {
            return
        }
        longPress.isEnabled = false
        isTaking = true
        backButton.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.15) {
            self.takeView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        } completion: { _ in
            self.delegate?.bottomView(beganTakePictures: self)
            UIView.animate(withDuration: 0.15) {
                self.takeView.transform = .identity
            } completion: { _ in
                self.isTaking = false
                self.backButton.isUserInteractionEnabled = true
                self.longPress.isEnabled = true
            }
        }
    }
    
    @objc
    func longPressGestureRecognizerClick(longPress: UILongPressGestureRecognizer) {
        switch longPress.state {
        case .began:
            if isRecording || isTaking {
                return
            }
            longPressBeganPoint = longPress.location(in: self)
            tapGesture.isEnabled = false
            isRecording = true
            backButton.isUserInteractionEnabled = false
            delegate?.bottomView(longPressDidBegan: self)
            UIView.animate(withDuration: 0.25) {
                self.takeBgView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.takeView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            } completion: { _ in
                if self.isRecording {
                    self.delegate?.bottomView(beganRecording: self)
                }
            }
        case .changed:
            let point = longPress.location(in: self)
            let marginY = point.y + 20
            if longPressBeganPoint.y <= marginY {
                return
            }
            let max: CGFloat = 100
            let distance = min(longPressBeganPoint.y - marginY, max)
            let scale = distance / max
            delegate?.bottomView(self, longPressDidChanged: scale)
        case .ended, .cancelled, .failed:
            delegate?.bottomView(longPressDidEnded: self)
            backButton.isUserInteractionEnabled = true
            if isTaking {
                return
            }
            stopRecord()
        default:
            break
        }
    }
    
    func stopRecord() {
        tapGesture.isEnabled = true
        if takePhotoMode == .press {
            takeMaskLayer.removeAllAnimations()
            takeMaskLayer.isHidden = true
        }else {
            UIView.animate(withDuration: 0.2) {
                self.videoTimeLb.alpha = 0
                self.typeView.alpha = 1
            } completion: { _ in
                self.videoTimeLb.text = "00:00"
            }
        }
        if !isRecording { return }
        isRecording = false
        delegate?.bottomView(endRecording: self)
        UIView.animate(withDuration: 0.25) {
            self.takeBgView.transform = .identity
            self.takeView.transform = .identity
            self.takeView.backgroundColor = .white
        }
    }
    func updateVideoTime(_ time: TimeInterval) {
        if takePhotoMode == .click {
            videoTimeLb.text = PhotoTools.transformVideoDurationToString(duration: time)
        }
    }
    func startTakeMaskLayerPath(duration: TimeInterval) {
        if takePhotoMode == .click {
            UIView.animate(withDuration: 0.2) {
                self.typeView.alpha = 0
                self.videoTimeLb.alpha = 1
            }
            return
        }
        if !isRecording { return }
        takeMaskLayer.isHidden = false
        let maskAnimation = PhotoTools.getBasicAnimation(
            "strokeEnd",
            0,
            1,
            duration
        )
        maskAnimation.isRemovedOnCompletion = false
//        maskAnimation.delegate = self
        takeMaskLayer.add(maskAnimation, forKey: "takeMaskLayer")
    }
    func setTakeMaskLayerPath() {
        let path = UIBezierPath(
            arcCenter: CGPoint(
                x: takeBgView.width * 0.5,
                y: takeBgView.height * 0.5
            ),
            radius: takeBgView.width * 0.5 - 2.5,
            startAngle: -CGFloat.pi * 0.5,
            endAngle: CGFloat.pi * 1.5,
            clockwise: true
        )
        takeMaskLayer.path = path.cgPath
    }
    func hiddenTip() {
        UIView.animate(withDuration: 0.25, delay: 1.5) {
            self.tipLb.alpha = 0
        }
    }
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if typeView.frame.contains(point) && takePhotoMode == .click {
            return true
        }
        return super.point(inside: point, with: event)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.frame = CGRect(x: 0, y: -20, width: width, height: height + 20)
        backButton.x = width * 0.5 - 120
        backButton.centerY = height * 0.5
        takeBgView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        takeView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        tipLb.frame = CGRect(
            x: UIDevice.leftMargin + 15,
            y: takeBgView.y - 40,
            width: width - UIDevice.leftMargin - UIDevice.rightMargin - 30,
            height: 30
        )
        if takePhotoMode == .click {
            guard let captureType = captureType else {
                return
            }
            typeView.frame = CGRect(
                x: UIDevice.leftMargin + 15,
                y: takeBgView.y - 40,
                width: width - UIDevice.leftMargin - UIDevice.rightMargin - 30,
                height: 30
            )
            switch captureType {
            case .photo:
                photoButton.frame = typeView.bounds
            case .video:
                videoButton.frame = typeView.bounds
                videoTimeLb.frame = typeView.frame
                maskLayer.frame = CGRect(x: 0, y: -30, width: width, height: height + 30)
            case .all:
                maskLayer.frame = CGRect(x: 0, y: -40, width: width, height: height + 40)
                photoButton.frame = .init(x: typeView.width * 0.5 - 110, y: 0, width: 100, height: typeView.height)
                videoButton.frame = .init(x: typeView.width * 0.5 + 10, y: 0, width: 100, height: typeView.height)
                videoTimeLb.frame = typeView.frame
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public enum CameraBottomViewTakeType {
    case photo
    case video
}
//    extension CameraBottomView: CAAnimationDelegate {
//        func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
//            if anim == takeMaskLayer.animation(forKey: "takeMaskLayer") && flag {
//                delegate?.bottomView(endRecording: self)
//                stopRecord()
//            }else {
//                takeMaskLayer.removeAllAnimations()
//            }
//        }
//    }
