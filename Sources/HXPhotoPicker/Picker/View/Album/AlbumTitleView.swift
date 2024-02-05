//
//  AlbumTitleView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

public class AlbumTitleView: UIControl, PhotoPickerNavigationTitle {
    let config: PickerConfiguration
    let isSplit: Bool
    
    public var title: String? {
       didSet {
           if let title = title {
               titleLb.text = title
           }else {
               titleLb.text = .textPhotoList.emptyNavigationTitle.text
           }
           updateFrame()
       }
    }
    
    public var titleColor: UIColor? {
       didSet {
           titleLb.textColor = titleColor
       }
    }
    
    public override var isSelected: Bool {
        didSet {
            if !isPopupAlbum {
                return
            }
            UIView.animate(withDuration: 0.25) {
                if self.isSelected {
                    self.arrowView.transform = .init(rotationAngle: .pi)
                }else {
                    self.arrowView.transform = .init(rotationAngle: .pi * 2)
                }
            }
        }
    }
    
    public override var isHighlighted: Bool {
        didSet {
            if isPopupAlbum {
                titleLb.textColor =  isHighlighted ? titleColor?.withAlphaComponent(0.4) : titleColor
                arrowView.isHighlighted = isHighlighted
                configColor()
            }
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        contentSize
    }
    
    required public init(config: PickerConfiguration, isSplit: Bool) {
        self.config = config
        self.isSplit = isSplit
        super.init(frame: .zero)
        initViews()
        configColor()
        size = contentSize
        translatesAutoresizingMaskIntoConstraints = false
    }
   
    var arrowView: ArrowView!
    var contentView: UIView!
    var titleLb: UILabel!
    var isPopupAlbum: Bool { config.albumShowMode.isPop && !isSplit }
    
    var contentSize: CGSize {
        let maxWidth: CGFloat
        #if !targetEnvironment(macCatalyst)
        if UIDevice.isPad {
            maxWidth = 300
        }else {
            maxWidth = UIDevice.screenSize.width * 0.5
        }
        #else
        maxWidth = 300
        #endif
        let titleWidth: CGFloat = min(maxWidth, titleLb.textWidth)
        if isPopupAlbum {
            return .init(width: titleWidth + 40 , height: 30)
        }else {
            return .init(width: titleWidth, height: 30)
        }
    }
    
    private func initViews() {
        let text: String = .textManager.picker.albumList.navigationTitle.text
        let font = UIFont.semiboldPingFang(ofSize: 18)
        titleLb = UILabel(
            frame: CGRect(
                x: 0,
                y: 0,
                width: text.width(ofFont: font, maxHeight: height),
                height: height
            )
        )
        titleLb.text = text
        titleLb.font = font
        titleLb.textAlignment = .center
        
        if isPopupAlbum {
            contentView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 30))
            contentView.layer.cornerRadius = 15
            contentView.layer.masksToBounds = true
            contentView.isUserInteractionEnabled = false
            addSubview(contentView)
            contentView.addSubview(titleLb)
            
            arrowView = ArrowView(frame: CGRect(
                x: titleLb.frame.maxX + 5,
                y: 0,
                width: 20,
                height: 20
            ), config: config.photoList.titleView.arrow)
            contentView.addSubview(arrowView)
        }else {
            addSubview(titleLb)
        }
    }
    
    public func addTarget(_ target: Any?, action: Selector) {
        if isPopupAlbum {
            addTarget(target, action: action, for: .touchUpInside)
        }
    }
    
    public func updateFrame() {
        size = contentSize
        invalidateIntrinsicContentSize()
        updateTitleFrame()
    }
    
    func updateTitleFrame() {
        let titleWidth = isPopupAlbum ? width - 40 : width
        UIView.animate(withDuration: 0.25) {
            self.titleLb.width = titleWidth
            if self.isPopupAlbum {
                self.titleLb.x = 10
                self.arrowView.x = self.titleLb.frame.maxX + 5
                self.contentView.width = self.arrowView.frame.maxX + 5
                self.contentView.centerX = self.width * 0.5
            }else {
                self.titleLb.x = 0
            }
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        titleLb.height = height
        if isPopupAlbum {
            arrowView.centerY = titleLb.centerY
            contentView.height = height
            contentView.centerX = width / 2
        }else {
            titleLb.x = 0
        }
    }

    func configColor() {
        if isPopupAlbum {
            let config = config.photoList.titleView
            let color = PhotoManager.isDark ? config.backgroudDarkColor : config.backgroundColor
            contentView.backgroundColor = isHighlighted ? color?.withAlphaComponent(0.4) : color
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
       super.traitCollectionDidChange(previousTraitCollection)
       if #available(iOS 13.0, *) {
           if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
               configColor()
           }
       }
    }

    required init?(coder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
    }
}
