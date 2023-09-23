//
//  EditorCanvasView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/16.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit
import PencilKit

@available(iOS 13.0, *)
protocol EditorCanvasViewDelegate: AnyObject {
    func canvasView(beginDraw canvasView: EditorCanvasView)
    func canvasView(endDraw canvasView: EditorCanvasView)
    
    func canvasView(_ canvasView: EditorCanvasView, toolPickerFramesObscuredDidChange toolPicker: PKToolPicker)
}

@available(iOS 13.0, *)
class EditorCanvasView: UIView {
    
    weak var delegate: EditorCanvasViewDelegate?
    var canvasView: PKCanvasView!
    
    private weak var toolPicker: PKToolPicker?
    private var drawingHistory: [PKDrawing] = []
    private var index: Int = -1
    private var drawingCurrentHistory: [PKDrawing] = []
    private var currentIndex: Int = -1
    
    private var rotateIndex: Int = -1
    private var drawingRotateHistory: [PKDrawing] = []
    private var isRotateDrawingData: Bool = false
    
    private var toolWidth: CGFloat = 0
    
    var scale: CGFloat = 1 {
        didSet {
            if !isUserInteractionEnabled {
                return
            }
            if let tool = toolPicker?.selectedTool as? PKInkingTool {
                canvasView.tool = PKInkingTool(tool.inkType, color: tool.color, width: tool.width / scale)
                toolWidth = tool.width / scale
            }
        }
    }
    var exportScale: CGFloat = UIScreen.main.scale
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        canvasView = .init(frame: frame)
        canvasView.contentInsetAdjustmentBehavior = .never
        canvasView.delegate = self
        canvasView.isOpaque = false
        canvasView.backgroundColor = .clear
        canvasView.bouncesZoom = false
        canvasView.automaticallyAdjustsScrollIndicatorInsets = false
        addSubview(canvasView)
        if let window = UIApplication._keyWindow,
           let toolPicker = PKToolPicker.shared(for: window) {
            canvasView.tool = toolPicker.selectedTool
            if let tool = toolPicker.selectedTool as? PKInkingTool {
                toolWidth = tool.width
            }
            toolPicker.addObserver(canvasView)
            toolPicker.addObserver(self)
            self.toolPicker = toolPicker
        }
    }
    
    func startDrawing() -> PKToolPicker? {
        let toolPicker = enterDrawing()
        if isRotateDrawingData {
            drawingHistory = drawingRotateHistory
            index = rotateIndex
            drawingRotateHistory = []
            rotateIndex = -1
            isRotateDrawingData = false
        }
        drawingCurrentHistory = drawingHistory
        currentIndex = index
        return toolPicker
    }
    
    func finishDrawing() {
        if canvasView.drawing.bounds.isEmpty {
            drawingCurrentHistory = []
            currentIndex = -1
        }else {
            if currentIndex < drawingCurrentHistory.count - 1 {
                drawingCurrentHistory.removeSubrange(currentIndex..<drawingCurrentHistory.count)
            }
        }
        quitDrawing()
        drawingHistory = drawingCurrentHistory
        index = currentIndex
    }
    
    func cancelDrawing() {
        undoCurrentAll()
        quitDrawing()
        drawingHistory = drawingCurrentHistory
        index = currentIndex
    }
    
    func enterDrawing() -> PKToolPicker? {
        isUserInteractionEnabled = true
        if let tool = toolPicker?.selectedTool as? PKInkingTool {
            canvasView.tool = PKInkingTool(tool.inkType, color: tool.color, width: tool.width / scale)
            toolWidth = tool.width / scale
        }
        canvasView.becomeFirstResponder()
        toolPicker?.setVisible(true, forFirstResponder: canvasView)
        delegate?.canvasView(beginDraw: self)
        return toolPicker
    }
    
    func quitDrawing() {
        toolPicker?.setVisible(false, forFirstResponder: canvasView)
        toolPicker?.isRulerActive = false
        canvasView.resignFirstResponder()
        isUserInteractionEnabled = false
        delegate?.canvasView(endDraw: self)
    }
    
    var isEmpty: Bool {
        canvasView.drawing.bounds.isEmpty
    }
    
    var image: UIImage {
        canvasView.drawing.image(from: bounds, scale: exportScale)
    }
    
    var data: EditorCanvasData? {
        if isEmpty {
            return nil
        }
        let data = canvasView.drawing.dataRepresentation()
        var historyDatas: [Data] = []
        for history in drawingCurrentHistory {
            historyDatas.append(history.dataRepresentation())
        }
        return .init(data: data, historyDatas: historyDatas, index: currentIndex, size: size)
    }
    
    func setData(data: EditorCanvasData?, viewSize: CGSize, isRotate: Bool = false) {
        guard let data = data else {
            return
        }
        drawingCurrentHistory = []
        currentIndex = -1
        do {
            var draws: [PKDrawing] = []
            for historyData in data.historyDatas {
                var drawing = try PKDrawing(data: historyData)
                if #available(iOS 14.0, *) {
                    var newStrokes: [PKStroke] = []
                    for stroke in drawing.strokes {
                        let path = stroke.path
                        let startIndex = path.startIndex
                        let endIndex = path.endIndex
                        let points = path[startIndex..<endIndex]
                        var newPoints: [PKStrokePoint] = []
                        for point in points {
                            let xScale = point.location.x / data.size.width
                            let yScale = point.location.y / data.size.height
                            let newPoint = PKStrokePoint(
                                location: .init(x: viewSize.width * xScale, y: viewSize.height * yScale),
                                timeOffset: point.timeOffset,
                                size: point.size,
                                opacity: point.opacity,
                                force: point.force,
                                azimuth: point.azimuth,
                                altitude: point.altitude
                            )
                            newPoints.append(newPoint)
                        }
                        let newPath = PKStrokePath(controlPoints: newPoints, creationDate: path.creationDate)
                        let newStroke: PKStroke
                        if #available(iOS 16.0, *) {
                            newStroke = PKStroke(
                                ink: stroke.ink,
                                path: newPath,
                                transform: stroke.transform,
                                mask: stroke.mask,
                                randomSeed: stroke.randomSeed
                            )
                        } else {
                            newStroke = PKStroke(
                                ink: stroke.ink,
                                path: newPath,
                                transform: stroke.transform,
                                mask: stroke.mask
                            )
                        }
                        newStrokes.append(newStroke)
                    }
                    drawing = .init(strokes: newStrokes)
                }
                draws.append(drawing)
            }
            isClear = true
            if #available(iOS 14.0, *) {
                if data.index < draws.count, data.index >= 0 {
                    canvasView.drawing = draws[data.index]
                }
            }else {
                canvasView.drawing = try PKDrawing(data: data.data)
            }
            drawingCurrentHistory = draws
            currentIndex = data.index
            isClear = false
        } catch {
            isClear = false
        }
        if !isUserInteractionEnabled {
            if !isRotate {
                drawingHistory = drawingCurrentHistory
                index = currentIndex
            }else {
                isRotateDrawingData = true
                drawingRotateHistory = drawingCurrentHistory
                rotateIndex = currentIndex
            }
        }
    }
    
    var isCanUndo: Bool {
        currentIndex >= 0
    }
    
    var isCanRedo: Bool {
        currentIndex < drawingCurrentHistory.count - 1
    }
    
    var isClear: Bool = false
    
    func redo() {
        if currentIndex < drawingCurrentHistory.count - 1 {
            currentIndex += 1
            isClear = true
            let nextDrawing = drawingCurrentHistory[currentIndex]
            if #available(iOS 14.0, *) {
                canvasView.drawing = .init(strokes: nextDrawing.strokes)
            } else {
                canvasView.drawing = .init().appending(nextDrawing)
            }
            isClear = false
            delegate?.canvasView(endDraw: self)
        }
    }
    
    func undo() {
        if currentIndex >= 0 {
            currentIndex -= 1
            isClear = true
            if currentIndex >= 0 {
                let previousDrawing = drawingCurrentHistory[currentIndex]
                if #available(iOS 14.0, *) {
                    canvasView.drawing = .init(strokes: previousDrawing.strokes)
                } else {
                    canvasView.drawing = .init().appending(previousDrawing)
                }
            }else {
                canvasView.drawing = .init()
            }
            isClear = false
        }
    }
    
    func undoCurrentAll() {
        drawingCurrentHistory = drawingHistory
        currentIndex = drawingCurrentHistory.count - 1
        isClear = true
        if let drawing = drawingCurrentHistory.last {
            if #available(iOS 14.0, *) {
                canvasView.drawing = .init(strokes: drawing.strokes)
            } else {
                canvasView.drawing = .init().appending(drawing)
            }
        }else {
            canvasView.drawing = .init()
        }
        isClear = false
    }
    
    func undoAll() {
        if currentIndex >= 0 {
            currentIndex = -1
            isClear = true
            canvasView.drawing = .init()
            isClear = false
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        canvasView.frame = bounds
        canvasView.contentSize = size
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let toolPicker = toolPicker {
            if toolPicker.isVisible {
                toolPicker.setVisible(false, forFirstResponder: canvasView)
            }
            toolPicker.removeObserver(canvasView)
            toolPicker.removeObserver(self)
            self.toolPicker = nil
        }
    }
}

