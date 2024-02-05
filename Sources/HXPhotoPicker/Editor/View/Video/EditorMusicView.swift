//
//  EditorMusicView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/20.
//

import UIKit
import AVFoundation

protocol EditorMusicViewDelegate: AnyObject {
    func musicView(_ musicView: EditorMusicView, didSelectMusic musicURL: VideoEditorMusicURL?)
    func musicView(_ musicView: EditorMusicView, deselectMusic didStop: Bool)
    func musicView(didSearchButton musicView: EditorMusicView)
    func musicView(didVolumeButton musicView: EditorMusicView)
    func musicView(_ musicView: EditorMusicView, didOriginalSoundButtonClick isSelected: Bool)
    func musicView(_ musicView: EditorMusicView, didShowLyricButton isSelected: Bool, music: VideoEditorMusic?)
    
    @discardableResult
    func musicView(
        _ musicView: EditorMusicView,
        didPlay musicURL: VideoEditorMusicURL, playCompletion: @escaping (() -> Void)
    ) -> Bool
    func musicView(_ musicView: EditorMusicView, playCompletion: @escaping (() -> Void))
    func musicView(playTime musicView: EditorMusicView) -> TimeInterval?
    func musicView(musicDuration musicView: EditorMusicView) -> TimeInterval?
    func musicView(stopPlay musicView: EditorMusicView)
}

class EditorMusicView: UIView {
    weak var delegate: EditorMusicViewDelegate?
    private var bgMaskLayer: CAGradientLayer!
    private var searchBgView: UIVisualEffectView!
    private var searchButton: UIButton!
    private var volumeBgView: UIVisualEffectView!
    private var volumeButton: UIButton!
    private var flowLayout: UICollectionViewFlowLayout!
    private var collectionView: UICollectionView!
    
    var backgroundButton: UIButton!
    var originalSoundButton: UIButton!
    var showLyricButton: UIButton!
    
    var isloading: Bool = false
    var pageWidth: CGFloat = 0
    var selectedIndex: Int = -1
    var currentPlayIndex: Int = -2
    var beforeIsSelect = false
    var musics: [VideoEditorMusic] = []
    let config: EditorConfiguration.Music
    var didEnterPlayGround = false
    
    var centerIndex: Int = 0
    init(config: EditorConfiguration.Music) {
        self.config = config
        super.init(frame: .zero)
        setMusics(infos: config.infos)
        initViews()
    }
    
