//
//  PhotoEditorMosaicView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/2.
//

import UIKit
import CoreImage
import CoreGraphics

protocol PhotoEditorMosaicViewDelegate: AnyObject {
    func mosaicView(_  mosaicView: PhotoEditorMosaicView, splashColor atPoint: CGPoint) -> UIColor?
    func mosaicView(beganDraw mosaicView: PhotoEditorMosaicView)
    func mosaicView(endDraw mosaicView: PhotoEditorMosaicView)
}

class PhotoEditorMosaicView: UIView, UIGestureRecognizerDelegate {
    enum MosaicType: Int, Codable {
        case mosaic
        case smear
    }
    
    weak var delegate: PhotoEditorMosaicViewDelegate?
    var originalImage: UIImage? {
        didSet {
            mosaicContentLayer.contents = originalImage?.cgImage
        }
    }
    var mosaicContentLayer: CALayer = {
        let mosaicContentLayer = CALayer()
        return mosaicContentLayer
    }()
    var mosaicPathLayer: CAShapeLayer = {
        let mosaicPathLayer = CAShapeLayer()
        mosaicPathLayer.strokeColor = UIColor.white.cgColor
        mosaicPathLayer.fillColor = nil
        mosaicPathLayer.lineCap = .round
        mosaicPathLayer.lineJoin = .round
        return mosaicPathLayer
    }()
    
    var scale: CGFloat = 1
    let mosaicLineWidth: CGFloat
    let imageWidth: CGFloat
    var type: MosaicType = .mosaic
    var isTouching: Bool = false
    var isBegan: Bool = false
    var count: Int { mosaicPaths.count }
    var enabled: Bool = false {
        didSet { isUserInteractionEnabled = enabled }
    }
    var canUndo: Bool { !mosaicPaths.isEmpty }
    
