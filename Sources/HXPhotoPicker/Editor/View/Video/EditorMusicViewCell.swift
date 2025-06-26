//
//  EditorMusicViewCell.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/20.
//

import UIKit
import AVFoundation

protocol EditorMusicViewCellDelegate: AnyObject {
    @discardableResult
    func musicViewCell(
        _ viewCell: EditorMusicViewCell,
        didPlay musicURL: VideoEditorMusicURL,
        playCompletion: @escaping (() -> Void)
    ) -> Bool
    func musicViewCell(_ viewCell: EditorMusicViewCell, playCompletion: @escaping (() -> Void))
    func musicViewCell(playTime viewCell: EditorMusicViewCell) -> TimeInterval?
    func musicViewCell(musicDuration viewCell: EditorMusicViewCell) -> TimeInterval?
    func musicViewCell(stopPlay viewCell: EditorMusicViewCell)
}

class EditorMusicViewCell: UICollectionViewCell {
    
    weak var delegate: EditorMusicViewCellDelegate?
    
    private var bgView: UIVisualEffectView!
    private var songNameLb: UILabel!
    private var animationView: EditorAudioAnimationView!
    private var flowLayout: UICollectionViewFlowLayout!
    private var collectionView: UICollectionView!
    private var shadeView: UIView!
    private var maskLayer: CAGradientLayer!
    private var musicIconView: UIImageView!
    private var loadingView: UIActivityIndicatorView!
    
    var music: VideoEditorMusic! {
        didSet {
            if music.isLoading {
                loadingView.isHidden = false
                loadingView.startAnimating()
                return
            }
            if music.lyrics.isEmpty {
                music.parseLrc()
            }
            if let songName = music.songName, !songName.isEmpty,
               let singer = music.singer, !singer.isEmpty {
                songNameLb.text = songName + " - " + singer
            }else {
                songNameLb.text = music.songName
            }
            if shadeView.height == 0 {
                layoutSubviews()
            }
            if music.isSelected {
                collectionView.reloadData()
                playMusic { _, _ in
                }
            }else {
                resetStatus()
            }
        }
    }
    private var isPlaying: Bool = false
    private var playTimer: DispatchSourceTimer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        maskLayer = CAGradientLayer()
        maskLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
        maskLayer.startPoint = CGPoint(x: 0, y: 1)
        maskLayer.endPoint = CGPoint(x: 1, y: 1)
        maskLayer.locations = [0.0, 0.1, 0.9, 1.0]
        
        musicIconView = UIImageView.init(image: .imageResource.editor.music.music.image?.withRenderingMode(.alwaysTemplate))
        musicIconView.tintColor = .white
        musicIconView.size = musicIconView.image?.size ?? .zero
        
        bgView = UIVisualEffectView.init(effect: UIBlurEffect(style: .light))
        bgView.layer.cornerRadius = 12
        bgView.layer.masksToBounds = true
        bgView.contentView.addSubview(musicIconView)
        contentView.addSubview(bgView)
        
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 20
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        collectionView = HXCollectionView(
            frame: CGRect(x: 0, y: 0, width: 0, height: 50),
            collectionViewLayout: flowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isUserInteractionEnabled = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(
            EditorMusicLyricViewCell.self,
            forCellWithReuseIdentifier: "EditorMusicLyricViewCellID"
        )
        
        shadeView = UIView()
        shadeView.addSubview(collectionView)
        shadeView.layer.mask = maskLayer
        contentView.addSubview(shadeView)
        
        loadingView = UIActivityIndicatorView(style: .white)
        loadingView.isHidden = true
        contentView.addSubview(loadingView)
        
        animationView = EditorAudioAnimationView()
        animationView.isHidden = true
        contentView.addSubview(animationView)
        
        songNameLb = UILabel()
        songNameLb.font = .mediumPingFang(ofSize: 16)
        contentView.addSubview(songNameLb)
    }
    
