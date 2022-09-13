//
//  PhotoEditorDrawView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/11.
//

import UIKit

protocol PhotoEditorDrawViewDelegate: AnyObject {
    func drawView(beganDraw drawView: PhotoEditorDrawView)
    func drawView(endDraw drawView: PhotoEditorDrawView)
}

class PhotoEditorDrawView: UIView, UIGestureRecognizerDelegate {
    
    weak var delegate: PhotoEditorDrawViewDelegate?
     
    var linePaths: [PhotoEditorBrushPath] = []
    var points: [CGPoint] = []
    var shapeLayers: [CAShapeLayer] = []
    
    var lineColor: UIColor = .white
    var lineWidth: CGFloat = 5.0
    var enabled: Bool = false {
        didSet { isUserInteractionEnabled = enabled }
    }
    var scale: CGFloat = 1
    var count: Int { linePaths.count }
    var canUndo: Bool { !linePaths.isEmpty }
    var isDrawing: Bool { (!isUserInteractionEnabled || !enabled) ? false : isTouching }
    var isTouching: Bool = false
    var isBegan: Bool = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        isUserInteractionEnabled = false
        let pan = PhotoPanGestureRecognizer.init(target: self, action: #selector(panGesureRecognizerClick(panGR:)))
        pan.delegate = self
        addGestureRecognizer(pan)
    }
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
            points.removeAll()
            let point = panGR.location(in: self)
            isTouching = false
            let path = PhotoEditorBrushPath()
            path.lineWidth = lineWidth / scale
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.move(to: point)
            path.color = lineColor
            linePaths.append(path)
            points.append(CGPoint(x: point.x / width, y: point.y / height))
            let shapeLayer = createdShapeLayer(path: path)
            layer.addSublayer(shapeLayer)
            shapeLayers.append(shapeLayer)
        case .changed:
            let point = panGR.location(in: self)
            let path = linePaths.last
            if path?.currentPoint.equalTo(point) == false {
                delegate?.drawView(beganDraw: self)
                isTouching = true
                
                path?.addLine(to: point)
                points.append(CGPoint(x: point.x / width, y: point.y / height))
                let shapeLayer = shapeLayers.last
                shapeLayer?.path = path?.cgPath
            }
        case .failed, .cancelled, .ended:
            if isTouching {
                let path = linePaths.last
                path?.points = points
                delegate?.drawView(endDraw: self)
            }else {
                undo()
            }
            points.removeAll()
            isTouching = false
        default:
            break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createdShapeLayer(path: PhotoEditorBrushPath) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.backgroundColor = UIColor.clear.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        shapeLayer.strokeColor = path.color?.cgColor
        shapeLayer.lineWidth = path.lineWidth
        return shapeLayer
    }
    
    func undo() {
        if shapeLayers.isEmpty {
            return
        }
        shapeLayers.last?.removeFromSuperlayer()
        shapeLayers.removeLast()
        linePaths.removeLast()
    }
    
    func emptyCanvas() {
        shapeLayers.forEach { (shapeLayer) in
            shapeLayer.removeFromSuperlayer()
        }
        linePaths.removeAll()
        shapeLayers.removeAll()
    }
    
    func getBrushData() -> [PhotoEditorBrushData] {
        var brushsData: [PhotoEditorBrushData] = []
        for path in linePaths {
            if let color = path.color {
                let brushData = PhotoEditorBrushData(
                    color: color,
                    points: path.points,
                    lineWidth: path.lineWidth
                )
                brushsData.append(brushData)
            }
        }
        return brushsData
    }
    
    func setBrushData(_ brushsData: [PhotoEditorBrushData], viewSize: CGSize) {
        for brushData in brushsData {
            let path = PhotoEditorBrushPath()
            path.lineWidth = brushData.lineWidth
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.points = brushData.points
            for (index, point) in brushData.points.enumerated() {
                let cPoint = CGPoint(x: point.x * viewSize.width, y: point.y * viewSize.height)
                if index == 0 {
                    path.move(to: cPoint)
                }else {
                    path.addLine(to: cPoint)
                }
            }
            path.color = brushData.color
            linePaths.append(path)
            let shapeLayer = createdShapeLayer(path: path)
            layer.addSublayer(shapeLayer)
            shapeLayers.append(shapeLayer)
        }
    }
}

struct PhotoEditorBrushData {
    let color: UIColor
    let points: [CGPoint]
    let lineWidth: CGFloat
}

extension PhotoEditorBrushData: Codable {
    enum CodingKeys: String, CodingKey {
        case color
        case points
        case lineWidth
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let colorData = try container.decode(Data.self, forKey: .color)
        color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as! UIColor
        points = try container.decode([CGPoint].self, forKey: .points)
        lineWidth = try container.decode(CGFloat.self, forKey: .lineWidth)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if #available(iOS 11.0, *) {
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            try container.encode(colorData, forKey: .color)
        } else {
            // Fallback on earlier versions
            let colorData = NSKeyedArchiver.archivedData(withRootObject: color)
            try container.encode(colorData, forKey: .color)
        }
        try container.encode(points, forKey: .points)
        try container.encode(lineWidth, forKey: .lineWidth)
    }
}

class PhotoEditorBrushPath: UIBezierPath {
    var color: UIColor?
    var points: [CGPoint] = []
}