    private func initViews() {
        bgMaskLayer = PhotoTools.getGradientShadowLayer(false)
        layer.addSublayer(bgMaskLayer)
        
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 15
        flowLayout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(
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
        collectionView.register(EditorMusicViewCell.self, forCellWithReuseIdentifier: "EditorMusicViewCellID")
        addSubview(collectionView)
        if config.showSearch {
            searchButton = UIButton(type: .system)
            searchButton.setImage(.imageResource.editor.music.search.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            searchButton.setTitle(.textManager.editor.music.searchButtonTitle.text, for: .normal)
            searchButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 0)
            searchButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 0)
            searchButton.titleLabel?.font = .textManager.editor.music.searchButtonTitleFont
            searchButton.tintColor = .white
            searchButton.imageView?.tintColor = .white
            searchButton.addTarget(self, action: #selector(didSearchButtonClick), for: .touchUpInside)
            let visualEffect = UIBlurEffect.init(style: .light)
            searchBgView = UIVisualEffectView.init(effect: visualEffect)
            searchBgView.layer.cornerRadius = 15
            searchBgView.layer.masksToBounds = true
            searchBgView.contentView.addSubview(searchButton)
            searchBgView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
            addSubview(searchBgView)
        }
        
        volumeButton = UIButton(type: .system)
        volumeButton.setImage(.imageResource.editor.music.volum.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        volumeButton.setTitle(.textManager.editor.music.volumeButtonTitle.text, for: .normal)
        volumeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 0)
        volumeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 0)
        volumeButton.titleLabel?.font = .textManager.editor.music.volumeButtonTitleFont
        volumeButton.tintColor = .white
        volumeButton.imageView?.tintColor = .white
        volumeButton.addTarget(self, action: #selector(didVolumeButtonClick), for: .touchUpInside)
        
        let volumeEffect = UIBlurEffect.init(style: .light)
        volumeBgView = UIVisualEffectView.init(effect: volumeEffect)
        volumeBgView.layer.cornerRadius = 15
        volumeBgView.layer.masksToBounds = true
        volumeBgView.contentView.addSubview(volumeButton)
        volumeBgView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        addSubview(volumeBgView)
        
        backgroundButton = UIButton(type: .custom)
        backgroundButton.setTitle(.textManager.editor.music.musicButtonTitle.text, for: .normal)
        backgroundButton.setTitleColor(.white, for: .normal)
        backgroundButton.titleLabel?.adjustsFontSizeToFitWidth = true
        backgroundButton.titleLabel?.font = .textManager.editor.music.musicButtonTitleFont
        backgroundButton.setImage(.imageResource.editor.music.selectionBoxNormal.image, for: .normal)
        backgroundButton.setImage(.imageResource.editor.music.selectionBoxSelected.image, for: .selected)
        backgroundButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        backgroundButton.tintColor = .white
        backgroundButton.addTarget(self, action: #selector(didButtonClick(button:)), for: .touchUpInside)
        backgroundButton.isHidden = musics.isEmpty
        backgroundButton.alpha = musics.isEmpty ? 0 : 1
        addSubview(backgroundButton)
        
        originalSoundButton = UIButton(type: .custom)
        originalSoundButton.setTitle(.textManager.editor.music.originalButtonTitle.text, for: .normal)
        originalSoundButton.setTitleColor(.white, for: .normal)
        originalSoundButton.titleLabel?.adjustsFontSizeToFitWidth = true
        originalSoundButton.titleLabel?.font = .textManager.editor.music.musicButtonTitleFont
        originalSoundButton.setImage(.imageResource.editor.music.selectionBoxNormal.image, for: .normal)
        originalSoundButton.setImage(.imageResource.editor.music.selectionBoxSelected.image, for: .selected)
        originalSoundButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        originalSoundButton.tintColor = .white
        originalSoundButton.addTarget(self, action: #selector(didButtonClick(button:)), for: .touchUpInside)
        originalSoundButton.isSelected = true
        addSubview(originalSoundButton)
        
        showLyricButton = UIButton(type: .custom)
        showLyricButton.setTitle(.textManager.editor.music.lyricButtonTitle.text, for: .normal)
        showLyricButton.setTitleColor(.white, for: .normal)
        showLyricButton.titleLabel?.adjustsFontSizeToFitWidth = true
        showLyricButton.titleLabel?.font = .textManager.editor.music.lyricButtonTitleFont
        showLyricButton.setImage(.imageResource.editor.music.selectionBoxNormal.image, for: .normal)
        showLyricButton.setImage(.imageResource.editor.music.selectionBoxSelected.image, for: .selected)
        showLyricButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        showLyricButton.tintColor = .white
        showLyricButton.addTarget(self, action: #selector(didButtonClick(button:)), for: .touchUpInside)
        showLyricButton.isHidden = musics.isEmpty
        showLyricButton.alpha = musics.isEmpty ? 0 : 1
        addSubview(showLyricButton)
    }
    
    @objc
    private func didSearchButtonClick() {
        if isloading {
            return
        }
        delegate?.musicView(didSearchButton: self)
    }
    
    @objc
    private func didVolumeButtonClick() {
        delegate?.musicView(didVolumeButton: self)
    }
    
    @objc
    private func didButtonClick(button: UIButton) {
        if isloading {
            return
        }
        button.isSelected = !button.isSelected
        if button == backgroundButton {
            if button.isSelected {
                selectedIndex = centerIndex
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
                selectedIndex = centerIndex
                playMusic()
            }else {
                delegate?.musicView(self, didShowLyricButton: button.isSelected, music: currentMusic())
            }
        }
    }
    
    func selectedMusic(_ music: VideoEditorMusic?) {
        if let music = music {
            for (index, tmpMusic) in musics.enumerated() where tmpMusic == music {
                selectedIndex = index
                currentPlayIndex = index
                centerIndex = index
                collectionView.reloadData()
                scrollToSelected()
                return
            }
        }
        selectedIndex = -1
        currentPlayIndex = -2
        collectionView.reloadData()
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
    func deselected() {
        if selectedIndex == -1 {
            return
        }
        selectedIndex = -1
        stopMusic(false)
    }
    func scrollToSelected() {
        if selectedIndex == -1 {
            return
        }
        collectionView.scrollToItem(
            at: .init(item: selectedIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
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
            audioURL: .temp(fileName: ""),
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
        bgMaskLayer.frame = .init(x: 0, y: -25, width: width, height: height + 25)
        
        let margin: CGFloat = 30
        let volumeTextWidth = volumeButton.currentTitle?.width(
            ofFont: UIFont.mediumPingFang(ofSize: 14),
            maxHeight: 30
        ) ?? 0
        var volumeButtonWidth = volumeTextWidth + (volumeButton.currentImage?.width ?? 0) + 20
        if volumeButtonWidth < 65 {
            volumeButtonWidth = 65
        }
        volumeBgView.frame = .init(x: 0, y: 0, width: volumeButtonWidth, height: 30)
        if config.showSearch {
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
            volumeBgView.x = width - UIDevice.rightMargin - margin - volumeButtonWidth
        }else {
            volumeBgView.x = UIDevice.leftMargin + margin
        }
        volumeButton.frame = volumeBgView.bounds
        
        pageWidth = width - margin * 2 - UIDevice.leftMargin - UIDevice.rightMargin + flowLayout.minimumLineSpacing
        collectionView.frame = CGRect(x: 0, y: volumeBgView.frame.maxY + 15, width: width, height: 90)
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
}

extension EditorMusicView: UICollectionViewDataSource,
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
            withReuseIdentifier: "EditorMusicViewCellID",
            for: indexPath
        ) as! EditorMusicViewCell
        cell.delegate = self
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
        let finalPoint = targetContentOffset.pointee
        let pageWidth = pageWidth
        let startX = pageWidth * CGFloat(centerIndex)
        var index = centerIndex
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
        centerIndex = index
        targetContentOffset.pointee.x = offsetX
        if config.autoPlayWhenScrollingStops {
            selectedIndex = centerIndex
        }
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
        ) as? EditorMusicViewCell
        if cell?.music.isLoading == true {
            return
        }
        cell?.playMusic(completion: { [weak self] musicURL, music in
            guard let self = self else { return }
            self.backgroundButton.isSelected = true
            let shake = UIImpactFeedbackGenerator(style: .light)
            shake.prepare()
            shake.impactOccurred()
            self.delegate?.musicView(self, didSelectMusic: musicURL)
            if self.showLyricButton.isSelected {
                self.delegate?.musicView(self, didShowLyricButton: true, music: music)
            }
        })
        currentPlayIndex = selectedIndex
    }
    func stopMusic(_ didFunc: Bool = true) {
        if let beforeCell = collectionView.cellForItem(
            at: IndexPath(
                item: currentPlayIndex,
                section: 0
            )
        ) as? EditorMusicViewCell {
            if beforeCell.music.isLoading == true {
                return
            }
            beforeCell.stopMusic(didFunc)
        }else {
            if currentPlayIndex >= 0 {
                let currentMusic = musics[currentPlayIndex]
                switch currentMusic.audioURL {
                case .network(let url):
                    PhotoManager.shared.suspendTask(url)
                default:
                    break
                }
                currentMusic.isSelected = false
            }
            if didFunc {
                delegate?.musicView(stopPlay: self)
            }
        }
        currentPlayIndex = -2
        delegate?.musicView(self, deselectMusic: didFunc)
    }
}

extension EditorMusicView: EditorMusicViewCellDelegate {
    func musicViewCell(
        _ viewCell: EditorMusicViewCell,
        didPlay musicURL: VideoEditorMusicURL,
        playCompletion: @escaping (() -> Void)
    ) -> Bool {
        if let isSuccess = delegate?.musicView(self, didPlay: musicURL, playCompletion: playCompletion) {
            return isSuccess
        }
        return false
    }
    
    func musicViewCell(_ viewCell: EditorMusicViewCell, playCompletion: @escaping (() -> Void)) {
        delegate?.musicView(self, playCompletion: playCompletion)
    }
    
    func musicViewCell(playTime viewCell: EditorMusicViewCell) -> TimeInterval? {
        delegate?.musicView(playTime: self)
    }
    
    func musicViewCell(musicDuration viewCell: EditorMusicViewCell) -> TimeInterval? {
        delegate?.musicView(musicDuration: self)
    }
    
    func musicViewCell(stopPlay viewCell: EditorMusicViewCell) {
        delegate?.musicView(stopPlay: self)
    }
    
}
