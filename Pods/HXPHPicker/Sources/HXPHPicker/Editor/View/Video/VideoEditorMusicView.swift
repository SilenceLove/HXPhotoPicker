//
//  VideoEditorMusicView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/17.
//

import UIKit

protocol VideoEditorMusicViewDelegate: AnyObject {
    func musicView(_ musicView: VideoEditorMusicView, didSelectMusic audioPath: String?)
    func musicView(deselectMusic musicView: VideoEditorMusicView)
    func musicView(_ musicView: VideoEditorMusicView, didOriginalSoundButtonClick isSelected: Bool)
}

class VideoEditorMusicView: UIView {
    weak var delegate: VideoEditorMusicViewDelegate?
    lazy var bgMaskLayer: CAGradientLayer = {
        let layer = CAGradientLayer.init()
        layer.contentsScale = UIScreen.main.scale
        let blackColor = UIColor.black
        layer.colors = [blackColor.withAlphaComponent(0).cgColor,
                        blackColor.withAlphaComponent(0.25).cgColor,
                        blackColor.withAlphaComponent(0.3).cgColor,
                        blackColor.withAlphaComponent(0.4).cgColor,
                        blackColor.withAlphaComponent(0.5).cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 0, y: 1)
        layer.locations = [0.15, 0.5, 0.6, 0.7, 0.9]
        layer.borderWidth = 0.0
        return layer
    }()
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 15
        flowLayout.minimumInteritemSpacing = 0
        return flowLayout
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 50), collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(VideoEditorMusicViewCell.self, forCellWithReuseIdentifier: "VideoEditorMusicViewCellID")
        return collectionView
    }()
    
    lazy var backgroundButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("配乐".localized, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.mediumPingFang(ofSize: 16)
        button.setImage("hx_photo_box_normal".image, for: .normal)
        button.setImage("hx_photo_box_selected".image, for: .selected)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        button.tintColor = .white
        button.addTarget(self, action: #selector(didButtonClick(button:)), for: .touchUpInside)
        button.isHidden = musics.isEmpty
        button.alpha = musics.isEmpty ? 0 : 1
        return button
    }()
    
    lazy var originalSoundButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("视频原声".localized, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.mediumPingFang(ofSize: 16)
        button.setImage("hx_photo_box_normal".image, for: .normal)
        button.setImage("hx_photo_box_selected".image, for: .selected)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        button.tintColor = .white
        button.addTarget(self, action: #selector(didButtonClick(button:)), for: .touchUpInside)
        button.isSelected = true
        return button
    }()
    
    @objc func didButtonClick(button: UIButton) {
        if isloading {
            return
        }
        button.isSelected = !button.isSelected
        if button == backgroundButton {
            if button.isSelected {
                if selectedIndex == -1 {
                    selectedIndex = 0
                }
                playMusic()
            }else {
                stopMusic()
            }
        }else {
            delegate?.musicView(self, didOriginalSoundButtonClick: button.isSelected)
        }
    }
    var isloading: Bool = false
    var pageWidth: CGFloat = 0
    var selectedIndex: Int = -1
    var currentPlayIndex: Int = -2
    var musics: [VideoEditorMusic] = []
    init(musicInfos: [VideoEditorMusicInfo]) {
        super.init(frame: .zero)
        setMusics(infos: musicInfos)
        layer.addSublayer(bgMaskLayer)
        addSubview(collectionView)
        addSubview(backgroundButton)
        addSubview(originalSoundButton)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterPlayGround), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    @objc func appDidEnterBackground() {
        stopMusic()
    }
    @objc func appDidEnterPlayGround() {
        if backgroundButton.isSelected {
            playMusic()
        }
    }
    func setMusics(infos: [VideoEditorMusicInfo]) {
        var musicArray: [VideoEditorMusic] = []
        for musicInfo in infos {
            let music = VideoEditorMusic(audioPath: musicInfo.audioPath,
                                         lrcPath: musicInfo.lrcPath)
            musicArray.append(music)
        }
        musics = musicArray
    }
    func reset() {
        selectedIndex = -1
        backgroundButton.isSelected = false
        stopMusic()
        collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    func reloadContentOffset() {
        collectionView.setContentOffset(collectionView.contentOffset, animated: false)
    }
    func reloadData(infos: [VideoEditorMusicInfo]) {
        setMusics(infos: infos)
        collectionView.reloadData()
        isloading = false
        backgroundButton.isHidden = infos.isEmpty
        if !infos.isEmpty {
            backgroundButton.isHidden = false
        }
        UIView.animate(withDuration: 0.25) {
            self.backgroundButton.alpha = infos.isEmpty ? 0 : 1
            self.setBottomButtonFrame()
        } completion: { _ in
            if infos.isEmpty {
                self.backgroundButton.isHidden = true
            }
        }

    }
    func showLoading() {
        if !musics.isEmpty {
            return
        }
        let loadMusic = VideoEditorMusic(audioPath: "",
                                         lrcPath: "")
        loadMusic.isLoading = true
        musics = [loadMusic]
        collectionView.reloadData()
        isloading = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bgMaskLayer.frame = bounds
        let margin: CGFloat = 30
        pageWidth = width - margin * 2 - UIDevice.leftMargin - UIDevice.rightMargin + flowLayout.minimumLineSpacing
        collectionView.frame = CGRect(x: 0, y: 0, width: width, height: 140)
        flowLayout.sectionInset = UIEdgeInsets(top: 15, left: margin + UIDevice.leftMargin, bottom: 5, right: margin + UIDevice.rightMargin)
        flowLayout.itemSize = CGSize(width: pageWidth - flowLayout.minimumLineSpacing, height: collectionView.height - 50)
        setBottomButtonFrame()
    }
    func setBottomButtonFrame() {
        
        let buttonHeight: CGFloat = 25
        let imageWidth = backgroundButton.currentImage?.width ?? 0
        let bgTextWidth = backgroundButton.currentTitle?.width(ofFont: UIFont.mediumPingFang(ofSize: 16), maxHeight: buttonHeight) ?? 0
        let bgButtonWidth = imageWidth + bgTextWidth + 10
        
        let originalTextWidth = originalSoundButton.currentTitle?.width(ofFont: UIFont.mediumPingFang(ofSize: 16), maxHeight: buttonHeight) ?? 0
        let originalButtonWidth = imageWidth + originalTextWidth + 10
        let margin: CGFloat = 20
        backgroundButton.frame = CGRect(x: width * 0.5 - margin - bgButtonWidth, y: collectionView.frame.maxY, width: bgButtonWidth, height: buttonHeight)
        
        originalSoundButton.frame = CGRect(x: width * 0.5 + margin, y: collectionView.frame.maxY, width: originalButtonWidth, height: buttonHeight)
        
        if musics.isEmpty {
            originalSoundButton.centerX = width * 0.5
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension VideoEditorMusicView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        musics.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoEditorMusicViewCellID", for: indexPath) as! VideoEditorMusicViewCell
        cell.music = musics[indexPath.item]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let offsetX = pageWidth * CGFloat(indexPath.item)
        if (indexPath.item == selectedIndex && backgroundButton.isSelected) || collectionView.contentOffset.x != offsetX {
            return
        }
        selectedIndex = indexPath.item
        if collectionView.contentOffset.x == offsetX {
            playMusic()
        }else {
            collectionView.setContentOffset(CGPoint(x: offsetX, y: collectionView.contentOffset.y), animated: true)
        }
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if selectedIndex == -1 {
            selectedIndex = 0
        }
        let x = targetContentOffset.pointee.x
        let pageWidth = pageWidth
        let movedX = x - pageWidth * CGFloat(selectedIndex)
        if movedX < -pageWidth * 0.5 {
            selectedIndex -= 1
        } else if movedX > pageWidth * 0.5 {
            selectedIndex += 1
        }
        let offsetX = pageWidth * CGFloat(selectedIndex)
        if abs(velocity.x) >= 2 {
            targetContentOffset.pointee.x = offsetX
            if scrollView.contentOffset.x != offsetX {
                scrollView.setContentOffset(CGPoint(x: offsetX, y: scrollView.contentOffset.y), animated: true)
            }else {
                playMusic()
            }
        } else {
            targetContentOffset.pointee.x = scrollView.contentOffset.x
            scrollView.setContentOffset(CGPoint(x: offsetX, y: scrollView.contentOffset.y), animated: true)
        }
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let currentX = pageWidth * CGFloat(selectedIndex)
        let beforeX = currentPlayIndex == -2 ? -1 : pageWidth * CGFloat(currentPlayIndex)
        if scrollView.contentOffset.x != currentX {
            scrollView.setContentOffset(CGPoint(x: currentX, y: scrollView.contentOffset.y), animated: true)
            return
        }
        if currentX.isEqual(to: beforeX) {
            return
        }
        playMusic()
    }
    func playMusic() {
        if currentPlayIndex == selectedIndex {
            return
        }
        stopMusic()
        let currentX = pageWidth * CGFloat(selectedIndex)
        if collectionView.contentOffset.x != currentX {
            collectionView.setContentOffset(CGPoint(x: currentX, y: 0), animated: false)
        }
        let cell = collectionView.cellForItem(at: IndexPath(item: selectedIndex, section: 0)) as? VideoEditorMusicViewCell
        if cell?.music.isLoading == true {
            return
        }
        cell?.playMusic()
        currentPlayIndex = selectedIndex
        backgroundButton.isSelected = true
        let shake = UIImpactFeedbackGenerator(style: .light)
        shake.prepare()
        shake.impactOccurred()
        delegate?.musicView(self, didSelectMusic: cell?.music.audioPath)
    }
    func stopMusic() {
        if currentPlayIndex >= 0 {
            let beforeCell = collectionView.cellForItem(at: IndexPath(item: currentPlayIndex, section: 0)) as? VideoEditorMusicViewCell
            if beforeCell?.music.isLoading == true {
                return
            }
            beforeCell?.stopMusic()
            currentPlayIndex = -2
        }else {
            PhotoManager.shared.stopPlayMusic()
        }
        delegate?.musicView(deselectMusic: self)
    }
}

class VideoEditorMusicViewCell: UICollectionViewCell {
    lazy var bgView: UIVisualEffectView = {
        let visualEffect = UIBlurEffect.init(style: .light)
        let view = UIVisualEffectView.init(effect: visualEffect)
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.contentView.addSubview(musicIconView)
        return view
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
        let collectionView = UICollectionView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 50), collectionViewLayout: flowLayout)
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
        collectionView.register(VideoEditorMusicLyricViewCell.self, forCellWithReuseIdentifier: "VideoEditorMusicLyricViewCellID")
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
        maskLayer.startPoint = CGPoint(x: 0, y: 1);
        maskLayer.endPoint = CGPoint(x: 1, y: 1);
        maskLayer.locations = [0.0, 0.1, 0.9, 1.0];
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
            collectionView.reloadData()
            resetStatus()
        }
    }
    var isPlaying: Bool = false
    var playTimer: DispatchSourceTimer?
    func playMusic() {
        isPlaying = true
        let visualEffect = UIBlurEffect.init(style: .extraLight)
        bgView.effect = visualEffect
        musicIconView.tintColor = "#333333".color
        animationView.startAnimation()
        animationView.isHidden = false
        collectionView.reloadData()
        let startPoint = -(width - 15)
        if PhotoManager.shared.playMusic(filePath: music.audioPath, finished: { [weak self] in
            self?.setPreciseContentOffset(x: startPoint, y: 0)
        }) {
            if let time = PhotoManager.shared.audioPlayer?.duration {
                scrollLyric(time: time)
            }else if let time = music.time {
                scrollLyric(time: time)
            }else if let time = music.lyrics.last?.startTime {
                scrollLyric(time: time + 5)
            }
        }
    }
    
    func scrollLyric(time: TimeInterval) {
        playTimer?.cancel()
        let startPoint = -(width - 15)
        collectionView.setContentOffset(CGPoint(x: startPoint, y: 0), animated: false)
        let maxOffsetX = self.collectionView.contentSize.width - width + (width - 15)
        let duration: TimeInterval = 0.005
        let marginX = (maxOffsetX - startPoint) / CGFloat(time * (1 / duration))
        let playTimer = DispatchSource.makeTimerSource()
        playTimer.schedule(deadline: .now(), repeating: .milliseconds(5), leeway: .milliseconds(0))
        playTimer.setEventHandler(handler: { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.sync {
                let offsetX = self.collectionView.contentOffset.x
                if offsetX >= maxOffsetX {
                    return
                }
                self.setPreciseContentOffset(x: offsetX + marginX, y: 0)
            }
        })
        playTimer.resume()
        self.playTimer = playTimer
    }
    
    func setPreciseContentOffset( x:CGFloat, y:CGFloat) {
        let point = CGPoint(x: x,y: y)
        collectionView.bounds = CGRect(origin: point, size: collectionView.size)
    }
    
    func stopMusic() {
        PhotoManager.shared.stopPlayMusic()
        resetStatus()
    }
    func resetStatus() {
        isPlaying = false
        let visualEffect = UIBlurEffect.init(style: .light)
        bgView.effect = visualEffect
        musicIconView.tintColor = .white
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
        shadeView.frame = CGRect(x: 0, y: musicIconView.frame.maxY + 10, width: width, height: height - musicIconView.frame.maxY - 20)
        collectionView.frame = shadeView.bounds
        maskLayer.frame = CGRect(x: 10, y: 0, width: shadeView.width - 20, height: shadeView.height)
        
        loadingView.center = CGPoint(x: width * 0.5, y: height * 0.5)
    }
    
    deinit {
        playTimer?.cancel()
    }
}

extension VideoEditorMusicViewCell: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return music.lyrics.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoEditorMusicLyricViewCellID", for: indexPath) as! VideoEditorMusicLyricViewCell
        cell.lyricLb.textColor = isPlaying ? "#333333".color : .white
        cell.lyric = music.lyrics[indexPath.item]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let lyric = music.lyrics[indexPath.item]
        let cellWidth = lyric.lyric.width(ofFont: UIFont.mediumPingFang(ofSize: 16), maxHeight: collectionView.height)
        return CGSize(width: cellWidth, height: collectionView.height)
    }
}

class VideoEditorMusicLyricViewCell: UICollectionViewCell {
    
    lazy var lyricLb: UILabel = {
        let label = UILabel.init()
        label.font = UIFont.mediumPingFang(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    var lyric: VideoEditorLyric! {
        didSet {
            lyricLb.text = lyric.lyric
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(lyricLb)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        lyricLb.frame = bounds
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