    func playMusic(completion: @escaping (VideoEditorMusicURL, VideoEditorMusic) -> Void) {
        hideLoading()
        switch music.audioURL {
        case .network:
            playNetworkMusic(completion: completion)
        default:
            playLocalMusic(completion: completion)
        }
    }
    func playLocalMusic(completion: @escaping (VideoEditorMusicURL, VideoEditorMusic) -> Void) {
        guard let url = music.audioURL.url else {
            return
        }
        music.localAudioPath = url.path
        didPlay(audioURL: music.audioURL)
        music.isSelected = true
        completion(music.audioURL, music)
    }
    func playNetworkMusic(completion: @escaping (VideoEditorMusicURL, VideoEditorMusic) -> Void) {
        guard let url = music.audioURL.url else {
            return
        }
        let key = url.absoluteString
        let audioTmpURL = PhotoTools.getAudioTmpURL(for: key)
        if PhotoTools.isCached(forAudio: key) {
            music.localAudioPath = audioTmpURL.path
            didPlay(audioURL: music.audioURL)
            music.isSelected = true
            completion(music.audioURL, music)
            return
        }
        showLoading()
        PhotoManager.shared.downloadTask(
            with: url,
            toFile: audioTmpURL,
            ext: music
        ) { [weak self] audioURL, _, ext in
            guard let self = self else { return }
            self.hideLoading()
            if let music = ext as? VideoEditorMusic, audioURL != nil {
                if music == self.music {
                    self.didPlay(audioURL: music.audioURL)
                    music.isSelected = true
                }else {
                    self.delegate?.musicViewCell(self, didPlay: music.audioURL, playCompletion: {
                    })
                }
                completion(music.audioURL, music)
            }else {
                self.resetStatus()
            }
        }
    }
    func showLoading() {
        loadingView.style = .gray
        loadingView.startAnimating()
        loadingView.isHidden = false
        let visualEffect = UIBlurEffect(style: .extraLight)
        bgView.effect = visualEffect
        musicIconView.tintColor = "#333333".color
        songNameLb.textColor = "#333333".color
        songNameLb.isHidden = true
        collectionView.isHidden = true
    }
    func hideLoading() {
        songNameLb.isHidden = false
        collectionView.isHidden = false
        loadingView.stopAnimating()
        loadingView.isHidden = true
    }
    var playTime: TimeInterval? {
        delegate?.musicViewCell(playTime: self)
    }
    var musicDuration: TimeInterval? {
        delegate?.musicViewCell(musicDuration: self)
    }
    func didPlay(audioURL: VideoEditorMusicURL) {
        isPlaying = true
        let visualEffect = UIBlurEffect.init(style: .extraLight)
        bgView.effect = visualEffect
        musicIconView.tintColor = "#333333".color
        songNameLb.textColor = "#333333".color
        animationView.startAnimation()
        animationView.isHidden = false
        collectionView.reloadData()
        let startPointX = -(width - 15)
        if music.isSelected {
            playTimer?.cancel()
            if music.lyricIsEmpty {
                DispatchQueue.main.async {
                    self.scrollLyric(time: 10)
                }
                return
            }
            delegate?.musicViewCell(self, playCompletion: { [weak self] in
                guard let self = self else { return }
                if self.music.lyricIsEmpty {
                    return
                }
                self.setPreciseContentOffset(x: startPointX, y: 0)
            })
            DispatchQueue.main.async {
                guard let time = self.playTime,
                      let duration = self.musicDuration else {
                    return
                }
                let timeScale = CGFloat(time / duration)
                let maxOffsetX = self.collectionView.contentSize.width - self.width + (self.width - 15) - startPointX
                let timeOffsetX = maxOffsetX * timeScale + startPointX
                self.setPreciseContentOffset(x: timeOffsetX, y: 0)
                self.scrollLyric(time: duration)
            }
        }else {
            let isPlaying = delegate?.musicViewCell(self, didPlay: audioURL, playCompletion: { [weak self] in
                guard let self = self else { return }
                if self.music.lyricIsEmpty {
                    return
                }
                self.setPreciseContentOffset(x: startPointX, y: 0)
            })
            if let isPlaying = isPlaying, isPlaying {
                if music.lyricIsEmpty {
                    scrollLyric(time: 10)
                    return
                }
                if let time = musicDuration {
                    scrollLyric(time: time)
                }else if let time = music.time {
                    scrollLyric(time: time)
                }else if let time = music.lyrics.last?.startTime {
                    scrollLyric(time: time + 5)
                }
            }
        }
    }
    
