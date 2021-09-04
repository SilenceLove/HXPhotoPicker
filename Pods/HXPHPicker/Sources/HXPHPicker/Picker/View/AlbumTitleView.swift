//
//  AlbumTitleView.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

class AlbumTitleView: UIControl {
   
   var config: AlbumTitleViewConfiguration
   
   lazy var contentView: UIView = {
       let contentView = UIView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 30))
       contentView.layer.cornerRadius = 15
       contentView.layer.masksToBounds = true
       contentView.isUserInteractionEnabled = false
       return contentView
   }()
   
   var title: String? {
       didSet {
           if title == nil {
               title = "相册".localized
           }
           titleLb.text = title
           updateTitleFrame()
       }
   }
   func updateTitleFrame() {
       var titleWidth = title?.width(ofFont: titleLb.font, maxHeight: height) ?? 0
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
       size = CGSize(width: UIScreen.main.bounds.size.width * 0.5, height: 30)
       updateTitleFrame()
   }
   var titleColor: UIColor? {
       didSet {
           titleLb.textColor = titleColor
       }
   }
   
   private lazy var titleLb: UILabel = {
        let text = "相册".localized
        let font = UIFont.semiboldPingFang(ofSize: 18)
        let titleLb = UILabel(
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
        return titleLb
   }()
   
   lazy var arrowView: ArrowView = {
       let arrowView = ArrowView(
        frame: CGRect(
            x: titleLb.frame.maxX + 5,
            y: 0,
            width: 20,
            height: 20
        ),
        config: self.config.arrow
       )
       
       return arrowView
   }()
   
   init(config: AlbumTitleViewConfiguration) {
       self.config = config
       super.init(frame: CGRect.zero)
       size = CGSize(width: UIScreen.main.bounds.size.width * 0.5, height: 30)
       contentView.addSubview(titleLb)
       contentView.addSubview(arrowView)
       addSubview(contentView)
       configColor()
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
