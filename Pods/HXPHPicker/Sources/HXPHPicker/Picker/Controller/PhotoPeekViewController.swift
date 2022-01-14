//
//  PhotoPeekViewController.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/4.
//

import UIKit
import AVKit

public protocol PhotoPeekViewControllerDelegate: AnyObject {
    func photoPeekViewController(requestSucceed photoPeekViewController: PhotoPeekViewController)
    func photoPeekViewController(requestFailed photoPeekViewController: PhotoPeekViewController)
}

public extension PhotoPeekViewControllerDelegate {
    func photoPeekViewController(requestSucceed photoPeekViewController: PhotoPeekViewController) { }
    func photoPeekViewController(requestFailed photoPeekViewController: PhotoPeekViewController) { }
}

public class PhotoPeekViewController: UIViewController {
    weak var delegate: PhotoPeekViewControllerDelegate?
    lazy var contentView: PhotoPreviewContentView = {
        let type: PhotoPreviewContentView.`Type`
        if photoAsset.mediaType == .photo {
            if photoAsset.mediaSubType == .livePhoto ||
                photoAsset.mediaSubType == .localLivePhoto {
                type = .livePhoto
            }else {
                type = .photo
            }
        }else {
            type = .video
        }
        let view = PhotoPreviewContentView(type: type)
        view.isPeek = true
        if let photoAsset = photoAsset {
            view.photoAsset = photoAsset
        }
        view.livePhotoPlayType = .auto
        view.videoPlayType = .auto
        view.delegate = self
        if type == .video {
            view.videoView.delegate = self
        }
        return view
    }()
    
    lazy var progressView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    lazy var captureView: CaptureVideoPreviewView = {
        let view = CaptureVideoPreviewView()
        return view
    }()
    
    var photoAsset: PhotoAsset!
    fileprivate var progress: CGFloat = 0
    fileprivate var isCamera = false
    
    public init(_ photoAsset: PhotoAsset) {
        self.photoAsset = photoAsset
        super.init(nibName: nil, bundle: nil)
    }
    
    init(isCamera: Bool) {
        self.isCamera = isCamera
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if photoAsset != nil {
            view.addSubview(contentView)
            view.addSubview(progressView)
        }
        if isCamera {
            view.addSubview(captureView)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if photoAsset != nil {
            contentView.requestPreviewAsset()
        }
        if isCamera {
            captureView.startSession()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if photoAsset != nil {
            contentView.cancelRequest()
        }
        if isCamera {
            captureView.stopSession()
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if photoAsset != nil {
            contentView.frame = view.bounds
            progressView.height = 1
            progressView.y = view.height - progressView.height
            progressView.width = view.width * progress
        }
        if isCamera {
            captureView.frame = view.bounds
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension PhotoPeekViewController: PhotoPreviewContentViewDelete {
    public func contentView(requestSucceed contentView: PhotoPreviewContentView) {
        delegate?.photoPeekViewController(requestSucceed: self)
    }
    public func contentView(requestFailed contentView: PhotoPreviewContentView) {
        delegate?.photoPeekViewController(requestFailed: self)
    }
}
extension PhotoPeekViewController: PhotoPreviewVideoViewDelegate {
    func videoView(resetPlay videoView: VideoPlayerView) {
        progress = 0
        setupProgressView()
    }
    func videoView(_ videoView: VideoPlayerView, didChangedPlayerTime duration: CGFloat) {
        photoAsset.playerTime = duration
        progress = duration / CGFloat(photoAsset.videoDuration)
        setupProgressView()
    }
    fileprivate func setupProgressView() {
        if progress == 0 {
            progressView.width = 0
        }else {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveLinear) {
                self.progressView.width = self.view.width * self.progress
            }
        }
    }
}
