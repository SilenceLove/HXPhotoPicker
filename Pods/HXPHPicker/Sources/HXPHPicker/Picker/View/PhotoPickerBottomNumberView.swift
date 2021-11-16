//
//  PhotoPickerBottomNumberView.swift
//  HXPHPicker
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
    }
    
    func configData() {
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
            contentLb.text = nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentLb.frame = bounds
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configData()
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
