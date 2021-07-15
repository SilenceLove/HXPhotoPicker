//
//  PhotoPickerBaseViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit
import Photos

#if canImport(Kingfisher)
import Kingfisher
#endif

public protocol PhotoPickerViewCellDelegate: AnyObject {
    func cell(_ cell: PhotoPickerBaseViewCell, didSelectControl isSelected: Bool)
}

public extension PhotoPickerViewCellDelegate {
    func cell(_ cell: PhotoPickerBaseViewCell, didSelectControl isSelected: Bool) { }
}

open class PhotoPickerBaseViewCell: UICollectionViewCell {
    public weak var delegate: PhotoPickerViewCellDelegate?
    
    /// 配置
    public var config: PhotoListCellConfiguration? {
        didSet {
            configColor()
        }
    }
    open func configColor() {
        backgroundColor = PhotoManager.isDark ? config?.backgroundDarkColor : config?.backgroundColor
    }
    // 展示图片
    public lazy var imageView: UIImageView = {
        let imageView = UIImageView.init()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    /// 是否可以选择
    open var canSelect = true
    
    /// 请求ID
    public var requestID: PHImageRequestID?
    
    /// 网络图片下载状态
    public var downloadStatus: PhotoAsset.DownloadStatus = .unknow
    
    open var photoAsset: PhotoAsset! {
        didSet {
            updateSelectedState(isSelected: photoAsset.isSelected, animated: false)
            requestThumbnailImage()
        }
    }
    private var firstLoadCompletion: Bool = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func initView() {
        isHidden = true
        contentView.addSubview(imageView)
    }
    
    /// 当前选中时显示的标题数字
    open var selectedTitle: String = "0"
    
    /// 获取图片，重写此方法可以修改图片
    open func requestThumbnailImage() {
        requestThumbnailImage(targetWidth: PhotoManager.shared.targetWidth <= 0 ? width * 2 : PhotoManager.shared.targetWidth)
    }
    
    /// 获取图片，重写此方法可以修改图片
    open func requestThumbnailImage(targetWidth: CGFloat) {
        if photoAsset.isNetworkAsset || photoAsset.mediaSubType == .localVideo {
            downloadStatus = .downloading
            #if canImport(Kingfisher)
            imageView.setImage(for: photoAsset, urlType: .thumbnail, completionHandler:  { [weak self] (image, error, photoAsset) in
                if self?.photoAsset == photoAsset {
                    if image != nil {
                        self?.downloadStatus = .succeed
                    }else {
                        if error!.isTaskCancelled {
                            self?.downloadStatus = .canceled
                        }else {
                            self?.downloadStatus = .failed
                        }
                    }
                }
            })
            #else
            imageView.setVideoCoverImage(for: photoAsset) { [weak self] (image, photoAsset) in
                if self?.photoAsset == photoAsset {
                    self?.imageView.image = image
                    if image != nil {
                        self?.downloadStatus = .succeed
                    }else {
                        self?.downloadStatus = .failed
                    }
                }
            }
            #endif
            if !firstLoadCompletion {
                isHidden = false
                firstLoadCompletion = true
            }
        }else {
            requestID = photoAsset.requestThumbnailImage(targetWidth: targetWidth, completion: { [weak self] (image, photoAsset, info) in
                if photoAsset == self?.photoAsset && image != nil {
                    if self?.firstLoadCompletion == false {
                        self?.isHidden = false
                        self?.firstLoadCompletion = true
                    }
                    self?.imageView.image = image
                    if !AssetManager.assetIsDegraded(for: info) {
                        self?.requestID = nil
                    }
                }
            })
        }
    }
    
    /// 更新已选状态
    /// 重写此方法时如果是自定义的选择按钮显示当前选择的下标文字，必须在此方法内更新文字内容，否则将会出现顺序显示错乱
    /// 当前选择的下标：photoAsset.selectIndex
    /// - Parameters:
    ///   - isSelected: 是否已选择
    ///   - animated: 是否需要动画效果
    open func updateSelectedState(isSelected: Bool, animated: Bool) {
        selectedTitle = isSelected ? String(photoAsset.selectIndex + 1) : "0"
    }
    /// 布局，重写此方法修改布局
    open func layoutView() {
        imageView.frame = bounds
    }
    
    /// 取消请求资源图片
    public func cancelRequest() {
        if requestID != nil {
            PHImageManager.default().cancelImageRequest(requestID!)
            requestID = nil
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutView()
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
}
