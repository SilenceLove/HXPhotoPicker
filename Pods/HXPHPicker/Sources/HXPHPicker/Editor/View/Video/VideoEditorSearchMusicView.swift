//
//  VideoEditorSearchMusicView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/29.
//

import UIKit

protocol VideoEditorSearchMusicViewDelegate: AnyObject {
    func searchMusicView(didCancelClick searchMusicView: VideoEditorSearchMusicView)
    func searchMusicView(didFinishClick searchMusicView: VideoEditorSearchMusicView)
    func searchMusicView(_ searchMusicView: VideoEditorSearchMusicView,
                         didSelectItem audioPath: String?,
                         music: VideoEditorMusic)
    func searchMusicView(_ searchMusicView: VideoEditorSearchMusicView,
                         didSearch text: String?,
                         completion: @escaping ([VideoEditorMusicInfo], Bool) -> Void)
    func searchMusicView(_ searchMusicView: VideoEditorSearchMusicView,
                         loadMore text: String?,
                         completion: @escaping ([VideoEditorMusicInfo], Bool) -> Void)
    func searchMusicView(deselectItem searchMusicView: VideoEditorSearchMusicView)
}

class VideoEditorSearchMusicView: UIView {
    weak var delegate: VideoEditorSearchMusicViewDelegate?
    lazy var loadBgView: UIView = {
        let view = UIView()
        view.addSubview(loadingView)
        return view
    }()
    lazy var loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .white)
        view.hidesWhenStopped = true
        return view
    }()
    lazy var bgView: UIVisualEffectView = {
        let visualEffect = UIBlurEffect.init(style: .dark)
        let view = UIVisualEffectView.init(effect: visualEffect)
        return view
    }()
    lazy var topView: UIView = {
        let view = UIView()
        view.addSubview(cancelButton)
        view.addSubview(titleLb)
        view.addSubview(finishButton)
        return view
    }()
    lazy var titleLb: UILabel = {
        let label = UILabel()
        label.text = "背景音乐".localized
        label.textColor = .white
        label.textAlignment = .center
        label.font = .mediumPingFang(ofSize: 17)
        return label
    }()
    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消".localized, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.addTarget(self, action: #selector(didCancelButtonClick), for: .touchUpInside)
        return button
    }()
    @objc func didCancelButtonClick() {
        delegate?.searchMusicView(didCancelClick: self)
    }
    lazy var finishButton: UIButton = {
        let button = UIButton(type: .system)
        let title = "完成".localized
        let font = UIFont.systemFont(ofSize: 16)
        let image = UIImage.image(
            for: config.tintColor,
            havingSize: CGSize(
                width: title.width(ofFont: font, maxHeight: 35),
                height: 30
            ),
            radius: 3
        )
        let disabledImage = UIImage.image(
            for: .white.withAlphaComponent(0.2),
            havingSize: CGSize(
                width: title.width(ofFont: font, maxHeight: 30),
                height: 30
            ),
            radius: 3
        )
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.white.withAlphaComponent(0.6), for: .disabled)
        button.setBackgroundImage(image, for: .normal)
        button.setBackgroundImage(disabledImage, for: .disabled)
        button.titleLabel?.font = font
        button.isEnabled = false
        button.addTarget(self, action: #selector(didFinishButtonClick), for: .touchUpInside)
        return button
    }()
    @objc func didFinishButtonClick() {
        delegate?.searchMusicView(didFinishClick: self)
        currentSelectItem = -1
    }
    lazy var searchBgView: UIVisualEffectView = {
        let visualEffect = UIBlurEffect.init(style: .light)
        let view = UIVisualEffectView.init(effect: visualEffect)
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.alpha = 0.5
        return view
    }()
    lazy var searchView: SearchView = {
        let view = SearchView()
        view.textColor = .white
        view.tintColor = config.tintColor
        view.attributedPlaceholder = NSAttributedString(
            string: config.placeholder.isEmpty ?
                "搜索歌名".localized :
                config.placeholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.white.withAlphaComponent(0.4)
            ]
        )
        view.font = .systemFont(ofSize: 17)
        view.clearButtonMode = .whileEditing
        view.returnKeyType = .search
        let searchIcon = UIImageView()
        searchIcon.image = "hx_editor_video_music_search".image?.withRenderingMode(.alwaysTemplate)
        searchIcon.tintColor = .white.withAlphaComponent(0.4)
        searchIcon.size = searchIcon.image?.size ?? .zero
        view.leftView = searchIcon
        view.leftViewMode = .always
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.delegate = self
        return view
    }()
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 15
        flowLayout.minimumInteritemSpacing = 0
        return flowLayout
    }()
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: CGRect(
                x: 0, y: 0,
                width: 0, height: 90
            ),
            collectionViewLayout: flowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(VideoEditorMusicViewCell.self, forCellWithReuseIdentifier: "VideoEditorMusicViewCellID")
        return collectionView
    }()
    lazy var noMoreView: UIView = {
        let view = UIView()
        view.layer.addSublayer(noMoreLine)
        return view
    }()
    lazy var noMoreLine: CAShapeLayer = {
        let noMoreLine = CAShapeLayer()
        noMoreLine.contentsScale = UIScreen.main.scale
        noMoreLine.fillColor = UIColor.white.withAlphaComponent(0.5).cgColor
        noMoreLine.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        noMoreLine.lineCap = .round
        noMoreLine.lineJoin = .round
        noMoreLine.lineWidth = 1
        return noMoreLine
    }()
    var currentSelectItem: Int = -1
    var musics: [VideoEditorMusic] = []
    var isLoading = false
    var isLoadMore = false
    var hasMore = false
    let config: VideoEditorConfiguration.Music
    init(config: VideoEditorConfiguration.Music) {
        self.config = config
        super.init(frame: .zero)
        musics = getMusics(infos: config.infos)
        addSubview(bgView)
        addSubview(topView)
        addSubview(searchBgView)
        addSubview(searchView)
        addSubview(collectionView)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    @objc func appDidEnterBackground() {
        deselect()
    }
    func deselect() {
        if currentSelectItem >= 0 {
            if let cell = collectionView.cellForItem(
                at: IndexPath(item: currentSelectItem, section: 0)
            ) as? VideoEditorMusicViewCell {
                cell.stopMusic()
            }else {
                musics[currentSelectItem].isSelected = false
                let url = musics[currentSelectItem].audioURL
                PhotoManager.shared.suspendTask(url)
                PhotoManager.shared.stopPlayMusic()
            }
            currentSelectItem = -1
            delegate?.searchMusicView(deselectItem: self)
        }
        finishButton.isEnabled = false
    }
    func clearData() {
        searchView.text = nil
        musics.removeAll()
        stopLoading()
        removeNoMore()
        collectionView.reloadData()
        finishButton.isEnabled = false
    }
    func reloadData() {
        collectionView.reloadData()
        DispatchQueue.main.async {
            self.setupCollectionInset()
        }
    }
    func getMusics(infos: [VideoEditorMusicInfo]) -> [VideoEditorMusic] {
        var musicArray: [VideoEditorMusic] = []
        for musicInfo in infos {
            let music = VideoEditorMusic(audioURL: musicInfo.audioURL,
                                         lrc: musicInfo.lrc)
            musicArray.append(music)
        }
        return musicArray
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        bgView.frame = bounds
        topView.frame = CGRect(x: 0, y: 0, width: width, height: 50)
        titleLb.width = titleLb.text?.width(ofFont: titleLb.font, maxHeight: 50) ?? 0
        titleLb.height = 50
        titleLb.centerX = width * 0.5
        titleLb.y = 0
        cancelButton.frame = CGRect(x: 12 + UIDevice.leftMargin, y: 0, width: 0, height: 50)
        cancelButton.width = cancelButton.currentTitle?.width(ofFont: cancelButton.titleLabel!.font, maxHeight: 50) ?? 0
        finishButton.width = (
            finishButton.currentTitle?.width(
                ofFont: finishButton.titleLabel!.font,
                maxHeight: 50
            ) ?? 0
        ) + 20
        if finishButton.width < 55 {
            finishButton.width = 55
        }
        finishButton.height = 30
        finishButton.centerY = topView.height * 0.5
        finishButton.x = width - UIDevice.rightMargin - 12 - finishButton.width
        
        searchView.frame = CGRect(
            x: 12 + UIDevice.leftMargin,
            y: topView.frame.maxY + 12,
            width: width - 24 - UIDevice.leftMargin - UIDevice.rightMargin,
            height: 35
        )
        searchBgView.frame = searchView.frame
        
        setupCollectionInset()
        collectionView.frame = CGRect(
            x: 0,
            y: searchView.frame.maxY + 12,
            width: width,
            height: height - searchView.frame.maxY - 12
        )
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    class SearchView: UITextField {
        override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
            let rect = super.leftViewRect(forBounds: bounds)
            return CGRect(
                x: (height - rect.width) * 0.5,
                y: (height - rect.height) * 0.5,
                width: rect.width,
                height: rect.height
            )
        }
        override func textRect(forBounds bounds: CGRect) -> CGRect {
            var rect = super.textRect(forBounds: bounds)
            let leftViewRect = leftViewRect(forBounds: bounds)
            rect.origin.x += leftViewRect.minX
            rect.size.width -= leftViewRect.minX
            return rect
        }
        override func editingRect(forBounds bounds: CGRect) -> CGRect {
            var rect = super.editingRect(forBounds: bounds)
            let leftViewRect = leftViewRect(forBounds: bounds)
            rect.origin.x += leftViewRect.minX
            rect.size.width -= leftViewRect.minX
            return rect
        }
        override func layoutSubviews() {
            super.layoutSubviews()
            for view in subviews {
                if let button = view as? UIButton {
                    button.setImage(button.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
                    button.tintColor = .white.withAlphaComponent(0.4)
                }
            }
        }
    }
}
extension VideoEditorSearchMusicView: UICollectionViewDataSource,
                                      UICollectionViewDelegate,
                                      UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        musics.count
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "VideoEditorMusicViewCellID",
            for: indexPath
        ) as! VideoEditorMusicViewCell
        cell.music = musics[indexPath.item]
        return cell
    }
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath) {
        endEditing(true)
        collectionView.deselectItem(at: indexPath, animated: false)
        if currentSelectItem == indexPath.item {
            return
        }
        if currentSelectItem >= 0 {
            if let lastCell = collectionView.cellForItem(
                at: IndexPath(item: currentSelectItem, section: 0)
            ) as? VideoEditorMusicViewCell {
                lastCell.stopMusic()
            }else {
                musics[currentSelectItem].isSelected = false
                let url = musics[currentSelectItem].audioURL
                PhotoManager.shared.suspendTask(url)
                PhotoManager.shared.stopPlayMusic()
            }
        }
        let cell = collectionView.cellForItem(at: indexPath) as! VideoEditorMusicViewCell
        cell.playMusic { [weak self] path, music  in
            guard let self = self else { return }
            let shake = UIImpactFeedbackGenerator(style: .light)
            shake.prepare()
            shake.impactOccurred()
            self.delegate?.searchMusicView(self, didSelectItem: path, music: music)
        }
        currentSelectItem = indexPath.item
        finishButton.isEnabled = true
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: width - collectionView.contentInset.left - collectionView.contentInset.right, height: 90)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let maxOffsetY = contentHeight - scrollView.height + scrollView.contentInset.bottom
        if offsetY > maxOffsetY - 100 && hasMore {
            if !isLoadMore && !isLoading && !musics.isEmpty {
                isLoadMore = true
                startLoading(isMore: true)
                delegate?.searchMusicView(
                    self,
                    loadMore: searchView.text,
                    completion: { [weak self] musicInfos, hasMore in
                    guard let self = self else { return }
                    self.stopLoading()
                    let musics = self.getMusics(infos: musicInfos)
                    self.musics.append(contentsOf: musics)
                    self.collectionView.reloadData()
                    DispatchQueue.main.async {
                        if !hasMore {
                            self.addNoMore()
                        }else {
                            self.removeNoMore()
                        }
                    }
                    self.hasMore = hasMore
                    self.isLoadMore = false
                })
            }
        }
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        endEditing(true)
    }
    func setupCollectionInset() {
        let top: CGFloat = 10
        let left = UIDevice.leftMargin + 12
        let bottom = UIDevice.bottomMargin + 60
        let right = UIDevice.rightMargin + 12
        if isLoading {
            if !isLoadMore {
                collectionView.contentInset = UIEdgeInsets(top: top + 40, left: left, bottom: bottom, right: right)
                loadBgView.frame = CGRect(x: 0, y: -40, width: collectionView.width - left - right, height: 40)
            }else {
                collectionView.contentInset = UIEdgeInsets(top: top, left: left, bottom: bottom + 40, right: right)
                loadBgView.frame = CGRect(
                    x: 0,
                    y: collectionView.contentSize.height + top + 10,
                    width: collectionView.width - left - right,
                    height: 40
                )
            }
        }else {
            collectionView.contentInset = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
            if !hasMore {
                noMoreView.frame = CGRect(
                    x: 0,
                    y: collectionView.contentSize.height + top + 10,
                    width: collectionView.width - left - right,
                    height: 40
                )
                updateMoreLine()
            }
        }
    }
}
extension VideoEditorSearchMusicView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing(true)
        let text = textField.text
        isLoadMore = false
        stopLoading()
        removeNoMore()
        deselect()
        clearData()
        textField.text = text
        startLoading(isMore: false)
        delegate?.searchMusicView(
            self,
            didSearch: text,
            completion: { [weak self] musicInfos, hasMore in
            guard let self = self else { return }
            self.stopLoading()
            let musics = self.getMusics(infos: musicInfos)
            self.musics.append(contentsOf: musics)
            self.collectionView.reloadData()
            DispatchQueue.main.async {
                if !hasMore {
                    self.addNoMore()
                }else {
                    self.removeNoMore()
                }
            }
            self.hasMore = hasMore
        })
        return true
    }
    
    func startLoading(isMore: Bool) {
        isLoading = true
        let top: CGFloat = 10
        let left = UIDevice.leftMargin + 12
        let bottom = UIDevice.bottomMargin + 60
        let right = UIDevice.rightMargin + 12
        if !isMore {
            collectionView.contentInset = UIEdgeInsets(top: top + 40, left: left, bottom: bottom, right: right)
            loadBgView.frame = CGRect(x: 0, y: -40, width: collectionView.width - left - right, height: 40)
        }else {
            collectionView.contentInset = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
            loadBgView.frame = CGRect(
                x: 0,
                y: collectionView.contentSize.height + top + 10,
                width: collectionView.width - left - right,
                height: 40
            )
        }
        loadingView.startAnimating()
        loadingView.centerX = loadBgView.width * 0.5
        collectionView.addSubview(loadBgView)
    }
    func stopLoading() {
        isLoading = false
        collectionView.contentInset = UIEdgeInsets(
            top: 10,
            left: UIDevice.leftMargin + 12,
            bottom: UIDevice.bottomMargin + 60,
            right: UIDevice.rightMargin + 12
        )
        loadingView.stopAnimating()
        loadBgView.removeFromSuperview()
    }
    func addNoMore() {
        let top: CGFloat = 10
        let left = UIDevice.leftMargin + 12
        let bottom = UIDevice.bottomMargin + 60
        let right = UIDevice.rightMargin + 12
        collectionView.contentInset = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        noMoreView.frame = CGRect(
            x: 0,
            y: collectionView.contentSize.height + top + 10,
            width: collectionView.width - left - right,
            height: 40
        )
        updateMoreLine()
        collectionView.addSubview(noMoreView)
    }
    func removeNoMore() {
        noMoreView.removeFromSuperview()
    }
    func updateMoreLine() {
        let arcCenter = CGPoint(x: noMoreView.width * 0.5, y: 10)
        let path = UIBezierPath(
            arcCenter: arcCenter,
            radius: 1,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: true
        )
        path.move(to: CGPoint(x: arcCenter.x - 10, y: arcCenter.y))
        path.addLine(to: CGPoint(x: arcCenter.x - 110, y: arcCenter.y))
        path.move(to: CGPoint(x: arcCenter.x + 10, y: arcCenter.y))
        path.addLine(to: CGPoint(x: arcCenter.x + 110, y: arcCenter.y))
        noMoreLine.path = path.cgPath
    }
}
