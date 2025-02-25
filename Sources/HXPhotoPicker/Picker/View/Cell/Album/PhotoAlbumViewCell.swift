//
//  PhotoAlbumViewCell.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/19.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public class PhotoAlbumViewCell: UITableViewCell {
    var iconView: UIImageView!
    var titleLb: UILabel!
    var countLb: UILabel!
    var selectedBgView: UIView!
    var lineView: UIView!
    var arrowView: UIImageView!
    
    public var config: PhotoAlbumControllerConfiguration = .init() {
        didSet {
            titleLb.font = config.mediaTitleFont
            countLb.font = config.mediaCountFont
            countLb.isHidden = !config.isShowPhotoCount
            updateColors()
        }
    }
    
    public var assetCollection: PhotoAssetCollection! {
        didSet {
            if #available(iOS 13.0, *) {
                iconView.image = assetCollection.assetTypeimage?.withRenderingMode(.alwaysTemplate)
            }
            titleLb.text = assetCollection.albumName
            countLb.text = "\(assetCollection.count)"
        }
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLb = UILabel()
        contentView.addSubview(titleLb)
        
        iconView = UIImageView()
        contentView.addSubview(iconView)
        
        selectedBgView = UIView()
        lineView = UIView()
        lineView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.15)
        contentView.addSubview(lineView)
        countLb = UILabel()
        contentView.addSubview(countLb)
        arrowView = UIImageView(image: .imageResource.picker.albumList.cell.arrow.image?.withRenderingMode(.alwaysTemplate))
        contentView.addSubview(arrowView)
        updateColors()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if let imageSize = arrowView.image?.size {
            arrowView.size = imageSize
            arrowView.centerY = contentView.height / 2
            arrowView.hxPicker_x = contentView.width - 15 - arrowView.width
            arrowView.hxPicker_flip()
        }
        
        countLb.y = 0
        countLb.height = contentView.height
        countLb.width = countLb.textWidth
        countLb.hxPicker_x = arrowView.hxPicker_x - 10 - countLb.width
        
        if let image = iconView.image {
            iconView.size = .init(width: image.width * 1.3, height: image.height * 1.3)
            iconView.centerY = height / 2
            iconView.hxPicker_x = 15
            titleLb.hxPicker_frame = .init(x: 60, y: 0, width: countLb.hxPicker_x - 70, height: height)
        }else {
            titleLb.hxPicker_frame = .init(x: 15, y: 0, width: countLb.hxPicker_x - 20, height: height)
        }
        
        lineView.hxPicker_frame = .init(x: titleLb.hxPicker_x, y: contentView.height - 0.5, width: contentView.width - 15, height: 0.5)
    }
    
    func updateColors() {
        let isDark = PhotoManager.isDark
        iconView.tintColor = isDark ? config.imageDarkColor : config.imageColor
        titleLb.textColor = isDark ? config.mediaTitleDarkColor : config.mediaTitleColor
        countLb.textColor = isDark ? config.mediaCountDarkColor : config.mediaCountColor
        arrowView.tintColor = isDark ? config.arrowDarkColor : config.arrowColor
        lineView.backgroundColor = isDark ? config.separatorLineDarkColor : config.separatorLineColor
        backgroundColor = isDark ? config.cellBackgroundDarkColor : config.cellBackgroundColor
        if isDark {
            selectedBgView.backgroundColor = config.cellSelectedDarkColor
            selectedBackgroundView = selectedBgView
        }else {
            if let color = config.cellSelectedColor {
                selectedBgView.backgroundColor = color
                selectedBackgroundView = selectedBgView
            }else {
                selectedBackgroundView = nil
            }
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateColors()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


fileprivate extension PhotoAssetCollection {
    
    @available(iOS 13.0, *)
    var assetTypeimage: UIImage? {
        guard let collection = collection else {
            return nil
        }
        switch collection.assetCollectionSubtype {
        case .smartAlbumPanoramas:
            return .init(systemName: "pano")
        case .smartAlbumVideos:
            return .init(systemName: "video")
        case .smartAlbumTimelapses:
            return .init(systemName: "timelapse")
        case .smartAlbumBursts:
            return .init(systemName: "square.stack.3d.down.right")
        case .smartAlbumSlomoVideos:
            return .init(systemName: "slowmo")
        case .smartAlbumSelfPortraits:
            return .init(systemName: "person.crop.square")
        case .smartAlbumScreenshots:
            return .init(systemName: "camera.viewfinder")
        case .smartAlbumLivePhotos:
            return .init(systemName: "livephoto")
        case .smartAlbumAnimated:
            return .init(systemName: "square.stack.3d.down.dottedline")
        case .smartAlbumRAW:
            return .init(systemName: "r.square.on.square")
        case .smartAlbumCinematic:
            return .init(systemName: "video.circle")
        default:
            if collection.assetCollectionSubtype.rawValue == 1000000218 {
                return .init(systemName: "square.and.arrow.down.badge.clock")
            }
            return nil
        }
    }
    
}
