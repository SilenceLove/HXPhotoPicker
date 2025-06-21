//
//  PhotoPickerBaseViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit
import Photos

public protocol PhotoPickerViewCellDelegate: AnyObject {
    func pickerCell(_ cell: PhotoPickerBaseViewCell, didSelectControl isSelected: Bool)
    func pickerCell(videoRequestDurationCompletion cell: PhotoPickerBaseViewCell)
    func pickerCell(livePhotoContorlDidChange cell: PhotoPickerBaseViewCell)
}

public extension PhotoPickerViewCellDelegate {
    func pickerCell(_ cell: PhotoPickerBaseViewCell, didSelectControl isSelected: Bool) { }
    func pickerCell(videoRequestDurationCompletion cell: PhotoPickerBaseViewCell) { }
    func pickerCell(livePhotoContorlDidChange cell: PhotoPickerBaseViewCell) { }
}

open class PhotoPickerBaseViewCell: UICollectionViewCell {
    
    public weak var delegate: PhotoPickerViewCellDelegate?
    
    public var config: PhotoListCellConfiguration = .init() {
        didSet {
            photoView.targetWidth = config.targetWidth
            photoView.kf_indicatorColor = config.kf_indicatorColor
            configColor()
        }
    }
    /// 展示图片
    public var photoView: PhotoThumbnailView!
    
    /// 是否可以选择
    open var canSelect = true
    
    /// 请求ID
    public var requestID: PHImageRequestID? {
        photoView.requestID
    }
    
    /// 网络图片下载状态
    public var downloadStatus: PhotoAsset.DownloadStatus {
        photoView.downloadStatus
    }
    
    /// 是否赋值 photoAsset 时就请求数据
    /// Whether to request data when assigning photoAsset
    public var isRequestDirectly = true
    
    /// 对应资源的 PhotoAsset 对象
    open var photoAsset: PhotoAsset! {
        didSet {
            updateSelectedState(isSelected: photoAsset.isSelected, animated: false)
            photoView.photoAsset = photoAsset
            if isRequestDirectly {
                request()
            }
        }
    }
    
    open func updatePhotoAsset(_ asset: PhotoAsset) {
        isRequestDirectly = true
        photoAsset = asset
    }
    
    open func request() {
        requestThumbnailImage()
        requestICloudState()
    }
    
    /// 初始化
    open func initView() {
        photoView = PhotoThumbnailView()
        photoView.size = size
        photoView.imageView.size = size
        photoView.fadeImage = PhotoManager.shared.firstLoadAssets
        contentView.addSubview(photoView)
    }
    /// 配置背景颜色
    open func configColor() {
        backgroundColor = PhotoManager.isDark ? config.backgroundDarkColor : config.backgroundColor
    }
    
    /// 当前选中时显示的标题数字
    open var selectedTitle: String = "0"
    
    /// 获取图片，重写此方法可以修改图片
    open func requestThumbnailImage() {
        requestThumbnailImage(
            targetWidth: config.targetWidth
        )
    }
    
    /// 获取图片，重写此方法可以修改图片
    open func requestThumbnailImage(targetWidth: CGFloat) {
        photoView.requestThumbnailImage(targetWidth: targetWidth) { [weak self] in
            guard let self = self, self.photoAsset == $1 else { return }
            self.requestThumbnailCompletion($0)
        }
    }
    
    open func requestThumbnailCompletion(_ image: UIImage?) {
        
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
    
    /// 是否在iCloud上，只有获取过iCloud状态之后才确定
    open var inICloud: Bool = false
    
    /// 获取iCloud上的状态的请求id
    public var iCloudRequestID: PHImageRequestID?
    
    /// 获取是否在iCloud
    open func requestICloudState() {
        guard config.isShowICloudMark else {
            return
        }
        cancelICloudRequest()
        if PhotoManager.shared.thumbnailLoadMode == .simplify {
            return
        }
        iCloundLoading = true
        iCloudRequestID = photoAsset.requestICloudState { [weak self] photoAsset, inICloud in
            guard let self = self,
                  self.photoAsset == photoAsset else {
                return
            }
            self.iCloudRequestID = nil
            self.requestICloudStateCompletion(inICloud)
            self.iCloundLoading = false
        }
    }
    
    /// 获取iCloud上状态完成
    open func requestICloudStateCompletion(_ inICloud: Bool) {
        self.inICloud = inICloud
        requestICloudCompletion = true
    }
    
    /// 布局，重写此方法修改布局
    open func layoutView() {
        photoView.frame = bounds
    }
    
    /// 取消请求资源图片
    public func cancelRequest() {
        photoView.cancelRequest()
        cancelICloudRequest()
    }
    
    open func cancelICloudRequest() {
        if iCloundLoading {
            iCloundLoading = false
        }
        if requestICloudCompletion {
            requestICloudCompletion = false
        }
        if inICloud {
            inICloud = false
        }
        if let id = iCloudRequestID {
            PHImageManager.default().cancelImageRequest(id)
            iCloudRequestID = nil
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
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
    
    var iCloundLoading = false
    var requestICloudCompletion = false
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        cancelRequest()
    }
    
    deinit {
        cancelRequest()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension PhotoPickerBaseViewCell {
    func reload() {
        self.photoView.reloadImage()
        if !self.requestICloudCompletion && !self.iCloundLoading {
            self.requestICloudState()
        }
    }
    func cancelReload() {
        self.photoView.cancelRequest()
        if !self.requestICloudCompletion {
            self.cancelICloudRequest()
        }
    }
}
