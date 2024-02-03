//
//  EditorMosaicView.swift
//  Example
//
//  Created by Slience on 2022/11/8.
//

import UIKit
import CoreImage
import CoreGraphics

protocol EditorMosaicViewDelegate: AnyObject {
    func mosaicView(_  mosaicView: EditorMosaicView, splashColor atPoint: CGPoint) -> UIColor?
    func mosaicView(beginDraw mosaicView: EditorMosaicView)
    func mosaicView(endDraw mosaicView: EditorMosaicView)
}

class EditorMosaicView: UIView {
    weak var delegate: EditorMosaicViewDelegate?
    var originalImage: UIImage? {
        didSet {
            mosaicContentLayer.contents = originalImage?.cgImage
        }
    }
    var originalCGImage: CGImage? {
        didSet {
            mosaicContentLayer.contents = originalCGImage
        }
    }
    private var mosaicContentLayer: CALayer!
    private var mosaicPathLayer: CAShapeLayer!
    
    var isEnabled: Bool = false {
        didSet { isUserInteractionEnabled = isEnabled }
    }
    var isCanUndo: Bool { !mosaicPaths.isEmpty }
    var mosaicLineWidth: CGFloat = 25
    var imageWidth: CGFloat = 30
    var type: EditorMosaicType = .mosaic
    
    var scale: CGFloat = 1
    var isTouching: Bool = false
    var isBegan: Bool = false
    var count: Int { mosaicPaths.count }
    
