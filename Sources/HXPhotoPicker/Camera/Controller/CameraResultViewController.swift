//
//  CameraResultViewController.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/31.
//

import UIKit
import AVFoundation

#if !targetEnvironment(macCatalyst)
class CameraResultViewController: UIViewController {
    enum ResultType {
        case photo
        case video
    }
    weak var delegate: CameraResultViewControllerDelegate?
    let type: ResultType
    let color: UIColor
    var image: UIImage?
    init(image: UIImage, tintColor: UIColor) {
        self.type = .photo
        self.image = image
        self.color = tintColor
        super.init(nibName: nil, bundle: nil)
    }
    var videoURL: URL?
    init(videoURL: URL, tintColor: UIColor) {
        self.type = .video
        self.videoURL = videoURL
        self.color = tintColor
        super.init(nibName: nil, bundle: nil)
    }
    
    private var topMaskLayer: CAGradientLayer!
    private var imageView: UIImageView!
    private var playerView: CameraResultVideoView!
    private var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(didViewClick)
            )
        )
        initViews()
    }
    
    private func initViews() {
        topMaskLayer = PhotoTools.getGradientShadowLayer(true)
        view.layer.addSublayer(topMaskLayer)
        
        if type == .photo {
            imageView = UIImageView(image: image)
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            view.addSubview(imageView)
        }else {
            playerView = CameraResultVideoView()
            if let videoURL = videoURL {
                playerView.avAsset = AVAsset(url: videoURL)
            }
            view.addSubview(playerView)
        }
        
        doneButton = UIButton(type: .system)
        doneButton.setTitle(.textManager.camera.resultFinishTitle.text, for: .normal)
        doneButton.titleLabel?.font = .textManager.camera.resultFinishTitleFont
        doneButton.layer.cornerRadius = 3
        doneButton.layer.masksToBounds = true
        doneButton.addTarget(self, action: #selector(didDoneButtonClick(button:)), for: .touchUpInside)
        doneButton.backgroundColor = color
        doneButton.setTitleColor(.white, for: .normal)
        view.addSubview(doneButton)
    }
    
    @objc
    private func didDoneButtonClick(button: UIButton) {
        delegate?.cameraResultViewController(didDone: self)
    }
    
    @objc
    private func didViewClick() {
        if doneButton.alpha == 1 {
            navigationController?.setNavigationBarHidden(true, animated: true)
            UIView.animate(withDuration: 0.25) {
                self.doneButton.alpha = 0
            }
        }else {
            navigationController?.setNavigationBarHidden(false, animated: true)
            UIView.animate(withDuration: 0.25) {
                self.doneButton.alpha = 1
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let rect: CGRect
        if UIDevice.isPad || !UIDevice.isPortrait {
            if UIDevice.isPad {
                rect = view.bounds
            }else {
                let size = CGSize(width: view.height * 16 / 9, height: view.height)
                rect = CGRect(
                    x: (view.width - size.width) * 0.5,
                    y: (view.height - size.height) * 0.5,
                    width: size.width,
                    height: size.height
                )
            }
        }else {
            let size = CGSize(width: view.width, height: view.width / 9 * 16)
            rect = CGRect(
                x: (view.width - size.width) * 0.5,
                y: (view.height - size.height) * 0.5,
                width: size.width,
                height: size.height
            )
        }
        if type == .photo {
            imageView.frame = rect
        }else {
            playerView.frame = rect
        }
        var doneWidth: CGFloat = 0
        if let doneTitleWidth = doneButton.currentTitle?.width(ofFont: doneButton.titleLabel!.font, maxHeight: 33) {
            doneWidth = doneTitleWidth + 20
        }else {
            doneWidth = 20
        }
        if doneWidth < 60 {
            doneWidth = 60
        }
        doneButton.width = doneWidth
        doneButton.height = 33
        doneButton.x = view.width - doneWidth - 12 - UIDevice.rightMargin
        doneButton.centerY = view.height - UIDevice.bottomMargin - 25
        if let nav = navigationController {
            topMaskLayer.frame = CGRect(
                x: 0,
                y: 0,
                width: view.width,
                height: nav.navigationBar.frame.maxY + 10
            )
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let nav = navigationController else {
            return
        }
        let navHeight = nav.navigationBar.frame.maxY
        nav.navigationBar.setBackgroundImage(
            UIImage.image(
                for: .clear,
                havingSize: CGSize(width: view.width, height: navHeight)
            ),
            for: .default
        )
        nav.navigationBar.shadowImage = UIImage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CameraResultVideoView: VideoPlayerView {
    override var avAsset: AVAsset? {
        didSet {
            configAsset()
        }
    }
    func configAsset() {
        if let avAsset = avAsset {
            try? AVAudioSession.sharedInstance().setCategory(.soloAmbient)
            let playerItem = AVPlayerItem(asset: avAsset)
            player.replaceCurrentItem(with: playerItem)
            playerLayer.player = player
            player.play()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerItemDidPlayToEndTimeNotification(notifi:)),
                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                object: player.currentItem
            )
            
        }
    }
    @objc func playerItemDidPlayToEndTimeNotification(notifi: Notification) {
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        player.play()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
#endif
