//
//  HXPHPreviewViewCell.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import ImageIO

protocol HXPHPreviewViewCellDelegate: NSObjectProtocol {
    func singleTap()
}

class HXPHPreviewViewCell: UICollectionViewCell, UIScrollViewDelegate {
    
    weak var delegate: HXPHPreviewViewCellDelegate?
    
    var scrollContentView: HXPHPreviewContentView?
    lazy var scrollView : UIScrollView = {
        let scrollView = UIScrollView.init()
        scrollView.delegate = self;
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.minimumZoomScale = 1
        scrollView.isMultipleTouchEnabled = true
        scrollView.scrollsToTop = false
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        scrollView.alwaysBounceVertical = false
        scrollView.autoresizingMask = UIView.AutoresizingMask.init(arrayLiteral: .flexibleWidth, .flexibleHeight)
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(singleTap(tap:)))
        scrollView.addGestureRecognizer(singleTap)
        let doubleTap = UITapGestureRecognizer.init(target: self, action: #selector(doubleTap(tap:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        singleTap.require(toFail: doubleTap)
        scrollView.addGestureRecognizer(doubleTap)
        scrollView.addSubview(scrollContentView!)
        return scrollView
    }()
    
    var photoAsset: HXPHAsset? {
        didSet {
            setupScrollViewContenSize()
            scrollContentView!.photoAsset = photoAsset
        }
    }
    var allowInteration: Bool = true
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func initView() {
        contentView.addSubview(scrollView)
    }
    func setupScrollViewContenSize() {
        scrollView.zoomScale = 1
        if UIDevice.current.hx_isPortrait {
            let aspectRatio = hx_width / photoAsset!.imageSize.width
            let contentWidth = hx_width
            let contentHeight = photoAsset!.imageSize.height * aspectRatio
            if contentWidth < contentHeight {
                scrollView.maximumZoomScale = hx_width * 2.5 / contentWidth
            }else {
                scrollView.maximumZoomScale = hx_height * 2.5 / contentHeight
            }
            scrollContentView!.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
            if contentHeight < hx_height {
                scrollView.contentSize = hx_size
                scrollContentView!.center = CGPoint(x: hx_width * 0.5, y: hx_height * 0.5)
            }else {
                scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
            }
        }else {
            let aspectRatio = hx_height / photoAsset!.imageSize.height
            let contentWidth = photoAsset!.imageSize.width * aspectRatio
            let contentHeight = hx_height
            scrollView.maximumZoomScale = hx_width / contentWidth + 0.5
            
            scrollContentView!.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
            scrollContentView!.center = CGPoint(x: hx_width * 0.5, y: hx_height * 0.5)
            scrollView.contentSize = hx_size
        }
    }
    func requestPreviewAsset() {
        scrollContentView!.requestPreviewAsset()
    }
    func cancelRequest() {
        scrollContentView!.cancelRequest()
    }
    @objc func singleTap(tap: UITapGestureRecognizer) {
        delegate?.singleTap()
    }
    @objc func doubleTap(tap: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1 {
            scrollView.setZoomScale(1, animated: true)
        }else {
            let touchPoint = tap.location(in: scrollContentView!)
            let maximumZoomScale = scrollView.maximumZoomScale
            let width = hx_width / maximumZoomScale
            let height = hx_height / maximumZoomScale
            scrollView.zoom(to: CGRect(x: touchPoint.x - width / 2, y: touchPoint.y - height / 2, width: width, height: height), animated: true)
        }
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollContentView!
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.frame.size.width > scrollView.contentSize.width) ? (scrollView.frame.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
        let offsetY = (scrollView.frame.size.height > scrollView.contentSize.height) ? (scrollView.frame.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
        scrollContentView!.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY);
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !scrollView.isTracking && scrollView.isDecelerating {
            allowInteration = false
        }
    }
//    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if decelerate && scrollView.contentOffset.y >= -20 {
//            allowInteration = true
//        }
//    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= -40 {
            allowInteration = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if scrollView.frame.equalTo(bounds) == false {
            scrollView.frame = bounds
        }
    }
}
class HXPHPreviewPhotoViewCell: HXPHPreviewViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = HXPHPreviewContentView.init(type: HXPHPreviewContentViewType.photo)
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class HXPHPreviewLivePhotoViewCell: HXPHPreviewViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = HXPHPreviewContentView.init(type: HXPHPreviewContentViewType.livePhoto)
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class HXPHPreviewVideoViewCell: HXPHPreviewViewCell {
    
    var autoPlayVideo: Bool = false {
        didSet {
            scrollContentView?.videoView.autoPlayVideo = autoPlayVideo
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = HXPHPreviewContentView.init(type: HXPHPreviewContentViewType.video)
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

enum HXPHPreviewContentViewType: Int {
    case photo
    case livePhoto
    case video
}
class HXPHPreviewContentView: UIView, PHLivePhotoViewDelegate {
    
    lazy var imageView: HXPHGIFImageView = {
        let imageView = HXPHGIFImageView.init()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    @available(iOS 9.1, *)
    lazy var livePhotoView: PHLivePhotoView = {
        let livePhotoView = PHLivePhotoView.init()
        livePhotoView.delegate = self
        return livePhotoView
    }()
    lazy var videoView: HXPHVideoView = {
        let videoView = HXPHVideoView.init()
        videoView.alpha = 0
        return videoView
    }()
    
    var isBacking: Bool = false
    
    var type: HXPHPreviewContentViewType = .photo
    var requestID: PHImageRequestID?
    var requestCompletion: Bool = false
    var autoPlayVideo: Bool = false {
        didSet {
            if type == .video {
                videoView.autoPlayVideo = autoPlayVideo
            }
        }
    }
    var currentLoadAssetLocalIdentifier: String?
    var photoAsset: HXPHAsset? {
        didSet {
            if type == .livePhoto {
                if #available(iOS 9.1, *) {
                    livePhotoView.livePhoto = nil
                }
            }
            if photoAsset?.mediaSubType == .localImage {
                requestCompletion = true
            }
            weak var weakSelf = self
            
            requestID = photoAsset?.requestThumbnailImage(targetWidth: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height), completion: { (image, asset, info) in
                if asset == weakSelf?.photoAsset && image != nil {
                    weakSelf?.imageView.image = image
                }
            })
        }
    }
    var loadingView: HXPHProgressHUD?
    
    init(type: HXPHPreviewContentViewType) {
        super.init(frame: CGRect.zero)
        self.type = type
        addSubview(imageView)
        if type == .livePhoto {
            if #available(iOS 9.1, *) {
                addSubview(livePhotoView)
            }
        }else if type == .video {
            addSubview(videoView)
        }
    }
    
    func requestPreviewAsset() {
        if requestCompletion {
            return
        }
        if photoAsset?.mediaSubType == .localImage {
            return
        }
        var canRequest = true
        if let localIdentifier = currentLoadAssetLocalIdentifier, localIdentifier == photoAsset?.asset?.localIdentifier {
            canRequest = false
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            if loadingView == nil {
                loadingView = HXPHProgressHUD.showLoadingHUD(addedTo: self, text: "正在下载".hx_localized + "(" + String(Int(photoAsset!.downloadProgress * 100)) + "%)", animated: true)
            }
        }else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if requestID != nil {
                PHImageManager.default().cancelImageRequest(requestID!)
                requestID = nil
            }
        }
        if type == .photo {
            if photoAsset?.mediaSubType == .imageAnimated &&
                imageView.gifImage != nil {
                imageView.startAnimating()
            }else {
                if canRequest {
                    requestOriginalImage()
                }
            }
        }else if type == .livePhoto {
            if #available(iOS 9.1, *) {
                if canRequest {
                    requestLivePhoto()
                }
            }
        }else if type == HXPHPreviewContentViewType.video {
            if videoView.player.currentItem == nil && canRequest {
                requestAVAsset()
            }
        }
    }
    
    func requestOriginalImage() {
        weak var weakSelf = self
        requestID = photoAsset?.requestImageData(iCloudHandler: { (asset, iCloudRequestID) in
            if asset == weakSelf?.photoAsset {
                weakSelf?.requestShowDonwloadICloudHUD(iCloudRequestID: iCloudRequestID)
            }
        }, progressHandler: { (asset, progress) in
            if asset == weakSelf?.photoAsset {
                weakSelf?.requestUpdateProgress(progress: progress)
            }
        }, success: { (asset, imageData, imageOrientation, info) in
            if asset.mediaSubType == .imageAnimated {
                if asset == weakSelf?.photoAsset {
                    weakSelf?.requestSucceed()
                    let image = HXPHGIFImage.init(data: imageData)
                    weakSelf?.imageView.gifImage = image
                    weakSelf?.requestID = nil
                    weakSelf?.requestCompletion = true
                }
            }else {
                DispatchQueue.global().async {
                    var image = UIImage.init(data: imageData)
                    image = image?.hx_scaleSuitableSize()
                    DispatchQueue.main.async {
                        if asset == weakSelf?.photoAsset {
                            weakSelf?.requestSucceed()
                            weakSelf?.setImage(for: image)
                            weakSelf?.requestID = nil
                            weakSelf?.requestCompletion = true
                        }
                    }
                }
            }
        }, failure: { (asset, info) in
            if asset == weakSelf?.photoAsset {
                weakSelf?.requestFailed(info: info)
            }
        })
    }
    func setImage(for image: UIImage?) {
        let transition = CATransition.init()
        transition.duration = 0.2
        transition.timingFunction = CAMediaTimingFunction.init(name: .linear)
        transition.type = .fade
        imageView.layer.add(transition, forKey: nil)
        imageView.image = image
    }
    @available(iOS 9.1, *)
    func requestLivePhoto() {
        let targetSize : CGSize = hx_size
        weak var weakSelf = self
        requestID = photoAsset?.requestLivePhoto(targetSize: targetSize, iCloudHandler: { (asset, requestID) in
            if asset == weakSelf?.photoAsset {
                weakSelf?.requestShowDonwloadICloudHUD(iCloudRequestID: requestID)
            }
        }, progressHandler: { (asset, progress) in
            if asset == weakSelf?.photoAsset {
                weakSelf?.requestUpdateProgress(progress: progress)
            }
        }, success: { (asset, livePhoto, info) in
            if asset == weakSelf?.photoAsset {
                weakSelf?.requestSucceed()
                weakSelf?.livePhotoView.livePhoto = livePhoto
                UIView.animate(withDuration: 0.25) {
                    weakSelf?.livePhotoView.alpha = 1
                }
                weakSelf?.livePhotoView.startPlayback(with: PHLivePhotoViewPlaybackStyle.full)
                weakSelf?.requestID = nil
                weakSelf?.requestCompletion = true
            }
        }, failure: { (asset, info) in
            if asset == weakSelf?.photoAsset {
                weakSelf?.requestFailed(info: info)
            }
        })
    }
    func requestAVAsset() {
        weak var weakSelf = self
        requestID = photoAsset?.requestAVAsset(iCloudHandler: { (asset, requestID) in
            if asset == weakSelf?.photoAsset {
                weakSelf?.requestShowDonwloadICloudHUD(iCloudRequestID: requestID)
            }
        }, progressHandler: { (asset, progress) in
            if asset == weakSelf?.photoAsset {
                weakSelf?.requestUpdateProgress(progress: progress)
            }
        }, success: { (asset, avAsset, info) in
            if asset == weakSelf?.photoAsset {
                weakSelf?.requestSucceed()
                if weakSelf?.isBacking ?? true {
                    return
                }
                weakSelf?.videoView.avAsset = avAsset
                UIView.animate(withDuration: 0.25) {
                    weakSelf?.videoView.alpha = 1
                }
                weakSelf?.requestID = nil
                weakSelf?.requestCompletion = true
            }
        }, failure: { (asset, info) in
            if asset == weakSelf?.photoAsset {
                weakSelf?.requestFailed(info: info)
            }
        })
    }
    func requestShowDonwloadICloudHUD(iCloudRequestID: PHImageRequestID) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        requestID = iCloudRequestID
        currentLoadAssetLocalIdentifier = photoAsset?.asset?.localIdentifier
        loadingView = HXPHProgressHUD.showLoadingHUD(addedTo: self, text: "正在下载".hx_localized, animated: true)
    }
    func requestUpdateProgress(progress: Double) {
        loadingView?.updateText(text: "正在下载".hx_localized + "(" + String(Int(progress * 100)) + "%)")
    }
    func requestSucceed() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        currentLoadAssetLocalIdentifier = nil
        loadingView = nil
        HXPHProgressHUD.hideHUD(forView: self, animated: true)
    }
    func requestFailed(info: [AnyHashable : Any]?) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        loadingView?.removeFromSuperview()
        loadingView = nil
        currentLoadAssetLocalIdentifier = nil
        if !HXPHAssetManager.assetDownloadCancel(for: info) {
            HXPHProgressHUD.hideHUD(forView: self, animated: true)
            HXPHProgressHUD.showWarningHUD(addedTo: self, text: "下载失败".hx_localized, animated: true, delay: 2)
        }
    }
    func cancelRequest() {
        if photoAsset?.mediaSubType == .localImage {
            requestCompletion = false
            return
        }
        currentLoadAssetLocalIdentifier = nil
        if requestID != nil {
            PHImageManager.default().cancelImageRequest(requestID!)
            requestID = nil
        }
        stopAnimatedImage()
        HXPHProgressHUD.hideHUD(forView: self, animated: false)
        if type == .livePhoto {
            if #available(iOS 9.1, *) {
                livePhotoView.stopPlayback()
                livePhotoView.alpha = 0
            }
        }else if type == .video {
            videoView.cancelPlayer()
            videoView.alpha = 0
        }
        requestCompletion = false
    }
    func showOtherSubview() {
        if photoAsset?.mediaType == .video {
            videoView.showPlayButton()
        }
    }
    func hiddenOtherSubview() {
        if photoAsset?.mediaType == .video {
            videoView.hiddenPlayButton()
        }
        loadingView = nil
        HXPHProgressHUD.hideHUD(forView: self, animated: false)
    }
    func startAnimatedImage() {
        if photoAsset?.mediaSubType == .imageAnimated {
            imageView.setupDisplayLink()
        }
    }
    func stopAnimatedImage() {
        if photoAsset?.mediaSubType == .imageAnimated {
            imageView.displayLink?.invalidate()
            imageView.gifImage = nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        if type == HXPHPreviewContentViewType.livePhoto {
            if #available(iOS 9.1, *) {
                livePhotoView.frame = bounds
            }
        }else if type == HXPHPreviewContentViewType.video {
            videoView.frame = bounds
        }
    }
    deinit {
        cancelRequest()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class HXPHGIFImage {
    /// 内部读取图片帧队列
    fileprivate lazy var readFrameQueue: DispatchQueue = DispatchQueue(label: "hxpickerimage.gif.readFrameQueue", qos: .background)
    /// 图片资源数据
    fileprivate var cgImageSource: CGImageSource?
    /// 总动画时长
    var totalDuration: TimeInterval = 0.0
    /// 每一帧对应的动画时长
    var frameDurations: [Int: TimeInterval] = [:]
    /// 每一帧对应的图片
    var frameImages: [Int: UIImage] = [:]
    /// 总图片数
    var frameTotalCount: Int = 0
    /// 兼容之前的 UIImage 使用
    var image: UIImage?

    /// 全局配置
    struct GlobalSetting {
        /// 配置预加载帧的数量
        static var prefetchNumber: Int = 10
        static var minFrameDuration: TimeInterval = 0.01
    }

    /// 兼容 UIImage data 调用
    convenience init?(data: Data) {
        self.init(data: data, scale: 1.0)
    }

    /// 根据二进制数据初始化【核心初始化方法】
    init?(data: Data, scale: CGFloat) {
        guard let cgImageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return }
        self.cgImageSource = cgImageSource
        initGIFSource(cgImageSource: cgImageSource)
    }

    /// 获取图片数据源的第 index 帧图片的动画时间
    fileprivate class func getCGImageSourceGifFrameDelay(imageSource: CGImageSource, index: Int) -> TimeInterval {
        var delay = 0.0
        guard let imgProperties: NSDictionary = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) else { return delay }
        // 获取该帧图片的属性字典
        if let property = imgProperties[kCGImagePropertyGIFDictionary as String] as? NSDictionary {
            // 获取该帧图片的动画时长
            if let unclampedDelayTime = property[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
                delay = unclampedDelayTime.doubleValue
                if delay <= 0, let delayTime = property[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
                    delay = delayTime.doubleValue
                }
            }
        }
        return delay
    }

    /// 根据图片数据源初始化，设置动画总时长、总帧数等属性
    fileprivate func initGIFSource(cgImageSource: CGImageSource) {
        let numOfFrames = CGImageSourceGetCount(cgImageSource)
        frameTotalCount = numOfFrames
        for index in 0..<numOfFrames {
            // 获取每一帧的动画时长
            let frameDuration = HXPHGIFImage.getCGImageSourceGifFrameDelay(imageSource: cgImageSource, index: index)
            self.frameDurations[index] = max(GlobalSetting.minFrameDuration, frameDuration)
            self.totalDuration += frameDuration
            // 一开始初始化预加载一定数量的图片，而不是全部图片
            if index < GlobalSetting.prefetchNumber {
                if let cgimage = CGImageSourceCreateImageAtIndex(cgImageSource, index, nil) {
                    let image: UIImage = UIImage(cgImage: cgimage)
                    if index == 0 {
                        self.image = image
                    }
                    self.frameImages[index] = image
                }
            }
        }
    }

    /// 获取某一帧图片
    func getFrame(index: Int) -> UIImage? {
        guard index < frameTotalCount else { return nil }
        // 取当前帧图片
        let currentImage = self.frameImages[index] ?? self.image
        // 如果总帧数大于预加载数，需要加载后面未加载的帧图片
        if frameTotalCount > GlobalSetting.prefetchNumber {
            // 清除当前帧图片缓存数据，空出内存
            if index != 0 {
                self.frameImages[index] = nil
            }
            // 加载后面帧图片到内存
            for i in 1...GlobalSetting.prefetchNumber {
                let idx = (i + index) % frameTotalCount
                if self.frameImages[idx] == nil {
                    // 默认加载第一张帧图片为占位，防止多次加载
                    self.frameImages[idx] = self.frameImages[0]
                    self.readFrameQueue.async { [weak self] in
                        guard let strongSelf = self, let cgImageSource = strongSelf.cgImageSource else { return }
                        guard let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, idx, nil) else { return }
                        strongSelf.frameImages[idx] = UIImage(cgImage: cgImage)
                    }
                }
            }
        }
        return currentImage
    }
}
class HXPHGIFImageView: UIImageView {
    /// 累加器，用于计算一个定时循环中的可用动画时间
    fileprivate var accumulator: TimeInterval = 0.0
    /// 当前正在显示的图片帧索引
    fileprivate var currentFrameIndex: Int = 0
    /// 当前正在显示的图片
    fileprivate var currentFrame: UIImage?
    /// 动画图片存储属性
    fileprivate var animatedImage: HXPHGIFImage?
    /// 定时器
    fileprivate var displayLink: CADisplayLink?

