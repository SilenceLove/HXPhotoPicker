//
//  HXPHPreviewContentView.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit
import PhotosUI

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
        if let localIdentifier = currentLoadAssetLocalIdentifier, localIdentifier == photoAsset?.phAsset?.localIdentifier {
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
        currentLoadAssetLocalIdentifier = photoAsset?.phAsset?.localIdentifier
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
