//
//  PhotoPickerBottomNumberView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/10/25.
//

import UIKit

class PhotoPickerBottomNumberView: UICollectionReusableView {
    
    lazy var contentLb: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    
    var photoCount: Int = 0
    var videoCount: Int = 0
    
    var config: PhotoListConfiguration.AssetNumber? {
        didSet {
            configData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(contentLb)
        addSubview(filterLb)
    }
    
    func configData(_ showEmpty: Bool = false) {
        guard let config = config else {
            return
        }
        let isDark = PhotoManager.isDark
        contentLb.textColor = isDark ? config.textDarkColor : config.textColor
        contentLb.font = config.textFont
        let photoString = "\(photoCount)".intervalNumber + " "
        let videoString = "\(videoCount)".intervalNumber + " " 
        if photoCount > 0 && videoCount > 0 {
            contentLb.text = photoString  + "张照片".localized + "、" + videoString + "个视频".localized
        }else if photoCount > 0 {
            contentLb.text = photoString + "张照片".localized
        }else if videoCount > 0 {
            contentLb.text = videoString + "个视频".localized
        }else {
            if showEmpty {
                contentLb.text = "没有项目".localized
            }else {
                contentLb.text = nil
            }
        }
    }
    
    lazy var filterLb: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didFilterLabelClick)))
        return label
    }()
    
    var didFilterHandler: (() -> Void)?
    
    @objc
    func didFilterLabelClick() {
        didFilterHandler?()
    }
    
    var filterOptions: PhotoPickerFilterSection.Options = .any {
        didSet {
            updateFilter()
        }
    }
    
    func updateFilter() {
        if filterOptions == .any {
            filterLb.isHidden = true
            return
        }
        filterLb.isHidden = false
        var filterContent = ""
        if filterOptions.contains(.edited) {
            filterContent += "已编辑".localized
        }
        if filterOptions.contains(.photo) {
            if !filterContent.isEmpty {
                filterContent += "、"
            }
            filterContent += "筛选照片".localized
        }
        if filterOptions.contains(.gif) {
            if !filterContent.isEmpty {
                filterContent += "、"
            }
            filterContent += "GIF"
        }
        if filterOptions.contains(.livePhoto) {
            if !filterContent.isEmpty {
                filterContent += "、"
            }
            filterContent += "LivePhoto"
        }
        if filterOptions.contains(.video) {
            if !filterContent.isEmpty {
                filterContent += "、"
            }
            filterContent += "筛选视频".localized
        }
        guard let config = config else {
            return
        }
        let isDark = PhotoManager.isDark
        let atbStr = NSMutableAttributedString(
            string: "筛选条件".localized + "：",
            attributes: [
                .font: config.filterFont,
                .foregroundColor: isDark ? config.filterTitleDarkColor : config.filterTitleColor
            ]
        )
        atbStr.append(.init(
            string: filterContent,
            attributes: [
                .font: config.filterFont,
                .foregroundColor: isDark ? config.filterContentDarkColor : config.filterContentColor
            ]
        ))
        filterLb.attributedText = atbStr
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentLb.size = .init(width: width, height: min(height, 30))
        if height < 30 {
            contentLb.y = 0
        }else {
            contentLb.centerY = 25
        }
        filterLb.width = width
        filterLb.height = filterLb.attributedText?.string.height(ofFont: .systemFont(ofSize: 14), maxWidth: width) ?? 0
        filterLb.y = contentLb.frame.maxY
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configData()
                updateFilter()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension String {
    fileprivate var intervalNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(self) ?? 0)) ?? self
    }
}