    func scrollLyric(time: TimeInterval) {
        playTimer?.cancel()
        let startPointX = -(width - 15)
        if !music.isSelected {
            collectionView.setContentOffset(CGPoint(x: startPointX, y: 0), animated: false)
        }
        let maxOffsetX = collectionView.contentSize.width - width + (width - 15)
        let duration: TimeInterval = 0.005
        let marginX = (maxOffsetX - startPointX) / CGFloat(time * (1 / duration))
        let playTimer = DispatchSource.makeTimerSource()
        playTimer.schedule(deadline: .now(), repeating: .milliseconds(5), leeway: .milliseconds(0))
        playTimer.setEventHandler(handler: { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.sync {
                let offsetX = self.collectionView.contentOffset.x
                if offsetX >= maxOffsetX {
                    if self.music.lyricIsEmpty {
                        self.setPreciseContentOffset(x: startPointX, y: 0)
                    }
                    return
                }
                self.setPreciseContentOffset(x: offsetX + marginX, y: 0)
            }
        })
        playTimer.resume()
        self.playTimer = playTimer
    }
    
    func setPreciseContentOffset(x: CGFloat, y: CGFloat) {
        let point = CGPoint(x: x, y: y)
        collectionView.bounds = CGRect(origin: point, size: collectionView.size)
    }
    
    func stopMusic(_ didFunc: Bool = true) {
        music.isSelected = false
        switch music.audioURL {
        case .network(let url):
            PhotoManager.shared.suspendTask(url)
        default:
            break
        }
        if didFunc {
            delegate?.musicViewCell(stopPlay: self)
        }
        resetStatus()
    }
    func resetStatus() {
        isPlaying = false
        hideLoading()
        let visualEffect = UIBlurEffect.init(style: .light)
        bgView.effect = visualEffect
        musicIconView.tintColor = .white
        songNameLb.textColor = .white
        animationView.isHidden = true
        animationView.stopAnimation()
        collectionView.reloadData()
        playTimer?.cancel()
        collectionView.setContentOffset(.zero, animated: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bgView.frame = bounds
        musicIconView.x = 15
        musicIconView.y = 15
        animationView.frame = CGRect(x: width - 60, y: 20, width: 20, height: 15)
        songNameLb.x = musicIconView.frame.maxX + 10
        songNameLb.width = animationView.x - 10 - songNameLb.x
        songNameLb.height = 20
        songNameLb.centerY = musicIconView.centerY
        shadeView.frame = CGRect(
            x: 0,
            y: musicIconView.frame.maxY + 10,
            width: width,
            height: height - musicIconView.frame.maxY - 20
        )
        collectionView.frame = shadeView.bounds
        maskLayer.frame = CGRect(x: 10, y: 0, width: shadeView.width - 20, height: shadeView.height)
        
        loadingView.center = CGPoint(x: width * 0.5, y: height * 0.5)
    }
    
    deinit {
        playTimer?.cancel()
    }
}

extension EditorMusicViewCell: UICollectionViewDataSource,
                                    UICollectionViewDelegate,
                                    UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return music.lyrics.count
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorMusicLyricViewCellID",
            for: indexPath
        ) as! EditorMusicLyricViewCell
        cell.lyricLb.textColor = isPlaying ? "#333333".color : .white
        cell.lyric = music.lyrics[indexPath.item]
        return cell
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let lyric = music.lyrics[indexPath.item]
        let cellWidth = lyric.lyric.width(
            ofFont: UIFont.mediumPingFang(ofSize: 16),
            maxHeight: shadeView.height
        )
        return CGSize(width: cellWidth, height: shadeView.height)
    }
}