    init(mosaicConfig: PhotoEditorConfiguration.Mosaic) {
        mosaicLineWidth = mosaicConfig.mosaiclineWidth
        imageWidth = mosaicConfig.smearWidth
        super.init(frame: .zero)
        layer.addSublayer(mosaicContentLayer)
        layer.addSublayer(mosaicPathLayer)
        mosaicPathLayer.lineWidth = mosaicLineWidth / scale
        mosaicContentLayer.mask = mosaicPathLayer
        clipsToBounds = true
        isUserInteractionEnabled = false
        let pan = PhotoPanGestureRecognizer.init(target: self, action: #selector(panGesureRecognizerClick(panGR:)))
        pan.delegate = self
        addGestureRecognizer(pan)
    }
    
    var mosaicPaths: [PhotoEditorMosaicPath] = []
    var mosaicPoints: [CGPoint] = []
    var smearLayers: [PhotoEditorMosaicSmearLayer] = []
    var smearAngles: [CGFloat] = []
    var smearColors: [UIColor] = []
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer.isKind(of: UITapGestureRecognizer.self) &&
            otherGestureRecognizer.view is PhotoEditorView {
            return true
        }
        return false
    }
    @objc func panGesureRecognizerClick(panGR: UIPanGestureRecognizer) {
        switch panGR.state {
        case .began:
            let point = panGR.location(in: self)
            isTouching = false
            isBegan = true
            if type == .mosaic {
                let lineWidth = mosaicLineWidth / scale
                let path = PhotoEditorMosaicPath(type: .mosaic, width: lineWidth)
                path.move(to: point)
                if let mosaicPath = mosaicPathLayer.path {
                    let bezierPath = PhotoEditorMosaicPath(cgPath: mosaicPath, type: .mosaic)
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
                    let path = PhotoEditorMosaicPath(cgPath: cgPath, type: .mosaic)
                    path.addLine(to: point)
                    mosaicPoints.append(CGPoint(x: point.x / width, y: point.y / height))
                    mosaicPathLayer.path = path.cgPath
                }
            }else if type == .smear {
                let image = "hx_editor_mosaic_brush_image".image?.withRenderingMode(.alwaysTemplate)
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
                let pointX = pointXArray[Int(arc4random() % 6)]
                let pointY = pointYArray[Int(arc4random() % 6)]
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
                        let path = PhotoEditorMosaicPath(type: .smear, width: imageWidth)
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
                    delegate?.mosaicView(beganDraw: self)
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
    ) -> PhotoEditorMosaicSmearLayer? {
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
            let data = PhotoEditorMosaicSmearLayerData(rect: CGRect(origin: .zero, size: rect.size), color: color)
            let smearLayer = PhotoEditorMosaicSmearLayer.init(data: data)
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
    func getMosaicData() -> [PhotoEditorMosaicData] {
        var mosaicDatas: [PhotoEditorMosaicData] = []
        for path in mosaicPaths {
            let lineWidth = path.type == .mosaic ? path.lineWidth : path.width
            let  mosaicData = PhotoEditorMosaicData.init(type: path.type,
                                                         points: path.points,
                                                         colors: path.smearColors,
                                                         lineWidth: lineWidth,
                                                         angles: path.angles)
            mosaicDatas.append(mosaicData)
        }
        return mosaicDatas
    }
    func setMosaicData(mosaicDatas: [PhotoEditorMosaicData], viewSize: CGSize) {
        let mosaicPath = UIBezierPath()
        for mosaicData in mosaicDatas {
            if mosaicData.type == .mosaic {
                let path = PhotoEditorMosaicPath(type: .mosaic, width: mosaicData.lineWidth)
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
                let image = "hx_editor_mosaic_brush_image".image?.withRenderingMode(.alwaysTemplate)
                let path = PhotoEditorMosaicPath(type: .smear, width: mosaicData.lineWidth)
                var layers: [PhotoEditorMosaicSmearLayer] = []
                for (index, point) in mosaicData.points.enumerated() {
                    let color = mosaicData.colors[index]
                    let newPoint = CGPoint(x: point.x * viewSize.width, y: point.y * viewSize.height)
                    if let colorLayer = createSmearLayer(at: newPoint,
                                                         image: image,
                                                         imageWidth: mosaicData.lineWidth,
                                                         angle: mosaicData.angles[index],
                                                         smearColor: color) {
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
class PhotoEditorMosaicPath: PhotoEditorBrushPath {
    let type: PhotoEditorMosaicView.MosaicType
    let width: CGFloat
    var smearLayers: [PhotoEditorMosaicSmearLayer] = []
    var smearColors: [UIColor] = []
    var angles: [CGFloat] = []
    init(type: PhotoEditorMosaicView.MosaicType, width: CGFloat) {
        self.type = type
        self.width = width
        super.init()
    }
    convenience init(cgPath: CGPath, type: PhotoEditorMosaicView.MosaicType) {
        self.init(type: type, width: 0)
        self.cgPath = cgPath
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
struct PhotoEditorMosaicSmearLayerData {
    let rect: CGRect
    let color: UIColor
}
class PhotoEditorMosaicSmearLayer: CALayer {
    let data: PhotoEditorMosaicSmearLayerData
    init(data: PhotoEditorMosaicSmearLayerData) {
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
        if let image = "hx_editor_mosaic_brush_image".image?.withRenderingMode(
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

struct PhotoEditorMosaicData {
    let type: PhotoEditorMosaicView.MosaicType
    let points: [CGPoint]
    let colors: [UIColor]
    let lineWidth: CGFloat
    let angles: [CGFloat]
}
extension PhotoEditorMosaicData: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case points
        case colors
        case lineWidth
        case angles
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(PhotoEditorMosaicView.MosaicType.self, forKey: .type)
        points = try container.decode([CGPoint].self, forKey: .points)
        let colorDatas = try container.decode(Data.self, forKey: .colors)
        colors = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorDatas) as! [UIColor]
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
