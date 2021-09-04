//
//  EditorChartletPreviewView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/3.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

class EditorChartletPreviewView: UIView {
    lazy var imageView: ImageView = {
        let view = ImageView()
        return view
    }()
    lazy var bgLayer: CAShapeLayer = {
        let bgLayer = CAShapeLayer()
        bgLayer.fillColor = UIColor.white.cgColor
        bgLayer.strokeColor = UIColor.white.cgColor
        bgLayer.contentsScale = UIScreen.main.scale
        bgLayer.path = bgLayerPath()
        return bgLayer
    }()
    let touchCenter: CGPoint
    let touchViewSize: CGSize
    var image: UIImage?
    var triangleMove: CGPoint = .zero
    var upslope: Bool = true
    var isHorizontal: Bool = false
    var horizontalType: Int = 0
    init(
        image: UIImage,
        touch center: CGPoint,
        touchView viewSize: CGSize
    ) {
        self.image = image
        touchCenter = center
        touchViewSize = viewSize
        super.init(frame: .zero)
        setupFrame(imageSize: image.size)
        layer.addSublayer(bgLayer)
        imageView.image = image
        addSubview(imageView)
    }
    #if canImport(Kingfisher)
    init(
        imageURL: URL,
        editorType: EditorController.EditorType,
        touch center: CGPoint,
        touchView viewSize: CGSize
    ) {
        image = nil
        touchCenter = center
        touchViewSize = viewSize
        super.init(frame: .zero)
        setupFrame(imageSize: CGSize(width: 200, height: 200))
        layer.addSublayer(bgLayer)
        addSubview(imageView)
        imageView.my.kf.indicatorType = .activity
        let options: KingfisherOptionsInfo
        if imageURL.isGif && editorType == .video {
            options = []
        }else {
            let processor = DownsamplingImageProcessor(
                size: CGSize(
                    width: width * 2,
                    height: height * 2
                )
            )
            options = [
                .processor(processor),
                .backgroundDecode
            ]
        }
        imageView.my.kf.setImage(
            with: imageURL,
            options: options
        ) { [weak self] result in
            switch result {
            case .success(let imageResult):
                self?.image = imageResult.image
                self?.setupFrame(
                    imageSize: imageResult.image.size
                )
                self?.bgLayer.path = self?.bgLayerPath()
            case .failure(_):
                break
            }
        }
    }
    #endif
    func setupFrame(imageSize: CGSize) {
        let viewSize = touchViewSize
        let center = touchCenter
        let imageScale = imageSize.height / imageSize.width
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let maxWidth = (!UIDevice.isPad && UIDevice.isPortrait) ?
            screenWidth * 0.5 :
            screenWidth * 0.25
        let maxHeight = screenHeight * 0.5
        var width = imageSize.width
        var height = imageSize.height
        if width > maxWidth {
            width = maxWidth
            height = width * imageScale
        }
        if height > maxHeight {
            height = maxHeight
        }
        width += 10
        height += 20
        var x: CGFloat = center.x - width * 0.5
        if x + width + UIDevice.rightMargin + 10 > screenWidth {
            x = center.x + viewSize.width * 0.5 - width
        }else if x < UIDevice.leftMargin + 10 {
            x = center.x - viewSize.width * 0.5
        }
        var y: CGFloat = center.y - viewSize.height * 0.5 - height
        if y < UIDevice.topMargin {
            y = center.y + viewSize.height * 0.5
            triangleMove = CGPoint(x: center.x - x, y: 0)
            upslope = false
            if y + height > screenHeight {
                width += 10
                height -= 10
                isHorizontal = true
                horizontalType = 0
                y = center.y - height * 0.5
                x = center.x - viewSize.width * 0.5 - width
                triangleMove = CGPoint(x: width, y: height * 0.5)
                if x < UIDevice.leftMargin + 10 {
                    x = center.x + viewSize.width * 0.5
                    triangleMove = CGPoint(x: 0, y: height * 0.5)
                    horizontalType = 1
                }
            }
        }else {
            triangleMove = CGPoint(
                x: center.x - x,
                y: center.y - viewSize.height * 0.5 - y
            )
            upslope = true
        }
        frame = CGRect(
            x: x, y: y,
            width: width, height: height
        )
    }
    
    func bgLayerPath() -> CGPath? {
        if image == nil {
            return nil
        }
        let rect: CGRect
        let trianglePath = UIBezierPath()
        trianglePath.move(to: triangleMove)
        if !isHorizontal {
            rect = CGRect(
                x: 0,
                y: upslope ? 0 : 10,
                width: width,
                height: height - 10
            )
            if upslope {
                trianglePath.addLine(
                    to: CGPoint(x: triangleMove.x - 10, y: triangleMove.y - 10)
                )
                trianglePath.addLine(
                    to: CGPoint(x: triangleMove.x + 10, y: triangleMove.y - 10)
                )
            }else {
                trianglePath.addLine(
                    to: CGPoint(x: triangleMove.x - 10, y: triangleMove.y + 10)
                )
                trianglePath.addLine(
                    to: CGPoint(x: triangleMove.x + 10, y: triangleMove.y + 10)
                )
            }
        }else {
            rect = CGRect(
                x: horizontalType == 0 ? 0 : 10,
                y: 0,
                width: width - 10,
                height: height
            )
            if horizontalType == 0 {
                trianglePath.addLine(
                    to: CGPoint(x: triangleMove.x - 10, y: triangleMove.y - 10)
                )
                trianglePath.addLine(
                    to: CGPoint(x: triangleMove.x - 10, y: triangleMove.y + 10)
                )
            }else {
                trianglePath.addLine(
                    to: CGPoint(x: triangleMove.x + 10, y: triangleMove.y - 10)
                )
                trianglePath.addLine(
                    to: CGPoint(x: triangleMove.x + 10, y: triangleMove.y + 10)
                )
            }
        }
        
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 5)
        path.append(trianglePath)
        return path.cgPath
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bgLayer.frame = bounds
        if !isHorizontal {
            imageView.frame = CGRect(
                x: 5,
                y: upslope ? 5 : 15,
                width: width - 10,
                height: height - 20
            )
        }else {
            imageView.frame = CGRect(
                x: horizontalType == 0 ? 5 : 15,
                y: 5,
                width: width - 10,
                height: height - 20
            )
        }
    }
}
