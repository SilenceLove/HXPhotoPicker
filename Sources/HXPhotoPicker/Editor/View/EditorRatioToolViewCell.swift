//
//  EditorRatioToolViewCell.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/7.
//

import UIKit

class EditorRatioToolViewCell: UICollectionViewCell {
    
    lazy var bgEffectView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        view.layer.cornerRadius = 22 / 2
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()
    
    lazy var bgView: UIView = {
        let view = UIView()
        if #available(iOS 11.0, *) {
            view.cornersRound(radius: 22 / 2, corner: .allCorners)
        }
        view.addSubview(titleLb)
        return view
    }()
    
    lazy var titleLb: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    var config: EditorRatioToolConfig? {
        didSet {
            guard let config = config else {
                return
            }
            titleLb.text = config.title
            titleLb.textColor = config.titleNormalColor.color
            bgView.backgroundColor = config.backgroundNormalColor.color
        }
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectState(isSelected)
        }
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    func initView() {
        contentView.addSubview(bgEffectView)
        contentView.addSubview(bgView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.isPortrait {
            bgView.x = 0
            bgView.size = .init(width: width, height: 22)
            bgView.centerY = height * 0.5
        }else {
            if let config = config {
                bgView.y = 0
                let titleWidth = config.title.width(ofFont: .systemFont(ofSize: 14), maxHeight: .max) + 12
                bgView.size = .init(width: min(titleWidth, 120), height: height)
                bgView.centerX = width * 0.5
            }
        }
        titleLb.frame = bgView.bounds
        bgEffectView.frame = bgView.frame
        if #available(iOS 11.0, *) { }else {
            bgView.cornersRound(radius: 22 / 2, corner: .allCorners)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
