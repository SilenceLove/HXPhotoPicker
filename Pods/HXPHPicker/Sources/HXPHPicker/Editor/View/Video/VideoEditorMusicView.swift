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
    func musicView(didSearchButton musicView: VideoEditorMusicView)
    func musicView(didVolumeButton musicView: VideoEditorMusicView)
    func musicView(_ musicView: VideoEditorMusicView, didOriginalSoundButtonClick isSelected: Bool)
    func musicView(_ musicView: VideoEditorMusicView, didShowLyricButton isSelected: Bool, music: VideoEditorMusic?)
}

class VideoEditorMusicView: UIView {
    weak var delegate: VideoEditorMusicViewDelegate?
    lazy var bgMaskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(false)
        return layer
    }()
    lazy var searchBgView: UIVisualEffectView = {
        let visualEffect = UIBlurEffect.init(style: .light)
        let view = UIVisualEffectView.init(effect: visualEffect)
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        view.contentView.addSubview(searchButton)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        return view
    }()
    lazy var searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage("hx_editor_video_music_search".image?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle("搜索".localized, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 0)
        button.titleLabel?.font = .mediumPingFang(ofSize: 14)
        button.tintColor = .white
        button.imageView?.tintColor = .white
        button.addTarget(self, action: #selector(didSearchButtonClick), for: .touchUpInside)
        return button
    }()
    @objc func didSearchButtonClick() {
        delegate?.musicView(didSearchButton: self)
    }
    lazy var volumeBgView: UIVisualEffectView = {
        let visualEffect = UIBlurEffect.init(style: .light)
        let view = UIVisualEffectView.init(effect: visualEffect)
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        view.contentView.addSubview(volumeButton)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        return view
    }()
    lazy var volumeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage("hx_editor_video_music_volume".image?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle("音量".localized, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 0)
        button.titleLabel?.font = .mediumPingFang(ofSize: 14)
        button.tintColor = .white
        button.imageView?.tintColor = .white
        button.addTarget(self, action: #selector(didVolumeButtonClick), for: .touchUpInside)
        return button
    }()
    @objc func didVolumeButtonClick() {
        delegate?.musicView(didVolumeButton: self)
    }
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 15
        flowLayout.minimumInteritemSpacing = 0
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
        collectionView.decelerationRate = .fast
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
        button.titleLabel?.adjustsFontSizeToFitWidth = true
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
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.font = UIFont.mediumPingFang(ofSize: 16)
        button.setImage("hx_photo_box_normal".image, for: .normal)
        button.setImage("hx_photo_box_selected".image, for: .selected)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        button.tintColor = .white
        button.addTarget(self, action: #selector(didButtonClick(button:)), for: .touchUpInside)
        button.isSelected = true
        return button
    }()
    
    lazy var showLyricButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("歌词".localized, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
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
                showLyricButton.isSelected = false
                delegate?.musicView(self, didShowLyricButton: false, music: nil)
            }
        }else if button == originalSoundButton {
            delegate?.musicView(self, didOriginalSoundButtonClick: button.isSelected)
        }else {
            if !backgroundButton.isSelected && button.isSelected {
                if selectedIndex == -1 {
                    selectedIndex = 0
                }
                playMusic()
            }else {
                delegate?.musicView(self, didShowLyricButton: button.isSelected, music: currentMusic())
            }
        }
    }
    var isloading: Bool = false
    var pageWidth: CGFloat = 0
    var selectedIndex: Int = -1
    var currentPlayIndex: Int = -2
    var beforeIsSelect = false
    var musics: [VideoEditorMusic] = []
    let config: VideoEditorConfiguration.Music
    var didEnterPlayGround = false
    init(config: VideoEditorConfiguration.Music) {
        self.config = config
        super.init(frame: .zero)
        setMusics(infos: config.infos)
        layer.addSublayer(bgMaskLayer)
        addSubview(collectionView)
        if config.showSearch {
            addSubview(searchBgView)
        }
        addSubview(volumeBgView)
        addSubview(backgroundButton)
        addSubview(originalSoundButton)
        addSubview(showLyricButton)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterPlayGround),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    @objc func appDidEnterBackground() {
        if backgroundButton.isSelected && currentPlayIndex != -2 {
            beforeIsSelect = true
        }
        stopMusic()
        didEnterPlayGround = true
    }
    @objc func appDidEnterPlayGround() {
        if !didEnterPlayGround {
            return
        }
        if backgroundButton.isSelected && beforeIsSelect {
            playMusic()
        }else {
            backgroundButton.isSelected = false
            showLyricButton.isSelected = false
            delegate?.musicView(self, didShowLyricButton: false, music: nil)
        }
        beforeIsSelect = false
        didEnterPlayGround = false
    }
    func setMusics(infos: [VideoEditorMusicInfo]) {
        var musicArray: [VideoEditorMusic] = []
        for musicInfo in infos {
            let music = VideoEditorMusic(
                audioURL: musicInfo.audioURL,
                lrc: musicInfo.lrc
            )
            musicArray.append(music)
        }
        musics = musicArray
    }
    func reset() {
        selectedIndex = -1
        backgroundButton.isSelected = false
        showLyricButton.isSelected = false
        delegate?.musicView(self, didShowLyricButton: false, music: nil)
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
        showLyricButton.isHidden = infos.isEmpty
        if !infos.isEmpty {
            backgroundButton.isHidden = false
            showLyricButton.isHidden = false
        }
        UIView.animate(withDuration: 0.25) {
            self.backgroundButton.alpha = infos.isEmpty ? 0 : 1
            self.showLyricButton.alpha = infos.isEmpty ? 0 : 1
            self.setBottomButtonFrame()
        } completion: { _ in
            if infos.isEmpty {
                self.backgroundButton.isHidden = true
                self.showLyricButton.isHidden = true
            }
        }

    }
    func showLoading() {
        if !musics.isEmpty {
            return
        }
        let loadMusic = VideoEditorMusic(
            audioURL: URL(fileURLWithPath: ""),
            lrc: ""
        )
        loadMusic.isLoading = true
        musics = [loadMusic]
        collectionView.reloadData()
        isloading = true
    }
    
    func currentMusic() -> VideoEditorMusic? {
        if currentPlayIndex < 0 {
            return nil
        }
        return musics[currentPlayIndex]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bgMaskLayer.frame = bounds
        let margin: CGFloat = 30
        let searchTextWidth = searchButton.currentTitle?.width(
            ofFont: UIFont.mediumPingFang(ofSize: 14),
            maxHeight: 30
        ) ?? 0
        var searchButtonWidth = searchTextWidth + (searchButton.currentImage?.width ?? 0) + 20
        if searchButtonWidth < 65 {
            searchButtonWidth = 65
        }
        searchBgView.frame = CGRect(x: UIDevice.leftMargin + margin, y: 0, width: searchButtonWidth, height: 30)
        searchButton.frame = searchBgView.bounds
        
        let volumeTextWidth = volumeButton.currentTitle?.width(
            ofFont: UIFont.mediumPingFang(ofSize: 14),
            maxHeight: 30
        ) ?? 0
        var volumeButtonWidth = volumeTextWidth + (volumeButton.currentImage?.width ?? 0) + 20
        if volumeButtonWidth < 65 {
            volumeButtonWidth = 65
        }
        volumeBgView.frame = CGRect(
            x: width - UIDevice.rightMargin - margin - volumeButtonWidth,
            y: 0,
            width: volumeButtonWidth,
            height: 30
        )
        volumeButton.frame = volumeBgView.bounds
        
        pageWidth = width - margin * 2 - UIDevice.leftMargin - UIDevice.rightMargin + flowLayout.minimumLineSpacing
        collectionView.frame = CGRect(x: 0, y: searchBgView.frame.maxY + 15, width: width, height: 90)
        flowLayout.sectionInset = UIEdgeInsets(
            top: 0,
            left: margin + UIDevice.leftMargin,
            bottom: 0,
            right: margin + UIDevice.rightMargin
        )
        flowLayout.itemSize = CGSize(width: pageWidth - flowLayout.minimumLineSpacing, height: collectionView.height)
        setBottomButtonFrame()
    }
    func setBottomButtonFrame() {
        
        let buttonHeight: CGFloat = 25
        let imageWidth = backgroundButton.currentImage?.width ?? 0
        let bgTextWidth = backgroundButton.currentTitle?.width(
            ofFont: UIFont.mediumPingFang(ofSize: 16),
            maxHeight: buttonHeight
        ) ?? 0
        let bgButtonWidth = imageWidth + bgTextWidth + 10
        
        let originalTextWidth = originalSoundButton.currentTitle?.width(
            ofFont: UIFont.mediumPingFang(ofSize: 16),
            maxHeight: buttonHeight
        ) ?? 0
        let originalButtonWidth = imageWidth + originalTextWidth + 10
        
        let showLyricTextWidth = showLyricButton.currentTitle?.width(
            ofFont: UIFont.mediumPingFang(ofSize: 16),
            maxHeight: buttonHeight
        ) ?? 0
        let showLyricWidth = imageWidth + showLyricTextWidth + 10
        
        originalSoundButton.frame = CGRect(
            x: 0,
            y: backgroundButton.y,
            width: originalButtonWidth,
            height: buttonHeight
        )
        originalSoundButton.centerX = width * 0.5
        
        let margin: CGFloat = 35
        backgroundButton.frame = CGRect(
            x: originalSoundButton.x - margin - bgButtonWidth,
            y: collectionView.frame.maxY + 20,
            width: bgButtonWidth,
            height: buttonHeight
        )
        
        showLyricButton.frame = CGRect(
            x: originalSoundButton.frame.maxX + margin,
            y: backgroundButton.y,
            width: showLyricWidth,
            height: buttonHeight
        )
        if backgroundButton.x <= 0 && showLyricButton.frame.maxX >= width {
            backgroundButton.x = 5
            backgroundButton.width = originalSoundButton.x - 10
            showLyricButton.x = originalSoundButton.frame.maxX + 5
            showLyricButton.width = width - showLyricButton.x - 5
        }else if backgroundButton.x <= 0 || showLyricButton.frame.maxX >= width {
            let margin = (width - backgroundButton.width - originalSoundButton.width - showLyricButton.width) * 0.5
            backgroundButton.x = margin
            originalSoundButton.x = backgroundButton.frame.maxX
            showLyricButton.x = originalSoundButton.frame.maxX
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension VideoEditorMusicView: UICollectionViewDataSource,
                                UICollectionViewDelegate,
                                UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        musics.count
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "VideoEditorMusicViewCellID",
            for: indexPath
        ) as! VideoEditorMusicViewCell
        cell.music = musics[indexPath.item]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let offsetX = pageWidth * CGFloat(indexPath.item)
        if (indexPath.item == selectedIndex && backgroundButton.isSelected) ||
            collectionView.contentOffset.x != offsetX {
            return
        }
        selectedIndex = indexPath.item
        if collectionView.contentOffset.x == offsetX {
            playMusic()
        }else {
            collectionView.setContentOffset(CGPoint(x: offsetX, y: collectionView.contentOffset.y), animated: true)
        }
    }
    
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if selectedIndex == -1 { selectedIndex = 0 }
        let finalPoint = targetContentOffset.pointee
        let pageWidth = pageWidth
        let startX = pageWidth * CGFloat(selectedIndex)
        var index = selectedIndex
        let margin = flowLayout.itemSize.width * 0.3
        if finalPoint.x < startX - margin {
            index -= 1
        }else if finalPoint.x > startX + margin {
            index += 1
        }else {
            if velocity.x != 0 {
                index = velocity.x > 0 ? index + 1 : index - 1
            }
        }
        index = min(index, musics.count - 1)
        index = max(0, index)
        let offsetX = pageWidth * CGFloat(index)
        selectedIndex = index
        targetContentOffset.pointee.x = offsetX
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !scrollView.isTracking && config.autoPlayWhenScrollingStops {
            playMusic()
        }
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            if selectedIndex == -1 { return }
            let offsetX = pageWidth * CGFloat(selectedIndex)
            scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
        }
    }
 
    func playMusic() {
        if selectedIndex == -1 { return }
        if currentPlayIndex == selectedIndex { return }
        stopMusic()
        let currentX = pageWidth * CGFloat(selectedIndex)
        if collectionView.contentOffset.x != currentX {
            collectionView.setContentOffset(CGPoint(x: currentX, y: 0), animated: false)
        }
        let cell = collectionView.cellForItem(
            at: IndexPath(
                item: selectedIndex,
                section: 0
            )
        ) as? VideoEditorMusicViewCell
        if cell?.music.isLoading == true {
            return
        }
        cell?.playMusic(completion: { [weak self] path, music in
            guard let self = self else { return }
            self.backgroundButton.isSelected = true
            let shake = UIImpactFeedbackGenerator(style: .light)
            shake.prepare()
            shake.impactOccurred()
            self.delegate?.musicView(self, didSelectMusic: path)
            if self.showLyricButton.isSelected {
                self.delegate?.musicView(self, didShowLyricButton: true, music: music)
            }
        })
        currentPlayIndex = selectedIndex
    }
    func stopMusic() {
        if let beforeCell = collectionView.cellForItem(
            at: IndexPath(
                item: currentPlayIndex,
                section: 0
            )
        ) as? VideoEditorMusicViewCell {
            if beforeCell.music.isLoading == true {
                return
            }
            beforeCell.stopMusic()
        }else {
            if currentPlayIndex >= 0 {
                let currentMusic = musics[currentPlayIndex]
                PhotoManager.shared.suspendTask(currentMusic.audioURL)
                currentMusic.isSelected = false
            }
            PhotoManager.shared.stopPlayMusic()
        }
        currentPlayIndex = -2
        delegate?.musicView(deselectMusic: self)
    }
}
