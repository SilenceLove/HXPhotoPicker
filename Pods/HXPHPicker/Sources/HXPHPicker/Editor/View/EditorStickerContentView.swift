//
//  EditorStickerContentView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/20.
//

import UIKit

struct EditorStickerText {
    let image: UIImage
    let text: String
    let textColor: UIColor
    let showBackgroud: Bool
}

struct EditorStickerItem {
    let image: UIImage
    let text: EditorStickerText?
    var frame: CGRect {
        var width = UIScreen.main.bounds.width - 80
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
        case hasText
        case text
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let imageData = try container.decode(Data.self, forKey: .image)
        image = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(imageData) as! UIImage
        let hasText = try container.decode(Bool.self, forKey: .hasText)
        if hasText {
            text = try container.decode(EditorStickerText.self, forKey: .text)
        }else {
            text = nil
        }
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
        if let text = text {
            try container.encode(text, forKey: .text)
            try container.encode(true, forKey: .hasText)
        }else {
            try container.encode(false, forKey: .hasText)
        }
    }
}

class EditorStickerContentView: UIView {
    
    lazy var imageView: UIImageView = {
        let view = UIImageView(image: item.image)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    var item: EditorStickerItem
    init(item: EditorStickerItem) {
        self.item = item
        super.init(frame: item.frame)
        addSubview(imageView)
    }
    func update(item: EditorStickerItem) {
        self.item = item
        frame = item.frame
        imageView.image = item.image
    }
    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        gestureRecognizer.delegate = self
        super.addGestureRecognizer(gestureRecognizer)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorStickerContentView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.delegate is PhotoEditorViewController {
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
