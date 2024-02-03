//
//  EditorVideoControlMaskView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/13.
//

import UIKit

protocol EditorVideoControlMaskViewDelegate: AnyObject {
    func frameMaskView(leftValidRectDidChanged frameMaskView: EditorVideoControlMaskView)
    func frameMaskView(leftValidRectEndChanged frameMaskView: EditorVideoControlMaskView)
    func frameMaskView(rightValidRectDidChanged frameMaskView: EditorVideoControlMaskView)
    func frameMaskView(rightValidRectEndChanged frameMaskView: EditorVideoControlMaskView)
}

class EditorVideoControlMaskView: UIView {
    let controlWidth: CGFloat = 18
    
    weak var delegate: EditorVideoControlMaskViewDelegate?
    
    private var maskLayer: CAShapeLayer!
    private var topView: UIView!
    private var bottomView: UIView!
    private var leftImageView: UIImageView!
    private var leftControl: UIView!
    private var rightImageView: UIImageView!
    private var rightControl: UIView!
    private var mask_View: UIView!
    
    var validRect: CGRect = .zero {
        didSet {
            leftControl.frame = CGRect(x: validRect.minX - controlWidth, y: 0, width: controlWidth, height: height)
            leftImageView.center = .init(x: leftControl.width / 2, y: leftControl.height / 2)
            rightControl.frame = CGRect(x: validRect.maxX, y: 0, width: controlWidth, height: height)
            rightImageView.center = .init(x: rightControl.width / 2, y: rightControl.height / 2)
            topView.frame = .init(x: leftControl.frame.maxX, y: 0, width: validRect.width, height: 4)
            bottomView.frame = .init(
                x: leftControl.frame.maxX,
                y: leftControl.frame.maxY - 4,
                width: validRect.width,
                height: 4
            )
            drawMaskLayer()
            guard #available(iOS 11.0, *) else {
                leftControl.cornersRound(radius: 4, corner: [.topLeft, .bottomLeft])
                rightControl.cornersRound(radius: 4, corner: [.topRight, .bottomRight])
                return
            }
        }
    }
    var isShowFrame: Bool = false
    var minWidth: CGFloat = 0
    
    var arrowNormalColor: UIColor = .white
    var arrowHighlightedColor: UIColor = .black
    var frameHighlightedColor: UIColor = "#FDCC00".color
    
    init() {
        super.init(frame: .zero)
        initViews()
    }
    
    private func initViews() {
        maskLayer = CAShapeLayer()
        maskLayer.contentsScale = UIScreen._scale
        mask_View = UIView()
        mask_View.backgroundColor = .black.withAlphaComponent(0.5)
        mask_View.layer.mask = maskLayer
        addSubview(mask_View)
        
        topView = UIView()
        topView.backgroundColor = .clear
        addSubview(topView)
        
        bottomView = UIView()
        bottomView.backgroundColor = .clear
        addSubview(bottomView)
        
        leftImageView = UIImageView(image: .imageResource.editor.video.leftArrow.image?.withRenderingMode(.alwaysTemplate))
        leftImageView.size = leftImageView.image?.size ?? .zero
        leftImageView.tintColor = arrowNormalColor
        leftControl = UIView()
        leftControl.tag = 0
        if #available(iOS 11.0, *) {
            leftControl.cornersRound(radius: 4, corner: [.topLeft, .bottomLeft])
        }
        leftControl.addSubview(leftImageView)
        let leftControlPanGR = PhotoPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction(panGR:)))
        leftControl.addGestureRecognizer(leftControlPanGR)
        addSubview(leftControl)
        
        rightImageView = UIImageView(image: .imageResource.editor.video.rightArrow.image?.withRenderingMode(.alwaysTemplate))
        rightImageView.size = rightImageView.image?.size ?? .zero
        rightImageView.tintColor = arrowNormalColor
        rightControl = UIView()
        rightControl.tag = 1
        rightControl.addSubview(rightImageView)
        if #available(iOS 11.0, *) {
            rightControl.cornersRound(radius: 4, corner: [.topRight, .bottomRight])
        }
        let rightControlPanGR = PhotoPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction(panGR:)))
        rightControl.addGestureRecognizer(rightControlPanGR)
        addSubview(rightControl)
    }
    
    private func drawMaskLayer() {
        let maskPath = UIBezierPath(rect: bounds)
        maskPath.append(
            UIBezierPath(
                rect: CGRect(
                    x: validRect.minX,
                    y: validRect.minY + 4,
                    width: validRect.width,
                    height: validRect.height - 8
                )
            ).reversing()
        )
        maskLayer.path = maskPath.cgPath
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        mask_View.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var leftBeginRect: CGRect = .zero
    var rightBeginRect: CGRect = .zero
    @objc func panGestureRecognizerAction(panGR: UIPanGestureRecognizer) {
        let point = panGR.translation(in: self)
        switch panGR.state {
        case .began:
            leftBeginRect = leftControl.frame
            rightBeginRect = rightControl.frame
            switch panGR.view?.tag {
            case 0:
                delegate?.frameMaskView(leftValidRectDidChanged: self)
            case 1:
                delegate?.frameMaskView(rightValidRectDidChanged: self)
            default:
                break
            }
            updateFrameView()
        case .changed:
            var leftRect = leftBeginRect
            var rightRect = rightBeginRect
            switch panGR.view?.tag {
            case 0:
                leftRect.origin.x += point.x
                if leftRect.origin.x < 0 {
                    leftRect.origin.x = 0
                }
                if rightRect.origin.x - leftRect.maxX <= minWidth {
                    leftRect.origin.x = rightRect.origin.x - minWidth - leftRect.width
                }
                validRect = .init(
                    x: leftRect.maxX,
                    y: validRect.minY,
                    width: rightRect.origin.x - leftRect.maxX,
                    height: leftRect.height
                )
                delegate?.frameMaskView(leftValidRectDidChanged: self)
            case 1:
                rightRect.origin.x += point.x
                if rightRect.maxX > width {
                    rightRect.origin.x = width - rightRect.width
                }
                if rightRect.origin.x - leftRect.maxX <= minWidth {
                    rightRect.origin.x = leftRect.maxX + minWidth
                }
                validRect = .init(
                    x: leftRect.maxX,
                    y: validRect.minY,
                    width: rightRect.origin.x - leftRect.maxX,
                    height: leftRect.height
                )
                delegate?.frameMaskView(rightValidRectDidChanged: self)
            default:
                break
            }
            updateFrameView()
        case .ended, .failed, .cancelled:
            let leftRect = leftControl.frame
            let rightRect = rightControl.frame
            validRect = .init(
                x: leftRect.maxX,
                y: validRect.minY,
                width: rightRect.origin.x - leftRect.maxX,
                height: leftRect.height
            )
            switch panGR.view?.tag {
            case 0:
                delegate?.frameMaskView(leftValidRectEndChanged: self)
            case 1:
                delegate?.frameMaskView(rightValidRectEndChanged: self)
            default:
                break
            }
            updateFrameView()
        default:
            break
        }
    }
    
    func updateFrameView() {
        if rightControl.x - leftControl.frame.maxX < width - controlWidth * 2 || isShowFrame {
            UIView.animate(withDuration: 0.2) {
                self.topView.backgroundColor = self.frameHighlightedColor
                self.bottomView.backgroundColor = self.frameHighlightedColor
                self.leftControl.backgroundColor = self.frameHighlightedColor
                self.rightControl.backgroundColor = self.frameHighlightedColor
                self.leftImageView.tintColor = self.arrowHighlightedColor
                self.rightImageView.tintColor = self.arrowHighlightedColor
                self.mask_View.backgroundColor = .black.withAlphaComponent(0.5)
            }
        }else {
            UIView.animate(withDuration: 0.2) {
                self.topView.backgroundColor = .clear
                self.bottomView.backgroundColor = .clear
                self.leftControl.backgroundColor = .clear
                self.rightControl.backgroundColor = .clear
                self.leftImageView.tintColor = self.arrowNormalColor
                self.rightImageView.tintColor = self.arrowNormalColor
                self.mask_View.backgroundColor = .clear
            }
        }
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var leftRect = leftControl.frame
        leftRect.origin.x -= controlWidth
        leftRect.size.width += controlWidth
        var rightRect = rightControl.frame
        rightRect.size.width += controlWidth
        if leftRect.contains(point) {
            return leftControl
        }
        if rightRect.contains(point) {
            return rightControl
        }
        return nil
    }
}
