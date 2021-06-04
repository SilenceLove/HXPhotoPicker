//
//  PreviewVideoViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit

class PreviewVideoViewCell: PhotoPreviewViewCell {
    
    lazy var playButton: UIButton = {
        let playButton = UIButton.init(type: UIButton.ButtonType.custom)
        playButton.setImage("hx_picker_cell_video_play".image, for: UIControl.State.normal)
        playButton.setImage(UIImage.init(), for: UIControl.State.selected)
        playButton.addTarget(self, action: #selector(didPlayButtonClick(button:)), for: UIControl.Event.touchUpInside)
        playButton.size = playButton.currentImage!.size
        playButton.alpha = 0
        return playButton
    }()
    
    @objc func didPlayButtonClick(button: UIButton) {
        if !button.isSelected {
            scrollContentView.videoView.startPlay()
        }else {
            scrollContentView.videoView.stopPlay()
        }
    }
    
    var videoPlayType: PhotoPreviewViewController.VideoPlayType = .normal  {
        didSet {
            if videoPlayType == .auto || videoPlayType == .once {
                playButton.isSelected = true
            }
            scrollContentView.videoView.videoPlayType = videoPlayType
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = PhotoPreviewContentView.init(type: .video)
        scrollContentView.videoView.delegate = self
        initView()
        addSubview(playButton)
    }
    
    override func setupScrollViewContentSize() {
        if UIDevice.isPad {
            scrollView.zoomScale = 1
            setupLandscapeContentSize()
        }else {
            super.setupScrollViewContentSize()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playButton.centerX = width * 0.5
        playButton.centerY = height * 0.5
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension PreviewVideoViewCell: PhotoPreviewVideoViewDelegate {
    func videoView(startPlay videoView: VideoPlayerView) {
        playButton.isSelected = true
    }
    
    func videoView(stopPlay videoView: VideoPlayerView) {
        playButton.isSelected = false
    }
    
    func videoView(showPlayButton videoView: VideoPlayerView) {
        if playButton.alpha == 0 {
            UIView.animate(withDuration: 0.15) {
                self.playButton.alpha = 1
            }
        }
    }
    
    func videoView(hidePlayButton videoView: VideoPlayerView) {
        if playButton.alpha == 1 {
            UIView.animate(withDuration: 0.15) {
                self.playButton.alpha = 0
            }
        }
    }
}
