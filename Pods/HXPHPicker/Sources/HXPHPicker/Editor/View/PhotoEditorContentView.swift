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
}

class PhotoEditorContentView: UIView {
    
    weak var delegate: PhotoEditorContentViewDelegate?
    
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
        }
    }
    
    lazy var drawView: PhotoEditorDrawView = {
        let drawView = PhotoEditorDrawView.init(frame: .zero)
        drawView.delegate = self
        return drawView
    }()
    
    init() {
        super.init(frame: .zero)
        addSubview(imageView)
        addSubview(drawView)
    }
    
    
    func setImage(_ image: UIImage) {
        #if canImport(Kingfisher)
        let view = imageView as! AnimatedImageView
        view.image = image
        #else
        imageView.image = image
        #endif
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        drawView.frame = bounds
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
