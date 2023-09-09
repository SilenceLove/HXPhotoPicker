//
//  AlbumTitleView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

class AlbumTitleView: UIControl {
   
    let config: AlbumTitleViewConfiguration
    var arrowView: ArrowView!

    private var contentView: UIView!
    private var titleLb: UILabel!

    var title: String? {
       didSet {
           if let title = title {
               titleLb.text = title
           }else {
               titleLb.text = "相册".localized
           }
           updateTitleFrame()
       }
    }
    var titleColor: UIColor? {
       didSet {
           titleLb.textColor = titleColor
       }
    }
    
    init(config: AlbumTitleViewConfiguration) {
        self.config = config
        let width: CGFloat
        #if !targetEnvironment(macCatalyst)
        if UIDevice.isPad {
            width = 300
        }else {
            width = UIDevice.screenSize.width * 0.5
        }
        #else
        width = 300
        #endif
        super.init(frame: .init(x: 0, y: 0, width: width, height: 30))
        initViews()
        contentView.addSubview(titleLb)
        contentView.addSubview(arrowView)
        addSubview(contentView)
        configColor()
    }
    
    private func initViews() {
        contentView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 30))
        contentView.layer.cornerRadius = 15
        contentView.layer.masksToBounds = true
        contentView.isUserInteractionEnabled = false
        
        let text = "相册".localized
        let font = UIFont.semiboldPingFang(ofSize: 18)
        titleLb = UILabel(
            frame: CGRect(
                x: 10,
                y: 0,
                width: text.width(ofFont: font, maxHeight: height),
                height: height
            )
        )
        titleLb.text = text
        titleLb.font = font
        titleLb.textAlignment = .center
        
        arrowView = ArrowView(
         frame: CGRect(
             x: titleLb.frame.maxX + 5,
             y: 0,
             width: 20,
             height: 20
         ),
         config: self.config.arrow
        )
    }

    
    func updateTitleFrame() {
        var titleWidth: CGFloat = 0
        if let labelWidth = title?.width(ofFont: titleLb.font, maxHeight: height) {
            titleWidth = labelWidth
        }
       if titleWidth > width - 40 {
           titleWidth = width - 45
       }
       UIView.animate(withDuration: 0.25) {
           self.titleLb.width = titleWidth
           self.arrowView.x = self.titleLb.frame.maxX + 5
           self.contentView.width = self.arrowView.frame.maxX + 5
           self.contentView.centerX = self.width * 0.5
       }
    }
    func updateViewFrame() {
        let width: CGFloat
        #if !targetEnvironment(macCatalyst)
        if UIDevice.isPad {
            width = 300
        }else {
            width = UIDevice.screenSize.width * 0.5
        }
        #else
        width = 300
        #endif
        size = CGSize(width: width, height: 30)
        updateTitleFrame()
    }

    override func layoutSubviews() {
       super.layoutSubviews()
       titleLb.height = height
       arrowView.centerY = titleLb.centerY
       contentView.height = height
    }

    func configColor() {
       contentView.backgroundColor = PhotoManager.isDark ? config.backgroudDarkColor : config.backgroundColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
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
