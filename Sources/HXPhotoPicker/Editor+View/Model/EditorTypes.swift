//
//  EditorTypes.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/13.
//

import UIKit
import AVFoundation

public extension EditorView {
    
    enum State {
        /// 正常状态
        case normal
        /// 编辑状态
        case edit
    }
    
    enum MaskType: Equatable {
        /// 毛玻璃效果
        case blurEffect(style: UIBlurEffect.Style)
        /// 自定义颜色
        case customColor(color: UIColor)
    }
}

public enum EditorContentViewType {
    case unknown
    case image
    case video
}

public enum EditorDarwType: Int, Codable {
    case normal
    case canvas
}

public enum EditorMosaicType: Int, Codable {
    /// 马赛克
    case mosaic
    /// 涂抹
    case smear
}

public class EditorStickersItemBaseView: UIView {
    public var isSelected: Bool = false
    
    public var text: EditorStickerText? {
        item.text
    }
    
    public var audio: EditorStickerAudio? {
        item.audio
    }
    
    var item: EditorStickerItem!
}

public enum EditorError: LocalizedError, CustomStringConvertible {
    
    public enum `Type` {
        case exportFailed
        case removeFile
        case writeFileFailed
        case blankFrame
        case dataAcquisitionFailed
        case cropImageFailed
        case inputIsEmpty
        case compressionFailed
        case typeError
        case nothingProcess
        case cancelled
    }
    
    case error(type: `Type`, message: String)
}

public extension EditorError {
    
    var isCancel: Bool {
        switch self {
        case let .error(type, _):
            return type == .cancelled
        }
    }
    
    var errorDescription: String? {
        switch self {
        case let .error(_, message):
            return message
        }
    }
    
    var description: String {
        errorDescription ?? "nil"
    }
}

extension EditorMaskView {
    
    enum `Type` {
        case frame
        case mask
        case customMask
    }
}

extension EditorControlView {
    struct Factor: Codable {
        var fixedRatio: Bool = false
        var aspectRatio: CGSize = .zero
    }
}

extension EditorView {
    enum Operate {
        case startEdit((() -> Void)?)
        case finishEdit((() -> Void)?)
        case cancelEdit((() -> Void)?)
        case rotate(CGFloat, (() -> Void)?)
        case rotateLeft((() -> Void)?)
        case rotateRight((() -> Void)?)
        case mirrorHorizontally((() -> Void)?)
        case mirrorVertically((() -> Void)?)
        case reset((() -> Void)?)
        case setRoundMask(Bool)
        case setData(EditAdjustmentData)
    }
}

extension EditorAdjusterView {
    
    enum ImageOrientation {
        case up
        case left
        case right
        case down
    }
    
    struct AdjustedFactor {
        var angle: CGFloat = 0
        var zoomScale: CGFloat = 1
        var contentOffset: CGPoint = .zero
        var contentInset: UIEdgeInsets = .zero
        var maskRect: CGRect = .zero
        var transform: CGAffineTransform = .identity
        var rotateTransform: CGAffineTransform = .identity
        var mirrorTransform: CGAffineTransform = .identity
        var maskImage: UIImage?
        
        var contentOffsetScale: CGPoint = .zero
        var min_zoom_scale: CGFloat = 1
        var isRoundMask: Bool = false
    }
    
}

enum EditorVideoOrientation: Int {
    case portrait = 1
    case portraitUpsideDown = 2
    case landscapeRight = 3
    case landscapeLeft = 4
}
