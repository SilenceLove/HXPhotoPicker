//
//  PhotoPickerBottomNumberView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/10/25.
//

import UIKit

public class PhotoPickerBottomNumberView: UICollectionReusableView {
    
    private var contentLb: UILabel!
    private var filterLb: UILabel!
    
    public var didFilterHandler: (() -> Void)?
    public var filterOptions: PhotoPickerFilterSection.Options = .any {
        didSet {
            updateFilter()
        }
    }
    
    public var photoCount: Int = 0
    var videoCount: Int = 0
    
    public var config: PhotoListConfiguration.AssetNumber? {
        didSet {
            configData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentLb = UILabel()
        contentLb.textAlignment = .center
        addSubview(contentLb)
        
        filterLb = UILabel()
        filterLb.textAlignment = .center
        filterLb.numberOfLines = 0
        filterLb.isHidden = true
        filterLb.isUserInteractionEnabled = true
        filterLb.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didFilterLabelClick)))
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
                contentLb.text = .textPhotoList.filterBottomEmptyItemTitle.text
            }else {
                contentLb.text = nil
            }
        }
    }
    
    @objc
    private func didFilterLabelClick() {
        didFilterHandler?()
    }
    
    private func updateFilter() {
        if filterOptions == .any {
            filterLb.isHidden = true
            return
        }
        filterLb.isHidden = false
        var filterContent = ""
        if filterOptions.contains(.edited) {
            filterContent += .textPhotoList.filter.editedTitle.text
        }
        if filterOptions.contains(.photo) {
            if !filterContent.isEmpty {
                filterContent += "、"
            }
            filterContent += .textPhotoList.filter.photoTitle.text
        }
        if filterOptions.contains(.gif) {
            if !filterContent.isEmpty {
                filterContent += "、"
            }
            filterContent += .textPhotoList.filter.gifTitle.text
        }
        if filterOptions.contains(.livePhoto) {
            if !filterContent.isEmpty {
                filterContent += "、"
            }
            filterContent += .textPhotoList.filter.livePhotoTitle.text
        }
        if filterOptions.contains(.video) {
            if !filterContent.isEmpty {
                filterContent += "、"
            }
            filterContent += .textPhotoList.filter.videoTitle.text
        }
        guard let config = config else {
            return
        }
        let isDark = PhotoManager.isDark
        let atbStr = NSMutableAttributedString(
            string: .textPhotoList.filterBottomTitle.text + "：",
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
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        contentLb.size = .init(width: width, height: min(height, 30))
        if height < 30 {
            contentLb.y = 0
        }else {
            contentLb.centerY = 25
        }
        filterLb.width = width
        if let textHeight = filterLb.attributedText?.string.height(ofFont: .systemFont(ofSize: 14), maxWidth: width) {
            filterLb.height = textHeight
        }
        filterLb.y = contentLb.frame.maxY
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
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

fileprivate extension String {
    var intervalNumber: String {
        guard let value = Int(self) else {
            return self
        }
        let number = NSNumber(value: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        guard let string = formatter.string(from: number) else {
            return self
        }
        return string
    }
}
