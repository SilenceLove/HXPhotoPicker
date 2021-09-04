//
//  ConfigurationViewCell.swift
//  Example
//
//  Created by Slience on 2021/3/16.
//

import UIKit

class ConfigurationViewCell: UITableViewCell {
    
    private(set) lazy var titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        view.adjustsFontSizeToFitWidth = true
        if #available(iOS 13.0, *) {
            view.textColor = UIColor.label
        } else {
            view.textColor = UIColor.black
        }
        view.text = ""
        view.textAlignment = .left
        return view
    }()
    
    private(set) lazy var tagsButton: UIButton = {
        let view = UIButton(frame: .zero)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        view.setTitleColor(UIColor.systemBlue, for: .normal)
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.tertiarySystemGroupedBackground
        } else {
            view.backgroundColor = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
        }
        view.setTitle("", for: .normal)
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 2
        view.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private(set) lazy var contentLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        view.text = ""
        view.numberOfLines = 2
        view.adjustsFontSizeToFitWidth = true
        if #available(iOS 13.0, *) {
            view.textColor = UIColor.secondaryLabel
        } else {
            view.textColor = UIColor.gray
        }
        view.textAlignment = .right
        return view
    }()
    
    private(set) lazy var colorView: UIView = {
        let colorView = UIView.init(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        colorView.layer.cornerRadius = 2
        colorView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        colorView.layer.shadowRadius = 2
        colorView.layer.shadowOpacity = 0.5
        colorView.layer.shadowOffset = CGSize(width: -1, height: 1)
        return colorView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(tagsButton)
        contentView.addSubview(contentLabel)
        contentView.addSubview(colorView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.hx.x = 20
        let titleLbWidth = titleLabel.text!.hx.width(ofFont: titleLabel.font, maxHeight: CGFloat(MAXFLOAT))
        titleLabel.hx.width = titleLbWidth > hx.width - 50 ? hx.width - 50 : titleLbWidth
        titleLabel.hx.height = titleLabel.text!.hx.height(ofFont: titleLabel.font, maxWidth: titleLabel.hx.width)
        titleLabel.hx.y = hx.height * 0.5 - 2 - titleLabel.hx.height
        
        tagsButton.hx.x = 16
        tagsButton.hx.width = tagsButton.titleLabel!.text!.hx.width(
            ofFont: tagsButton.titleLabel!.font,
            maxHeight: CGFloat(MAXFLOAT)
        ) + 8
        tagsButton.hx.height = tagsButton.titleLabel!.text!.hx.height(
            ofFont: tagsButton.titleLabel!.font,
            maxWidth: CGFloat(MAXFLOAT)
        ) + 4
        tagsButton.hx.y = hx.height * 0.5 + 2
        
        contentLabel.hx.width = contentLabel.text!.hx.width(ofFont: contentLabel.font, maxHeight: CGFloat(MAXFLOAT))
        contentLabel.hx.height = contentLabel.text!.hx.height(
            ofFont: contentLabel.font,
            maxWidth: contentLabel.hx.width
        )
        contentLabel.hx.centerY = hx.height * 0.5
        contentLabel.hx.x = hx.width - 20 - contentLabel.hx.width
        
        colorView.hx.centerY = hx.height * 0.5
        colorView.hx.x = hx.width - 10 - colorView.hx.width
    }
    
    public func setupData(_ rowType: ConfigRowTypeRule, _ content: String) {
        titleLabel.text = rowType.title
        tagsButton.setTitle(rowType.detailTitle, for: .normal)
        contentLabel.text = content
        colorView.isHidden = true
        
    }
    public func setupColorData(_ rowType: ConfigRowTypeRule, _ color: UIColor?) {
        titleLabel.text = rowType.title
        tagsButton.setTitle(rowType.detailTitle, for: .normal)
        colorView.backgroundColor = color
        contentLabel.isHidden = true
    }
}