    init() {
        super.init(frame: .zero)
        initViews()
        layer.addSublayer(mosaicContentLayer)
        layer.addSublayer(mosaicPathLayer)
        mosaicPathLayer.lineWidth = mosaicLineWidth / scale
        mosaicContentLayer.mask = mosaicPathLayer
        clipsToBounds = true
        isUserInteractionEnabled = false
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panGesureRecognizerClick(panGR:)))
        pan.delegate = self
        addGestureRecognizer(pan)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesureRecognizerClick(pinchGR:)))
        pinch.delegate = self
        addGestureRecognizer(pinch)
    }
    
    func initViews() {
        mosaicContentLayer = CALayer()
        mosaicPathLayer = CAShapeLayer()
        mosaicPathLayer.strokeColor = UIColor.white.cgColor
        mosaicPathLayer.fillColor = nil
        mosaicPathLayer.lineCap = .round
        mosaicPathLayer.lineJoin = .round
    }
    
    var mosaicPaths: [MosaicPath] = []
    var mosaicPoints: [CGPoint] = []
    var smearLayers: [SmearLayer] = []
    var smearAngles: [CGFloat] = []
    var smearColors: [UIColor] = []
    
    @objc
    func pinchGesureRecognizerClick(pinchGR: UIPanGestureRecognizer) {
        
    }
    
    @objc func panGesureRecognizerClick(panGR: UIPanGestureRecognizer) {
        switch panGR.state {
        case .began:
            let point = panGR.location(in: self)
            isTouching = false
            isBegan = true
            if type == .mosaic {
                let lineWidth = mosaicLineWidth / scale
                let path = MosaicPath(type: .mosaic, width: lineWidth)
                path.move(to: point)
                if let mosaicPath = mosaicPathLayer.path {
                    let bezierPath = MosaicPath(cgPath: mosaicPath, type: .mosaic)
                    bezierPath.move(to: point)
                    mosaicPathLayer.path = bezierPath.cgPath
                }else {
                    mosaicPathLayer.path = path.cgPath
                }
                mosaicPaths.append(path)
                mosaicPoints.append(CGPoint(x: point.x / width, y: point.y / height))
            }
        case .changed:
            let point = panGR.location(in: self)
            var didChanged = false
            if type == .mosaic {
                if let cgPath = mosaicPathLayer.path,
                   let mosaicPath = mosaicPaths.last,
                   !mosaicPath.currentPoint.equalTo(point) {
                    didChanged = true
                    mosaicPath.addLine(to: point)
                    let path = MosaicPath(cgPath: cgPath, type: .mosaic)
                    path.addLine(to: point)
                    mosaicPoints.append(CGPoint(x: point.x / width, y: point.y / height))
                    mosaicPathLayer.path = path.cgPath
                }
            }else if type == .smear {
                let image: UIImage? = .imageResource.editor.mosaic.smearMask.image?.withRenderingMode(.alwaysTemplate)
                let pointXArray = [
                    point.x - 4,
                    point.x + 4,
                    point.x - 3,
                    point.x + 3,
                    point.x - 2,
                    point.x + 2,
                    point.x
                ]
                let pointYArray = [
                    point.y - 4,
                    point.y + 4,
                    point.y - 3,
                    point.y + 3,
                    point.y - 2,
                    point.y + 2,
                    point.y
                ]
                let pointX = pointXArray[Int.random(in: 0..<6)]
                let pointY = pointYArray[Int.random(in: 0..<6)]
                let newPoint = CGPoint(x: pointX, y: pointY)
                if let lastPoint = mosaicPoints.last,
                   (abs(newPoint.x - lastPoint.x * width) <= 2 || abs(newPoint.y - lastPoint.y * width) <= 2) {
                    return
                }
                var angle: CGFloat = 0
                if let startPoint = mosaicPoints.last {
                    angle = getAngleBetweenPoint(
                        startPoint: CGPoint(
                            x: startPoint.x * width,
                            y: startPoint.y * height
                        ),
                        endPoint: newPoint
                    )
                }
                let imageWidth = imageWidth / scale
                if let colorLayer = createSmearLayer(at: newPoint, image: image, imageWidth: imageWidth, angle: angle) {
                    if mosaicPoints.isEmpty {
                        let path = MosaicPath(type: .smear, width: imageWidth)
                        mosaicPaths.append(path)
                    }
                    mosaicPoints.append(CGPoint(x: newPoint.x / width, y: newPoint.y / height))
                    didChanged = true
                    layer.addSublayer(colorLayer)
                    smearLayers.append(colorLayer)
                    smearColors.append(colorLayer.data.color)
                    smearAngles.append(angle)
                }
            }
            if didChanged {
                if isBegan {
                    delegate?.mosaicView(beginDraw: self)
                }
                isTouching = true
                isBegan = false
            }
        case .failed, .cancelled, .ended:
            if isTouching {
                delegate?.mosaicView(endDraw: self)
                let path = mosaicPaths.last
                path?.points = mosaicPoints
                if type == .smear {
                    path?.smearLayers = smearLayers
                    path?.angles = smearAngles
                    path?.smearColors = smearColors
                }
            }else {
                undo()
            }
            smearAngles.removeAll()
            smearLayers.removeAll()
            smearColors.removeAll()
            mosaicPoints.removeAll()
            isTouching = false
        default:
            break
        }
    }
    func createSmearLayer(
        at point: CGPoint,
        image: UIImage?,
        imageWidth: CGFloat,
        angle: CGFloat,
        smearColor: UIColor? = nil
    ) -> SmearLayer? {
        guard let colorImage = image else {
            return nil
        }
        let imageHeight = colorImage.height * (imageWidth / colorImage.width)
        let rect = CGRect(
            x: point.x - imageWidth * 0.5,
            y: point.y - imageHeight * 0.5,
            width: imageWidth,
            height: imageHeight
        )
        var color = smearColor
        if color == nil {
            color = delegate?.mosaicView(self, splashColor: point)
        }
        if let color = color {
            let data = SmearLayerData(rect: CGRect(origin: .zero, size: rect.size), color: color)
            let smearLayer = SmearLayer(data: data)
            smearLayer.frame = rect
            smearLayer.transform = CATransform3DMakeRotation(angle * CGFloat.pi / 180.0, 0, 0, 1)
            smearLayer.setNeedsDisplay()
            return smearLayer
        }
        return nil
    }
    func getAngleBetweenPoint(startPoint: CGPoint, endPoint: CGPoint) -> CGFloat {
        let p2 = startPoint
        let p3 = endPoint
        let p1 = CGPoint(x: p3.x, y: p2.y)
        if (p1.x == p2.x && p2.x == p3.x) || (p1.y == p2.x && p2.x == p3.x) {
            return 0
        }
        let a = abs(p1.x - p2.x)
        let b = abs(p1.y - p2.y)
        let c = abs(p3.x - p2.x)
        let d = abs(p3.y - p2.y)
        
        if (a < 1.0 && b < 1.0) || (c < 1.0 && d < 1.0) {
            return 0
        }
        let e = a * c + b * d
        let f = sqrt(a * a + b * b)
        let g = sqrt(c * c + d * d)
        let r = CGFloat(acos(e / (f * g)))
        let angle = (180 * r / CGFloat.pi)
        if p3.x < p2.x {
            if p3.y < p2.y {
                return 270 + angle
            }else {
                return 270 - angle
            }
        }else {
            if p3.y < p2.y {
                return 90 - angle
            }else {
                return 90 + angle
            }
        }
    }
    func undo() {
        if let lastPath = mosaicPaths.last {
            mosaicPaths.removeLast()
            if lastPath.type == .mosaic {
                let mosaicPath = UIBezierPath()
                for path in mosaicPaths {
                    mosaicPath.append(path)
                }
                if mosaicPath.isEmpty {
                    mosaicPathLayer.path = nil
                }else {
                    mosaicPathLayer.path = mosaicPath.cgPath
                }
            }else if lastPath.type == .smear {
                for subLayer in lastPath.smearLayers {
                    subLayer.removeFromSuperlayer()
                }
            }
        }
    }
    func undoAll() {
        for path in mosaicPaths {
            for subLayer in path.smearLayers {
                subLayer.removeFromSuperlayer()
            }
        }
        mosaicPaths.removeAll()
        mosaicPathLayer.path = nil
    }
    func getMosaicData() -> [MosaicData] {
        var mosaicDatas: [MosaicData] = []
        for path in mosaicPaths {
            let lineWidth = path.type == .mosaic ? path.lineWidth : path.width
            let  mosaicData = MosaicData(
                type: path.type,
                points: path.points,
                colors: path.smearColors,
                lineWidth: lineWidth / width,
                angles: path.angles
            )
            mosaicDatas.append(mosaicData)
        }
        return mosaicDatas
    }
    func setMosaicData(mosaicDatas: [MosaicData], viewSize: CGSize) {
        let mosaicPath = UIBezierPath()
        for mosaicData in mosaicDatas {
            if mosaicData.type == .mosaic {
                let path = MosaicPath(
                    type: .mosaic,
                    width: mosaicData.lineWidth * viewSize.width
                )
                for (index, point) in mosaicData.points.enumerated() {
                    let newPoint = CGPoint(x: point.x * viewSize.width, y: point.y * viewSize.height)
                    if index == 0 {
                        path.move(to: newPoint)
                    }else {
                        path.addLine(to: newPoint)
                    }
                }
                path.points = mosaicData.points
                mosaicPath.append(path)
                mosaicPaths.append(path)
            }else if mosaicData.type == .smear {
                let image: UIImage? = .imageResource.editor.mosaic.smearMask.image?.withRenderingMode(.alwaysTemplate)
                let path = MosaicPath(
                    type: .smear,
                    width: mosaicData.lineWidth * viewSize.width
                )
                var layers: [SmearLayer] = []
                for (index, point) in mosaicData.points.enumerated() {
                    let color = mosaicData.colors[index]
                    let newPoint = CGPoint(x: point.x * viewSize.width, y: point.y * viewSize.height)
                    if let colorLayer = createSmearLayer(
                        at: newPoint,
                        image: image,
                        imageWidth: mosaicData.lineWidth * viewSize.width,
                        angle: mosaicData.angles[index],
                        smearColor: color
                    ) {
                        layer.addSublayer(colorLayer)
                        layers.append(colorLayer)
                    }
                }
                path.points = mosaicData.points
                path.smearLayers = layers
                path.angles = mosaicData.angles
                path.smearColors = mosaicData.colors
                mosaicPaths.append(path)
            }
        }
        if mosaicPath.isEmpty {
            mosaicPathLayer.path = nil
        }else {
            mosaicPathLayer.path = mosaicPath.cgPath
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mosaicContentLayer.frame = bounds
        mosaicPathLayer.frame = bounds
        CATransaction.commit()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorMosaicView {
    
    class MosaicPath: EditorDrawView.BrushPath {
        let type: EditorMosaicType
        let width: CGFloat
        var smearLayers: [SmearLayer] = []
        var smearColors: [UIColor] = []
        var angles: [CGFloat] = []
        
        init(type: EditorMosaicType, width: CGFloat) {
            self.type = type
            self.width = width
            super.init()
        }
        
        convenience init(cgPath: CGPath, type: EditorMosaicType) {
            self.init(type: type, width: 0)
            self.cgPath = cgPath
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    struct SmearLayerData {
        let rect: CGRect
        let color: UIColor
    }
    
    class SmearLayer: CALayer {
        let data: SmearLayerData
        init(data: SmearLayerData) {
            self.data = data
            super.init()
        }
        
        override init(layer: Any) {
            data = .init(rect: .zero, color: .clear)
            super.init(layer: layer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        override func draw(in ctx: CGContext) {
            ctx.saveGState()
            if let image = UIImage.imageResource.editor.mosaic.smearMask.image?.withRenderingMode(
                .alwaysTemplate
            ), let cgImage = image.cgImage {
                let colorRef = CGColorSpaceCreateDeviceRGB()
                let contextRef = CGContext(data: nil,
                                           width: Int(image.width),
                                           height: Int(image.height),
                                           bitsPerComponent: 8,
                                           bytesPerRow: Int(image.width * 4),
                                           space: colorRef,
                                           bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
                let imageRect = CGRect(origin: .zero, size: image.size)
                contextRef?.clip(to: imageRect, mask: cgImage)
                contextRef?.setFillColor(data.color.cgColor)
                contextRef?.fill(imageRect)
                if let imageRef = contextRef?.makeImage() {
                    ctx.draw(imageRef, in: data.rect)
                }
            }
            ctx.restoreGState()
        }
    }

    struct MosaicData {
        let type: EditorMosaicType
        let points: [CGPoint]
        let colors: [UIColor]
        let lineWidth: CGFloat
        let angles: [CGFloat]
    }
}
extension EditorMosaicView.MosaicData: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case points
        case colors
        case lineWidth
        case angles
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(EditorMosaicType.self, forKey: .type)
        points = try container.decode([CGPoint].self, forKey: .points)
        let colorDatas = try container.decode(Data.self, forKey: .colors)
        if #available(iOS 11.0, *) {
            colors = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [UIColor.self], from: colorDatas) as! [UIColor]
        }else {
            colors = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorDatas) as! [UIColor]
        }
        lineWidth = try container.decode(CGFloat.self, forKey: .lineWidth)
        angles = try container.decode([CGFloat].self, forKey: .angles)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(points, forKey: .points)
        if #available(iOS 11.0, *) {
            let colorDatas = try NSKeyedArchiver.archivedData(withRootObject: colors, requiringSecureCoding: false)
            try container.encode(colorDatas, forKey: .colors)
        } else {
            // Fallback on earlier versions
            let colorDatas = NSKeyedArchiver.archivedData(withRootObject: colors)
            try container.encode(colorDatas, forKey: .colors)
        }
        try container.encode(lineWidth, forKey: .lineWidth)
        try container.encode(angles, forKey: .angles)
    }
}
extension EditorMosaicView: UIGestureRecognizerDelegate {
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        isEnabled
    }
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer {
            return false
        }
        if gestureRecognizer is UIPanGestureRecognizer {
            return false
        }
        return true
    }
}
