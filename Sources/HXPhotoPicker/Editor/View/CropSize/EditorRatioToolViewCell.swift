//
//  EditorRatioToolViewCell.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/7.
//

import UIKit

class EditorRatioToolViewCell: UICollectionViewCell {
    
    private var bgEffectView: UIVisualEffectView!
    private var bgView: UIView!
    private var titleLb: UILabel!
    
    private let bgHeight: CGFloat = UIDevice.isPad ? 25 : 22
    
    
    var config: EditorRatioToolConfig? {
        didSet {
            guard let config = config else {
                return
            }
            titleLb.text = config.title.text
            titleLb.textColor = config.titleNormalColor.color
            bgView.backgroundColor = config.backgroundNormalColor.color
        }
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectState(isSelected)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    func initView() {
        bgEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        bgEffectView.layer.cornerRadius = bgHeight / 2
        bgEffectView.layer.masksToBounds = true
        bgEffectView.isHidden = true
        contentView.addSubview(bgEffectView)
        
        bgView = UIView()
        if #available(iOS 11.0, *) {
            bgView.cornersRound(radius: bgHeight / 2, corner: .allCorners)
        }
        titleLb = UILabel()
        titleLb.textAlignment = .center
        titleLb.font = .systemFont(ofSize: UIDevice.isPad ? 16 : 14)
        titleLb.adjustsFontSizeToFitWidth = true
        bgView.addSubview(titleLb)
        contentView.addSubview(bgView)
    }
    
    func updateSelectState(_ isSelected: Bool) {
        guard let config = config else {
            return
        }
        if config.backgroundSelectedColor.isEmpty {
            bgEffectView.isHidden = !isSelected
        }else {
            bgEffectView.isHidden = true
        }
        bgView.backgroundColor = isSelected ? config.backgroundSelectedColor.color : config.backgroundNormalColor.color
        titleLb.textColor = isSelected ? config.titleSelectedColor.color : config.titleNormalColor.color
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.isPortrait {
            bgView.x = 0
            bgView.size = .init(width: width, height: bgHeight)
            bgView.centerY = height * 0.5
        }else {
            if let config = config, let font = titleLb.font {
                bgView.y = 0
                let titleWidth = config.title.text.width(ofFont: font, maxHeight: .max) + 12
                bgView.size = .init(width: min(titleWidth, 120), height: height)
                bgView.centerX = width * 0.5
            }
        }
        titleLb.frame = bgView.bounds
        bgEffectView.frame = bgView.frame
        guard #available(iOS 11.0, *) else {
            bgView.cornersRound(radius: bgHeight / 2, corner: .allCorners)
            return
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