    /// 重载初始化，初始化定时器
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDisplayLink()
    }
    init() {
        super.init(frame: CGRect.zero)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override init(image: UIImage?) {
        super.init(image: image)
    }

    /// 设置 GIF 图片
    var gifImage: HXPHGIFImage? {
        get {
            return self.animatedImage
        }
        set {
            if animatedImage === newValue {
                return
            }
            self.stopAnimating()
            self.currentFrameIndex = 0
            self.accumulator = 0.0
            if let newAnimatedImage = newValue {
                self.animatedImage = newAnimatedImage
                if let currentImage = newAnimatedImage.getFrame(index: 0) {
                    super.image = currentImage
                    self.currentFrame = currentImage
                }
                self.startAnimating()
            } else {
                self.animatedImage = nil
            }
            self.layer.setNeedsDisplay()
        }

    }

    /// 当显示 GIF 时，不处理高亮状态
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            if self.animatedImage == nil {
                super.isHighlighted = newValue
            }
        }
    }

    /// 获取是否正在动画
    override var isAnimating: Bool {
        if self.animatedImage != nil && self.displayLink != nil {
            return !self.displayLink!.isPaused
        } else {
            return super.isAnimating
        }
    }

    /// 开启定时器
    override func startAnimating() {
        if self.animatedImage != nil && self.displayLink != nil {
            self.displayLink!.isPaused = false
        } else {
            super.startAnimating()
        }
    }

    /// 暂停定时器
    override func stopAnimating() {
        if self.animatedImage != nil && self.displayLink != nil {
            self.displayLink!.isPaused = true
        } else {
            super.stopAnimating()
        }
    }

    /// 当前显示内容为 GIF 当前帧图片
    override func display(_ layer: CALayer) {
        super.display(layer)
        if self.animatedImage != nil {
            if let frame = self.currentFrame {
                layer.contents = frame.cgImage
            }
        }
    }

    /// 初始化定时器
    fileprivate func setupDisplayLink() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(HXPHGIFImageView.changeKeyFrame))
        self.displayLink!.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
        self.displayLink!.isPaused = true
    }

    /// 动态改变图片动画帧
    @objc fileprivate func changeKeyFrame() {
        if superview == nil || !(superview is HXPHPreviewContentView) {
            displayLink?.invalidate()
            gifImage = nil
            return
        }
        if let animatedImage = self.animatedImage {
            guard self.currentFrameIndex < animatedImage.frameTotalCount else { return }
            self.accumulator += min(1.0, displayLink!.duration)
            var frameDuration = animatedImage.frameDurations[self.currentFrameIndex] ?? displayLink!.duration
            while self.accumulator >= frameDuration {
                self.accumulator -= frameDuration
                self.currentFrameIndex += 1
                if self.currentFrameIndex >= animatedImage.frameTotalCount {
                    self.currentFrameIndex = 0
                }
                if let currentImage = animatedImage.getFrame(index: self.currentFrameIndex) {
                    self.currentFrame = currentImage
                }
                self.layer.setNeedsDisplay()
                if let newFrameDuration = animatedImage.frameDurations[self.currentFrameIndex] {
                    frameDuration = min(displayLink!.duration, newFrameDuration)
                }
            }
        } else {
            self.stopAnimating()
        }
    }
}

