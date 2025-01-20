//
//  PhotoPeekViewController.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/4.
//

import UIKit
import AVFoundation

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
    
    private var contentView: PhotoPreviewContentViewProtocol!
    private var progressView: UIView!
    #if !targetEnvironment(macCatalyst)
    private var captureView: CaptureVideoPreviewView!
    #endif
    
    var photoAsset: PhotoAsset!
    fileprivate var progress: CGFloat = 0
    fileprivate var isCamera = false
    
    public init(_ photoAsset: PhotoAsset) {
        self.photoAsset = photoAsset
        super.init(nibName: nil, bundle: nil)
    }
    
    public init(isCamera: Bool) {
        self.isCamera = isCamera
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if photoAsset != nil {
            if photoAsset.mediaType == .photo {
                if photoAsset.mediaSubType.isLivePhoto {
                    contentView = PhotoPreviewContentLivePhotoView()
                }else {
                    contentView = PhotoPreviewContentPhotoView()
                }
            }else {
                contentView = PhotoPreviewContentVideoView()
                contentView.videoView.delegate = self
            }
            contentView.isPeek = true
            if let photoAsset = photoAsset {
                contentView.photoAsset = photoAsset
            }
            contentView.livePhotoPlayType = .auto
            contentView.videoPlayType = .auto
            contentView.delegate = self
            view.addSubview(contentView)
            
            progressView = UIView()
            progressView.backgroundColor = .white
            view.addSubview(progressView)
        }
        #if !targetEnvironment(macCatalyst)
        if isCamera {
            captureView = CaptureVideoPreviewView()
            view.addSubview(captureView)
        }
        #endif
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if photoAsset != nil {
            contentView.requestPreviewAsset()
        }
        #if !targetEnvironment(macCatalyst)
        if isCamera {
            captureView.startSession()
        }
        #endif
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if photoAsset != nil {
            contentView.cancelRequest()
        }
        #if !targetEnvironment(macCatalyst)
        if isCamera {
            captureView.stopSession()
        }
        #endif
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if photoAsset != nil {
            contentView.frame = view.bounds
            progressView.height = 1
            progressView.y = view.height - progressView.height
            progressView.width = view.width * progress
        }
        #if !targetEnvironment(macCatalyst)
        if isCamera {
            captureView.frame = view.bounds
        }
        #endif
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension PhotoPeekViewController: PhotoPreviewContentViewDelete {
    func contentView(requestSucceed contentView: PhotoPreviewContentViewProtocol) {
        delegate?.photoPeekViewController(requestSucceed: self)
    }
    func contentView(requestFailed contentView: PhotoPreviewContentViewProtocol) {
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
