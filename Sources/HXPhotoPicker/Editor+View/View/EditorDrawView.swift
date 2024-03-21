//
//  EditorDrawView.swift
//  Example
//
//  Created by Slience on 2022/11/8.
//

import UIKit

protocol EditorDrawViewDelegate: AnyObject {
    func drawView(beginDraw drawView: EditorDrawView)
    func drawView(endDraw drawView: EditorDrawView)
}

class EditorDrawView: UIView {
    weak var delegate: EditorDrawViewDelegate?
     
    var linePaths: [BrushPath] = []
    var points: [CGPoint] = []
    var shapeLayers: [CAShapeLayer] = []
    
    var lineColor: UIColor = .white
    var lineWidth: CGFloat = 5.0
    var isEnabled: Bool = false {
        didSet { isUserInteractionEnabled = isEnabled }
    }
    var scale: CGFloat = 1
    var count: Int { linePaths.count }
    var isCanUndo: Bool { !linePaths.isEmpty }
    var isDrawing: Bool {
        (!isUserInteractionEnabled || !isEnabled) ? false : isTouching
    }
    var isTouching: Bool = false
    var isBegan: Bool = false
    
    var isVideoMark: Bool = false
    
    let drawPathQueue = DispatchQueue(label: "com.path.hxqueue")
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        isUserInteractionEnabled = false
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesureRecognizerClick(panGR:)))
        pan.delegate = self
        addGestureRecognizer(pan)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesureRecognizerClick(pinchGR:)))
        pinch.delegate = self
        addGestureRecognizer(pinch)
    }
    
    @objc
    func pinchGesureRecognizerClick(pinchGR: UIPanGestureRecognizer) {
        
    }
    
    @objc
    func panGesureRecognizerClick(panGR: UIPanGestureRecognizer) {
        isVideoMark = false
        switch panGR.state {
        case .began:
            points.removeAll()
            let point = panGR.location(in: self)
            isTouching = false
            let path = BrushPath()
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
                delegate?.drawView(beginDraw: self)
                isTouching = true
                
                points.append(CGPoint(x: point.x / width, y: point.y / height))
                
                smoothedPath(points: points, curveSegmentCount: 10) { drawPath in
                    DispatchQueue.main.async {
                        path?.cgPath = drawPath.cgPath
                        let shapeLayer = self.shapeLayers.last
                        shapeLayer?.path = path?.cgPath
                    }
                }
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
    
    func createdShapeLayer(path: BrushPath) -> CAShapeLayer {
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
        isVideoMark = false
    }
    
    func undoAll() {
        shapeLayers.forEach { (shapeLayer) in
            shapeLayer.removeFromSuperlayer()
        }
        linePaths.removeAll()
        shapeLayers.removeAll()
        isVideoMark = false
    }
    
    func getBrushData() -> [BrushInfo] {
        var brushsData: [BrushInfo] = []
        for path in linePaths {
            if let color = path.color {
                let brushData = BrushInfo(
                    color: color,
                    points: path.points,
                    lineWidth: path.lineWidth / width
                )
                brushsData.append(brushData)
            }
        }
        return brushsData
    }
    
    func setBrushData(_ brushsData: [BrushInfo], viewSize: CGSize) {
        for brushData in brushsData {
            let path = BrushPath()
            path.lineWidth = brushData.lineWidth * viewSize.width
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.points = brushData.points
            path.color = brushData.color
            linePaths.append(path)
            let shapeLayer = createdShapeLayer(path: path)
            layer.addSublayer(shapeLayer)
            shapeLayers.append(shapeLayer)
            
            smoothedPath(points: points, curveSegmentCount: 10) { drawPath in
                DispatchQueue.main.async {
                    path.cgPath = drawPath.cgPath
                    shapeLayer.path = path.cgPath
                }
            }
            
        }
    }
    
    private func smoothedPath(points copyPoints:[CGPoint], curveSegmentCount: Int, completion: @escaping ((UIBezierPath) -> Void)) {
        let points = copyPoints.map { poi in
            CGPoint(x: poi.x*width, y: poi.y*height)
        }
        drawPathQueue.async {
            // 创建路径对象
            let smoothedPath = UIBezierPath();
            guard points.count > 0 else {
                completion(smoothedPath)
                return
            }
            let first = points[0]
            smoothedPath.move(to: first)
            if points.count < 4 {
                //简单地连接所有点，如果没有足够的点来形成一个样条曲线
                for point in points {
                    smoothedPath.addLine(to: point)
                }
                
            } else {
                let pointArray = EditorDrawTool.generatePoints(from: points, segmentsPerCurve: curveSegmentCount)
                for point in pointArray {
                    smoothedPath.addLine(to: point)
                }
            }
            completion(smoothedPath)
        }
    }
}

extension EditorDrawView: UIGestureRecognizerDelegate {
    
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

extension EditorDrawView {
    
    struct BrushInfo {
        let color: UIColor
        let points: [CGPoint]
        let lineWidth: CGFloat
    }

    class BrushPath: UIBezierPath {
        var color: UIColor?
        var points: [CGPoint] = []
    }

}

extension EditorDrawView.BrushInfo: Codable {
    
    enum CodingKeys: String, CodingKey {
        case color
        case points
        case lineWidth
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let colorData = try container.decode(Data.self, forKey: .color)
        if #available(iOS 11.0, *) {
            color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)!
        }else {
            color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as! UIColor
        }
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
