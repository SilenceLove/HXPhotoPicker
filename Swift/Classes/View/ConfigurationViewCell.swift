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
        titleLabel.x = 20
        let titleLbWidth = titleLabel.text!.width(ofFont: titleLabel.font, maxHeight: CGFloat(MAXFLOAT))
        titleLabel.width = titleLbWidth > width - 50 ? width - 50 : titleLbWidth
        titleLabel.height = titleLabel.text!.height(ofFont: titleLabel.font, maxWidth: titleLabel.width)
        titleLabel.y = height * 0.5 - 2 - titleLabel.height
        
        tagsButton.x = 16
        tagsButton.width = tagsButton.titleLabel!.text!.width(
            ofFont: tagsButton.titleLabel!.font,
            maxHeight: CGFloat(MAXFLOAT)
        ) + 8
        tagsButton.height = tagsButton.titleLabel!.text!.height(
            ofFont: tagsButton.titleLabel!.font,
            maxWidth: CGFloat(MAXFLOAT)
        ) + 4
        tagsButton.y = height * 0.5 + 2
        
        contentLabel.width = contentLabel.text!.width(ofFont: contentLabel.font, maxHeight: CGFloat(MAXFLOAT))
        contentLabel.height = contentLabel.text!.height(
            ofFont: contentLabel.font,
            maxWidth: contentLabel.width
        )
        contentLabel.centerY = height * 0.5
        contentLabel.x = width - 20 - contentLabel.width
        
        colorView.centerY = height * 0.5
        colorView.x = width - 10 - colorView.width
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