class HXPHVideoView: UIView {
    
    var avAsset: AVAsset? {
        didSet {
            if playButton.alpha == 0 {
                UIView.animate(withDuration: 0.25) {
                    self.playButton.alpha = 1
                }
            }
            let playerItem = AVPlayerItem.init(asset: avAsset!)
            player.replaceCurrentItem(with: playerItem)
            playerLayer.player = player
            addedPlayerObservers()
        }
    }
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    lazy var player: AVPlayer = {
        let player = AVPlayer.init()
        return player
    }()
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    lazy var playButton: UIButton = {
        let playButton = UIButton.init(type: UIButton.ButtonType.custom)
        playButton.setImage("hx_picker_cell_video_play".hx_image, for: UIControl.State.normal)
        playButton.setImage(UIImage.init(), for: UIControl.State.selected)
        playButton.addTarget(self, action: #selector(didPlayButtonClick(button:)), for: UIControl.Event.touchUpInside)
        playButton.hx_size = playButton.currentImage!.size
        playButton.alpha = 0
        return playButton
    }()
    @objc func didPlayButtonClick(button: UIButton) {
        if !button.isSelected {
            startPlay()
        }else {
            stopPlay()
        }
    }
    var isPlaying: Bool = false
    var didEnterBackground: Bool = false
    var enterPlayGroundShouldPlay: Bool = false
    var canRemovePlayerObservers: Bool = false
    var autoPlayVideo: Bool = false {
        didSet {
            if autoPlayVideo {
                playButton.isSelected = true
            }
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        layer.masksToBounds = true
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        addSubview(playButton)
        
        playerLayer.addObserver(self, forKeyPath: "readyForDisplay", options: [.new, .old], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterPlayGround), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    @objc func appDidEnterBackground() {
        didEnterBackground = true
        if isPlaying {
            enterPlayGroundShouldPlay = true
            stopPlay()
        }
    }
    @objc  func appDidEnterPlayGround() {
        didEnterBackground = false
        if enterPlayGroundShouldPlay {
            startPlay()
            enterPlayGroundShouldPlay = false
        }
    }
    func startPlay() {
        if isPlaying {
            return
        }
        player.play()
        playButton.isSelected = true
        isPlaying = true
    }
    func stopPlay() {
        if !isPlaying {
            return
        }
        player.pause()
        playButton.isSelected = false
        isPlaying = false
    }
    func hiddenPlayButton() {
        HXPHProgressHUD.hideHUD(forView: self, animated: true)
        UIView.animate(withDuration: 0.15) {
            self.playButton.alpha = 0
        }
    }
    func showPlayButton() {
        UIView.animate(withDuration: 0.25) {
            self.playButton.alpha = 1
        }
    }
    func cancelPlayer() {
        if player.currentItem != nil {
            stopPlay()
            if autoPlayVideo {
                playButton.isSelected = true
            }
            player.seek(to: CMTime.zero)
            player.cancelPendingPrerolls()
            player.currentItem?.cancelPendingSeeks()
            player.currentItem?.asset.cancelLoading()
            
            player.replaceCurrentItem(with: nil)
            playerLayer.player = nil
            removePlayerObservers()
            HXPHProgressHUD.hideHUD(forView: self, animated: true)
        }
    }
    func addedPlayerObservers() {
        if canRemovePlayerObservers {
            return
        }
        player.currentItem?.addObserver(self, forKeyPath: "status", options:[.new, .old], context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options:.new, context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options:.new, context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options:.new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTimeNotification(notifi:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        canRemovePlayerObservers = true
    }
    func removePlayerObservers() {
        if !canRemovePlayerObservers {
            return
        }
        player.currentItem?.removeObserver(self, forKeyPath: "status", context: nil)
        player.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges", context: nil)
        player.currentItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty", context: nil)
        player.currentItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp", context: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        canRemovePlayerObservers = false
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object is AVPlayerItem {
            if object as? AVPlayerItem != player.currentItem {
                return
            }
            if keyPath == "status" {
                switch player.currentItem!.status {
                case AVPlayerItem.Status.readyToPlay:
                    // 可以播放了
                    break
                case AVPlayerItem.Status.failed:
                    // 初始化失败
                    
                    break
                default:
                    // 未知状态
                    break
                }
            }else if keyPath == "loadedTimeRanges" {
                
            }else if keyPath == "playbackBufferEmpty" {
                
            }else if keyPath == "playbackLikelyToKeepUp" {
                if !player.currentItem!.isPlaybackLikelyToKeepUp {
                    // 缓冲完成
                    _ = HXPHProgressHUD.showLoadingHUD(addedTo: self, animated: true)
                }else {
                    // 缓冲中
                    HXPHProgressHUD.hideHUD(forView: self, animated: true)
                }
            }
        }else if object is AVPlayerLayer && keyPath == "readyForDisplay" {
            if object as? AVPlayerLayer != playerLayer {
                return
            }
            if self.playerLayer.isReadyForDisplay && !didEnterBackground && autoPlayVideo {
                startPlay()
            }
        }
    }
    
    @objc func playerItemDidPlayToEndTimeNotification(notifi: Notification) {
        stopPlay()
        player.currentItem?.seek(to: CMTime.init(value: 0, timescale: 1))
        if autoPlayVideo {
            startPlay()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
        playButton.hx_centerX = hx_width * 0.5
        playButton.hx_centerY = hx_height * 0.5
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    deinit {
        playerLayer.removeObserver(self, forKeyPath: "readyForDisplay")
        NotificationCenter.default.removeObserver(self)
    }
}