@available(iOS 13.0, *)
extension EditorCanvasView: PKCanvasViewDelegate {
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if !isClear {
            if currentIndex >= 0, !drawingCurrentHistory.isEmpty, currentIndex < drawingCurrentHistory.count - 1 {
                drawingCurrentHistory.removeSubrange(currentIndex+1..<drawingCurrentHistory.count)
                currentIndex = drawingCurrentHistory.count - 1
            }
            let newDrawing = canvasView.drawing
            if !drawingCurrentHistory.contains(newDrawing) {
                drawingCurrentHistory.append(newDrawing)
                currentIndex = drawingCurrentHistory.count - 1
            }
        }
        delegate?.canvasView(endDraw: self)
    }
    
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        if let tool = canvasView.tool as? PKInkingTool, tool.width != toolWidth {
            canvasView.tool = PKInkingTool(tool.inkType, color: tool.color, width: tool.width / scale)
            toolWidth = tool.width / scale
        }
        delegate?.canvasView(beginDraw: self)
    }

    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        
    }
}

@available(iOS 13.0, *)
extension EditorCanvasView: PKToolPickerObserver {
    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
        if let tool = toolPicker.selectedTool as? PKInkingTool {
            canvasView.tool = PKInkingTool(tool.inkType, color: tool.color, width: tool.width / scale)
            toolWidth = tool.width / scale
        }
    }
    
    func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
        delegate?.canvasView(self, toolPickerFramesObscuredDidChange: toolPicker)
    }
    
    func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
        delegate?.canvasView(self, toolPickerFramesObscuredDidChange: toolPicker)
    }
}

struct EditorCanvasData: Codable {
    let data: Data
    let historyDatas: [Data]
    let index: Int
    let size: CGSize
}
