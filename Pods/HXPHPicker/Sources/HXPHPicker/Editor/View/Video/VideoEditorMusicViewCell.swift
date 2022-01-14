//
//  VideoEditorMusicViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/26.
//

import UIKit

class VideoEditorMusicViewCell: UICollectionViewCell {
    lazy var bgView: UIVisualEffectView = {
        let visualEffect = UIBlurEffect.init(style: .light)
        let view = UIVisualEffectView.init(effect: visualEffect)
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.contentView.addSubview(musicIconView)
        return view
    }()
    lazy var songNameLb: UILabel = {
        let label = UILabel()
        label.font = .mediumPingFang(ofSize: 16)
        return label
    }()
    lazy var animationView: VideoEditorMusicAnimationView = {
        let view = VideoEditorMusicAnimationView()
        view.isHidden = true
        return view
    }()
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 20
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        return flowLayout
    }()
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
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
            VideoEditorMusicLyricViewCell.self,
            forCellWithReuseIdentifier: "VideoEditorMusicLyricViewCellID"
        )
        return collectionView
    }()
    
    lazy var shadeView: UIView = {
        let view = UIView.init()
        view.addSubview(collectionView)
        view.layer.mask = maskLayer
        return view
    }()
    
    lazy var maskLayer: CAGradientLayer = {
        let maskLayer = CAGradientLayer.init()
        maskLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
        maskLayer.startPoint = CGPoint(x: 0, y: 1)
        maskLayer.endPoint = CGPoint(x: 1, y: 1)
        maskLayer.locations = [0.0, 0.1, 0.9, 1.0]
        return maskLayer
    }()
    
    lazy var musicIconView: UIImageView = {
        let view = UIImageView.init(image: "hx_editor_tools_music".image?.withRenderingMode(.alwaysTemplate))
        view.tintColor = .white
        view.size = view.image?.size ?? .zero
        return view
    }()
    
    lazy var loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .white)
        view.isHidden = true
        return view
    }()
    
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
            collectionView.reloadData()
            if music.isSelected {
                playMusic { _, _ in
                }
            }else {
                resetStatus()
            }
        }
    }
    var isPlaying: Bool = false
    var playTimer: DispatchSourceTimer?
    func playMusic(completion: @escaping (String, VideoEditorMusic) -> Void) {
        hideLoading()
        if music.audioURL.isFileURL {
            playLocalMusic(completion: completion)
        }else {
            playNetworkMusic(completion: completion)
        }
    }
    func playLocalMusic(completion: @escaping (String, VideoEditorMusic) -> Void) {
        music.localAudioPath = music.audioURL.path
        didPlay(audioPath: music.audioURL.path)
        music.isSelected = true
        completion(music.audioURL.path, music)
    }
    func playNetworkMusic(completion: @escaping (String, VideoEditorMusic) -> Void) {
        let key = music.audioURL.absoluteString
        let audioTmpURL = PhotoTools.getAudioTmpURL(for: key)
        if PhotoTools.isCached(forAudio: key) {
            music.localAudioPath = audioTmpURL.path
            didPlay(audioPath: audioTmpURL.path)
            music.isSelected = true
            completion(audioTmpURL.path, music)
            return
        }
        showLoading()
        PhotoManager.shared.downloadTask(
            with: music.audioURL,
            toFile: audioTmpURL,
            ext: music
        ) { audioURL, error, ext in
            self.hideLoading()
            if let audioURL = audioURL,
               let music = ext as? VideoEditorMusic {
                if music == self.music {
                    self.didPlay(audioPath: audioURL.path)
                }else {
                    PhotoManager.shared.playMusic(filePath: audioURL.path) {}
                }
                music.isSelected = true
                completion(audioURL.path, music)
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
    func didPlay(audioPath: String) {
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
            PhotoManager.shared.audioPlayFinish = { [weak self] in
                guard let self = self else { return }
                if self.music.lyricIsEmpty {
                    return
                }
                self.setPreciseContentOffset(x: startPointX, y: 0)
            }
            DispatchQueue.main.async {
                guard let time = PhotoManager.shared.audioPlayer?.currentTime,
                      let duration = PhotoManager.shared.audioPlayer?.duration else {
                    return
                }
                let timeScale = CGFloat(time / duration)
                let maxOffsetX = self.collectionView.contentSize.width - self.width + (self.width - 15) - startPointX
                let timeOffsetX = maxOffsetX * timeScale + startPointX
                self.setPreciseContentOffset(x: timeOffsetX, y: 0)
                self.scrollLyric(time: duration)
            }
        }else {
            if PhotoManager.shared.playMusic(filePath: audioPath, finished: { [weak self] in
                guard let self = self else { return }
                if self.music.lyricIsEmpty {
                    return
                }
                self.setPreciseContentOffset(x: startPointX, y: 0)
            }) {
                if music.lyricIsEmpty {
                    scrollLyric(time: 10)
                    return
                }
                if let time = PhotoManager.shared.audioPlayer?.duration {
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
    
    func stopMusic() {
        music.isSelected = false
        if !music.audioURL.isFileURL {
            PhotoManager.shared.suspendTask(music.audioURL)
        } 
        PhotoManager.shared.stopPlayMusic()
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
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(bgView)
        contentView.addSubview(shadeView)
        contentView.addSubview(loadingView)
        contentView.addSubview(animationView)
        contentView.addSubview(songNameLb)
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

extension VideoEditorMusicViewCell: UICollectionViewDataSource,
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
            withReuseIdentifier: "VideoEditorMusicLyricViewCellID",
            for: indexPath
        ) as! VideoEditorMusicLyricViewCell
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
