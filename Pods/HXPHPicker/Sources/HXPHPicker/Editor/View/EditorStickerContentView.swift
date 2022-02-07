//
//  EditorStickerContentView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/20.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

struct EditorStickerText {
    let image: UIImage
    let text: String
    let textColor: UIColor
    let showBackgroud: Bool
}

struct EditorStickerItem {
    let image: UIImage
    let imageData: Data?
    let text: EditorStickerText?
    let music: VideoEditorMusic?
    var frame: CGRect {
        var width = UIScreen.main.bounds.width - 80
        if music != nil {
            let height: CGFloat = 60
            width = UIScreen.main.bounds.width - 40
            return CGRect(origin: .zero, size: CGSize(width: width, height: height))
        }
        if text != nil {
            width = UIScreen.main.bounds.width - 30
        }
        let height = width
        var itemWidth: CGFloat = 0
        var itemHeight: CGFloat = 0
        let imageWidth = image.width
        var imageHeight = image.height
        if imageWidth > width {
            imageHeight = width / imageWidth * imageHeight
        }
        if imageHeight > height {
            itemWidth = height / image.height * imageWidth
            itemHeight = height
        }else {
            if imageWidth > width {
                itemWidth = width
            }else {
                itemWidth = imageWidth
            }
            itemHeight = imageHeight
        }
        return CGRect(x: 0, y: 0, width: itemWidth, height: itemHeight)
    }
    init(image: UIImage,
         imageData: Data?,
         text: EditorStickerText?,
         music: VideoEditorMusic? = nil,
         videoSize: CGSize? = nil) {
        self.image = image
        self.imageData = imageData
        self.text = text
        self.music = music
    }
}

extension EditorStickerText: Codable {
    enum CodingKeys: CodingKey {
        case image
        case text
        case textColor
        case showBackgroud
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let imageData = try container.decode(Data.self, forKey: .image)
        image = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(imageData) as! UIImage
        text = try container.decode(String.self, forKey: .text)
        let colorData = try container.decode(Data.self, forKey: .textColor)
        textColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as! UIColor
        showBackgroud = try container.decode(Bool.self, forKey: .showBackgroud)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if #available(iOS 11.0, *) {
            let imageData = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
            try container.encode(imageData, forKey: .image)
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: textColor, requiringSecureCoding: false)
            try container.encode(colorData, forKey: .textColor)
        } else {
            let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
            try container.encode(imageData, forKey: .image)
            let colorData = NSKeyedArchiver.archivedData(withRootObject: textColor)
            try container.encode(colorData, forKey: .textColor)
        }
        try container.encode(text, forKey: .text)
        try container.encode(showBackgroud, forKey: .showBackgroud)
    }
}

extension EditorStickerItem: Codable {
    enum CodingKeys: CodingKey {
        case image
        case imageData
        case text
        case music
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let imageData = try container.decode(Data.self, forKey: .image)
        var image = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(imageData) as! UIImage
        if let data = try container.decodeIfPresent(Data.self, forKey: .imageData) {
            self.imageData = data
            #if canImport(Kingfisher)
            if data.kf.imageFormat == .GIF {
                if let gifImage = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([])) {
                    image = gifImage
                }
            }
            #endif
        }else {
            self.imageData = nil
        }
        self.image = image
        text = try container.decodeIfPresent(EditorStickerText.self, forKey: .text)
        music = try container.decodeIfPresent(VideoEditorMusic.self, forKey: .music)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if #available(iOS 11.0, *) {
            let imageData = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
            try container.encode(imageData, forKey: .image)
        } else {
            let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
            try container.encode(imageData, forKey: .image)
        }
        if let data = imageData {
            try container.encodeIfPresent(data, forKey: .imageData)
        }else {
            #if canImport(Kingfisher)
            if let data = image.kf.gifRepresentation() {
                try container.encodeIfPresent(data, forKey: .imageData)
            }
            #endif
        }
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(music, forKey: .music)
    }
}

class EditorStickerContentView: UIView {
    
    lazy var animationView: VideoEditorMusicAnimationView = {
        let view = VideoEditorMusicAnimationView(hexColor: "#ffffff")
        view.startAnimation()
        return view
    }()
    lazy var textLayer: CATextLayer = {
        let textLayer = CATextLayer()
        let fontSize: CGFloat = 25
        let font = UIFont.boldSystemFont(ofSize: fontSize)
        textLayer.font = font
        textLayer.fontSize = fontSize
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.truncationMode = .end
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.alignmentMode = .left
        textLayer.isWrapped = true
        return textLayer
    }()
    lazy var imageView: ImageView = {
        let view = ImageView()
        if let imageData = item.imageData {
            view.setImageData(imageData)
        }else {
            view.image = item.image
        }
        return view
    }()
    var scale: CGFloat = 1
    var item: EditorStickerItem
    weak var timer: Timer?
    init(item: EditorStickerItem) {
        self.item = item
        super.init(frame: item.frame)
        if item.music != nil {
            addSubview(animationView)
            layer.addSublayer(textLayer)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if let player = PhotoManager.shared.audioPlayer {
                textLayer.string = item.music?.lyric(atTime: player.currentTime)?.lyric
            }else {
                textLayer.string = item.music?.lyric(atTime: 0)?.lyric
            }
            CATransaction.commit()
            updateText()
            startTimer()
        }else {
            if item.text != nil {
                imageView.layer.shadowColor = UIColor.black.withAlphaComponent(0.8).cgColor
            }
            addSubview(imageView)
        }
        layer.shadowOpacity = 0.4
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
    func startTimer() {
        invalidateTimer()
        let timer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true, block: { [weak self] timer in
                if let player = PhotoManager.shared.audioPlayer {
                    let lyric = self?.item.music?.lyric(atTime: player.currentTime)
                    if let str = self?.textLayer.string as? String,
                       let lyricStr = lyric?.lyric,
                       str == lyricStr {
                       return
                    }
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self?.textLayer.string = lyric?.lyric
                    self?.updateText()
                    CATransaction.commit()
                }else {
                    timer.invalidate()
                    self?.timer = nil
                }
        })
        self.timer = timer
    }
    func invalidateTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
    func update(item: EditorStickerItem) {
        self.item = item
        if !frame.equalTo(item.frame) {
            frame = item.frame
        }
        if imageView.image != item.image {
            imageView.image = item.image
        }
    }
    func updateText() {
        if var height = (textLayer.string as? String)?.height(
            ofFont: textLayer.font as! UIFont, maxWidth: width * scale
        ) {
            height = min(100, height)
            if textLayer.frame.height != height {
                textLayer.frame = CGRect(origin: .zero, size: CGSize(width: width * scale, height: height))
            }
        }
        animationView.frame = CGRect(x: 2, y: -23, width: 20, height: 15)
    }
    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        gestureRecognizer.delegate = self
        super.addGestureRecognizer(gestureRecognizer)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if item.music != nil {
            updateText()
        }else {
            imageView.frame = bounds
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
//    deinit {
//        print("deinit: \(self)")
//    }
}

extension EditorStickerContentView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer.delegate is PhotoEditorViewController ||
            otherGestureRecognizer.delegate is VideoEditorViewController {
            return false
        }
        if otherGestureRecognizer is UITapGestureRecognizer || gestureRecognizer is UITapGestureRecognizer {
            return true
        }
        if let view = gestureRecognizer.view, view == self,
           let otherView = otherGestureRecognizer.view, otherView == self {
            return true
        }
        return false
    }
}
