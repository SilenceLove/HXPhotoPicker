//
//  PhotoEditorContentView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/26.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

protocol PhotoEditorContentViewDelegate: AnyObject {
    func contentView(drawViewBeganDraw contentView: PhotoEditorContentView)
    func contentView(drawViewEndDraw contentView: PhotoEditorContentView)
    func contentView(_ contentView: PhotoEditorContentView, updateStickerText item: EditorStickerItem)
    func contentView(didRemoveAudio contentView: PhotoEditorContentView)
}

class PhotoEditorContentView: UIView {
    
    enum EditType {
        case image
        case video
    }
    
    weak var delegate: PhotoEditorContentViewDelegate?
    
    var itemViewMoveToCenter: ((CGRect) -> Bool)?
    
    var stickerMinScale: ((CGSize) -> CGFloat)?
    
    var stickerMaxScale: ((CGSize) -> CGFloat)?
    
    lazy var videoView: VideoEditorPlayerView = {
        let videoView = VideoEditorPlayerView()
        return videoView
    }()
    
    lazy var imageView: UIImageView = {
        var imageView: UIImageView
        #if canImport(Kingfisher)
        imageView = AnimatedImageView.init()
        #else
        imageView = UIImageView.init()
        #endif
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    var image: UIImage? { imageView.image }
    var zoomScale: CGFloat = 1 {
        didSet {
            drawView.scale = zoomScale
            mosaicView.scale = zoomScale
            stickerView.scale = zoomScale
        }
    }
    lazy var drawView: PhotoEditorDrawView = {
        let drawView = PhotoEditorDrawView.init(frame: .zero)
        drawView.delegate = self
        return drawView
    }()
    lazy var mosaicView: PhotoEditorMosaicView = {
        let view = PhotoEditorMosaicView(mosaicConfig: mosaicConfig)
        view.delegate = self
        return view
    }()
    lazy var stickerView: EditorStickerView = {
        let view = EditorStickerView(frame: .zero)
        view.delegate = self
        return view
    }()
    lazy var longPressGesture: UILongPressGestureRecognizer = {
        let long = UILongPressGestureRecognizer(
            target: self,
            action: #selector(longPressGestureRecognizerClick(_:))
        )
        long.minimumPressDuration = 0.2
        long.isEnabled = false
        return long
    }()
    let mosaicConfig: PhotoEditorConfiguration.Mosaic
    let editType: EditType
    init(
        editType: EditType,
        mosaicConfig: PhotoEditorConfiguration.Mosaic
    ) {
        self.mosaicConfig = mosaicConfig
        self.editType = editType
        super.init(frame: .zero)
        if editType == .image {
            addSubview(imageView)
            addSubview(mosaicView)
            
        }else {
            addSubview(videoView)
        }
        addSubview(drawView)
        addSubview(stickerView)
        addGestureRecognizer(longPressGesture)
    }
    var originalImage: UIImage?
    var tempImage: UIImage?
    @objc
    func longPressGestureRecognizerClick(
        _ longPressGesture: UILongPressGestureRecognizer
    ) {
        switch longPressGesture.state {
        case .began:
            if editType == .image {
                tempImage = imageView.image
                if let image = originalImage {
                    setImage(image)
                }
            }else {
                videoView.isLookOriginal = true
            }
        case .ended, .cancelled, .failed:
            if editType == .image {
                if let image = tempImage {
                    setImage(image)
                }
                tempImage = nil
            }else {
                videoView.isLookOriginal = false
            }
        default:
            break
        }
    }
    func setMosaicOriginalImage(_ image: UIImage?) {
        mosaicView.originalImage = image
    }
    func setImage(_ image: UIImage) {
        if editType == .video {
            videoView.coverImageView.image = image
            return
        }
        #if canImport(Kingfisher)
        let view = imageView as! AnimatedImageView
        view.image = image
        #else
        imageView.image = image
        #endif
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if editType == .image {
            imageView.frame = bounds
            mosaicView.frame = bounds
        }else {
            if videoView.superview == self {
                videoView.frame = bounds
            }
        }
        drawView.frame = bounds
        stickerView.frame = bounds
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PhotoEditorContentView: PhotoEditorDrawViewDelegate {
    func drawView(beganDraw drawView: PhotoEditorDrawView) {
        delegate?.contentView(drawViewBeganDraw: self)
    }
    func drawView(endDraw drawView: PhotoEditorDrawView) {
        delegate?.contentView(drawViewEndDraw: self)
    }
}
extension PhotoEditorContentView: EditorStickerViewDelegate {
    func stickerView(_ stickerView: EditorStickerView, updateStickerText item: EditorStickerItem) {
        delegate?.contentView(self, updateStickerText: item)
    }
    
    func stickerView(touchBegan stickerView: EditorStickerView) {
        delegate?.contentView(drawViewBeganDraw: self)
    }
    func stickerView(touchEnded stickerView: EditorStickerView) {
        delegate?.contentView(drawViewEndDraw: self)
    }
    func stickerView(_ stickerView: EditorStickerView, moveToCenter rect: CGRect) -> Bool {
        if let moveToCenter = itemViewMoveToCenter?(rect) {
            return moveToCenter
        }
        return false
    }
    
    func stickerView(_ stickerView: EditorStickerView, minScale itemSize: CGSize) -> CGFloat {
        if let minScale = stickerMinScale?(itemSize) {
            return minScale
        }
        return 0.2
    }
    
    func stickerView(_ stickerView: EditorStickerView, maxScale itemSize: CGSize) -> CGFloat {
        if let maxScale = stickerMaxScale?(itemSize) {
            return maxScale
        }
        return 5
    }
    func stickerView(didRemoveAudio stickerView: EditorStickerView) {
        delegate?.contentView(didRemoveAudio: self)
    }
}
extension PhotoEditorContentView: PhotoEditorMosaicViewDelegate {
    func mosaicView(_ mosaicView: PhotoEditorMosaicView, splashColor atPoint: CGPoint) -> UIColor? {
        imageView.color(for: atPoint)
    }
    
    func mosaicView(beganDraw mosaicView: PhotoEditorMosaicView) {
        delegate?.contentView(drawViewBeganDraw: self)
    }
    
    func mosaicView(endDraw mosaicView: PhotoEditorMosaicView) {
        delegate?.contentView(drawViewEndDraw: self)
    }
}
