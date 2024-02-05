//
//  EditorMusicListViewController.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/6/7.
//

import UIKit
import AVFoundation

protocol EditorMusicListViewControllerDelegate: AnyObject {
    func musicViewController(
        _ musicViewController: EditorMusicListViewController,
        didSelectItem musicURL: VideoEditorMusicURL,
        music: VideoEditorMusic
    )
    func musicViewController(clearSearch musicViewController: EditorMusicListViewController)
    func musicViewController(
        _ musicViewController: EditorMusicListViewController,
        didSearch text: String?,
        completion: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    )
    func musicViewController(
        _ musicViewController: EditorMusicListViewController,
        loadMore text: String?,
        completion: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    )
    func musicViewController(deselectItem musicViewController: EditorMusicListViewController)
    
    @discardableResult
    func musicViewController(
        _ musicViewController: EditorMusicListViewController,
        didPlay musicURL: VideoEditorMusicURL,
        playCompletion: @escaping (() -> Void)
    ) -> Bool
    func musicViewController(
        _ musicViewController: EditorMusicListViewController,
        playCompletion: @escaping (() -> Void)
    )
    func musicViewController(playTime musicViewController: EditorMusicListViewController) -> TimeInterval?
    func musicViewController(musicDuration musicViewController: EditorMusicListViewController) -> TimeInterval?
    func musicViewController(stopPlay musicViewController: EditorMusicListViewController)
}

class EditorMusicListViewController: BaseViewController {
    weak var delegate: EditorMusicListViewControllerDelegate?
    private var loadBgView: UIView!
    private var loadingView: UIActivityIndicatorView!
    private var bgView: UIVisualEffectView!
    private var finishButton: UIButton!
    private var searchBgView: UIVisualEffectView!
    private var searchView: SearchView!
    private var flowLayout: UICollectionViewFlowLayout!
    private var collectionView: UICollectionView!
    private var noMoreView: UIView!
    private var noMoreLine: CAShapeLayer!
    
    var searchText: String?
    var currentSelectItem: Int = -1
    var musics: [VideoEditorMusic] = []
    var isLoading = false
    var isLoadMore = false
    var hasMore = false
    var isSearchData = false
    let config: EditorConfiguration.Music
    let defaultMusics: [VideoEditorMusic]
    init(config: EditorConfiguration.Music, defaultMusics: [VideoEditorMusic] = []) {
        self.config = config
        self.defaultMusics = defaultMusics
        self.musics = defaultMusics
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
        view.backgroundColor = .clear
        title = .textManager.editor.music.listTitle.text
        if !config.infos.isEmpty {
            musics = getMusics(infos: config.infos)
            hasMore = true
            removeNoMore()
        }else {
            for (index, music) in defaultMusics.enumerated() where music.isSelected {
                 currentSelectItem = index
            }
            hasMore = !defaultMusics.isEmpty
            if hasMore {
                removeNoMore()
            }
        }
        var finishButtonWidth = finishButton.currentTitle?.width(
            ofFont: finishButton.titleLabel!.font,
            maxHeight: 50
        ) ?? 0
        if config.finishButtonBackgroundColor != .clear {
            finishButtonWidth += 20
            if finishButton.width < 55 {
                finishButton.width = 55
            }
        }
        finishButton.width = finishButtonWidth
        finishButton.height = 30
        navigationItem.rightBarButtonItem = .init(customView: finishButton)
        view.addSubview(bgView)
        view.addSubview(searchBgView)
        view.addSubview(searchView)
        view.addSubview(collectionView)
        searchView.becomeFirstResponder()
    }
    
    private func initViews() {
        loadingView = UIActivityIndicatorView(style: .white)
        loadingView.hidesWhenStopped = true
        loadBgView = UIView()
        loadBgView.addSubview(loadingView)
        
        finishButton = UIButton(type: .system)
        let title: String = .textManager.editor.music.finishTitle.text
        let font: UIFont = .textManager.editor.music.finishTitleFont
        finishButton.setTitle(title, for: .normal)
        finishButton.setTitleColor(config.finishButtonTitleColor, for: .normal)
        if config.finishButtonBackgroundColor != .clear {
            let image = UIImage.image(
                for: config.finishButtonBackgroundColor,
                havingSize: CGSize(
                    width: title.width(ofFont: font, maxHeight: 35),
                    height: 30
                ),
                radius: 3
            )
            finishButton.setBackgroundImage(image, for: .normal)
        }
        finishButton.titleLabel?.font = font
        finishButton.isEnabled = false
        finishButton.addTarget(self, action: #selector(didFinishButtonClick), for: .touchUpInside)
        
        searchView = SearchView()
        searchView.textColor = .white
        searchView.tintColor = config.tintColor
        searchView.attributedPlaceholder = NSAttributedString(
            string: config.placeholder,
            attributes: [
                .font: UIFont.textManager.editor.music.searchPlaceholderFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.4)
            ]
        )
        searchView.font = .systemFont(ofSize: 17)
        searchView.clearButtonMode = .whileEditing
        searchView.returnKeyType = .search
        let searchIcon = UIImageView()
        searchIcon.image = .imageResource.editor.music.search.image?.withRenderingMode(.alwaysTemplate)
        searchIcon.tintColor = .white.withAlphaComponent(0.4)
        searchIcon.size = searchIcon.image?.size ?? .zero
        searchView.leftView = searchIcon
        searchView.leftViewMode = .always
        searchView.layer.cornerRadius = 10
        searchView.layer.masksToBounds = true
        searchView.delegate = self
        
        let visualEffect = UIBlurEffect(style: .light)
        searchBgView = UIVisualEffectView.init(effect: visualEffect)
        searchBgView.layer.cornerRadius = 10
        searchBgView.layer.masksToBounds = true
        searchBgView.alpha = 0.5
        
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 15
        flowLayout.minimumInteritemSpacing = 0
        
        collectionView = UICollectionView(
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
        collectionView.register(EditorMusicViewCell.self, forCellWithReuseIdentifier: "EditorMusicViewCellID")
        
        noMoreLine = CAShapeLayer()
        noMoreLine.contentsScale = UIScreen._scale
        noMoreLine.fillColor = UIColor.white.withAlphaComponent(0.5).cgColor
        noMoreLine.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        noMoreLine.lineCap = .round
        noMoreLine.lineJoin = .round
        noMoreLine.lineWidth = 1
        
        noMoreView = UIView()
        noMoreView.layer.addSublayer(noMoreLine)
        
        let darkEffect = UIBlurEffect.init(style: .dark)
        bgView = UIVisualEffectView.init(effect: darkEffect)
    }
    
    @objc
    private func didFinishButtonClick() {
        dismiss(animated: true)
    }
    
    func deselect() {
        if currentSelectItem >= 0 {
            if let cell = collectionView.cellForItem(
                at: IndexPath(item: currentSelectItem, section: 0)
            ) as? EditorMusicViewCell {
                cell.stopMusic()
            }else {
                musics[currentSelectItem].isSelected = false
                let audioURL = musics[currentSelectItem].audioURL
                switch audioURL {
                case .network(let url):
                    PhotoManager.shared.suspendTask(url)
                default:
                    break
                }
                delegate?.musicViewController(stopPlay: self)
            }
            currentSelectItem = -1
            delegate?.musicViewController(deselectItem: self)
        }
    }
    func clearData() {
        searchText = nil
        searchView.text = nil
        musics.removeAll()
        stopLoading()
        removeNoMore()
        collectionView.reloadData()
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgView.frame = view.bounds
        let navHeight = navigationController?.navigationBar.frame.maxY ?? UIDevice.navigationBarHeight
        searchView.frame = CGRect(
            x: 12 + UIDevice.leftMargin,
            y: navHeight + 12,
            width: view.width - 24 - UIDevice.leftMargin - UIDevice.rightMargin,
            height: 35
        )
        searchBgView.frame = searchView.frame
        
        setupCollectionInset()
        collectionView.frame = CGRect(
            x: 0,
            y: searchView.frame.maxY + 12,
            width: view.width,
            height: view.height - searchView.frame.maxY - 12
        )
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setBackgroundImage(.image(for: .clear, havingSize: .zero), for: .default)
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorMusicListViewController: UICollectionViewDataSource,
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
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        view.endEditing(true)
        collectionView.deselectItem(at: indexPath, animated: false)
        if currentSelectItem == indexPath.item {
            return
        }
        if currentSelectItem >= 0 {
            if let lastCell = collectionView.cellForItem(
                at: IndexPath(item: currentSelectItem, section: 0)
            ) as? EditorMusicViewCell {
                lastCell.stopMusic()
            }else {
                musics[currentSelectItem].isSelected = false
                let audioURL = musics[currentSelectItem].audioURL
                switch audioURL {
                case .network(let url):
                    PhotoManager.shared.suspendTask(url)
                default:
                    break
                }
                delegate?.musicViewController(stopPlay: self)
            }
        }
        let cell = collectionView.cellForItem(at: indexPath) as! EditorMusicViewCell
        cell.playMusic { [weak self] musicURL, music  in
            guard let self = self else { return }
            let shake = UIImpactFeedbackGenerator(style: .light)
            shake.prepare()
            shake.impactOccurred()
            self.delegate?.musicViewController(self, didSelectItem: musicURL, music: music)
        }
        currentSelectItem = indexPath.item
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: view.width - collectionView.contentInset.left - collectionView.contentInset.right, height: 90)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let maxOffsetY = contentHeight - scrollView.height + scrollView.contentInset.bottom
        if offsetY > maxOffsetY - 100 && hasMore {
            if !isLoadMore && !isLoading && !musics.isEmpty {
                isLoadMore = true
                startLoading(isMore: true)
                delegate?.musicViewController(
                    self,
                    loadMore: searchText,
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
        view.endEditing(true)
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
extension EditorMusicListViewController: EditorMusicViewCellDelegate {
    func musicViewCell(
        _ viewCell: EditorMusicViewCell,
        didPlay musicURL: VideoEditorMusicURL,
        playCompletion: @escaping (() -> Void)
    ) -> Bool {
        if let isSuccess = delegate?.musicViewController(self, didPlay: musicURL, playCompletion: playCompletion) {
            return isSuccess
        }
        return false
    }
    
    func musicViewCell(_ viewCell: EditorMusicViewCell, playCompletion: @escaping (() -> Void)) {
        delegate?.musicViewController(self, playCompletion: playCompletion)
    }
    
    func musicViewCell(playTime viewCell: EditorMusicViewCell) -> TimeInterval? {
        delegate?.musicViewController(playTime: self)
    }
    
    func musicViewCell(musicDuration viewCell: EditorMusicViewCell) -> TimeInterval? {
        delegate?.musicViewController(musicDuration: self)
    }
    
    func musicViewCell(stopPlay viewCell: EditorMusicViewCell) {
        delegate?.musicViewController(stopPlay: self)
    }
}
extension EditorMusicListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        let text = textField.text
        removeNoMore()
        if let text = text, text.isEmpty {
            searchText = nil
            if isSearchData {
                deselect()
                if config.infos.isEmpty {
                    musics = defaultMusics
                }else {
                    musics = getMusics(infos: config.infos)
                }
                collectionView.reloadData()
            }
            isSearchData = false
            hasMore = true
            stopLoading()
            delegate?.musicViewController(clearSearch: self)
            return true
        }
        isLoadMore = false
        stopLoading()
        deselect()
        clearData()
        textField.text = text
        searchText = text
        startLoading(isMore: false)
        collectionView.contentOffset.y = -collectionView.contentInset.top
        delegate?.musicViewController(
            self,
            didSearch: text,
            completion: { [weak self] musicInfos, hasMore in
            guard let self = self else { return }
                self.isSearchData = true
                self.stopLoading()
                let musics = self.getMusics(infos: musicInfos)
                self.musics.append(contentsOf: musics)
                self.collectionView.reloadData()
                self.hasMore = hasMore
                DispatchQueue.main.async {
                    if !hasMore {
                        self.addNoMore()
                    }else {
                        self.removeNoMore()
                    }
                }
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
        let contentHeight = musics.isEmpty ? 0 : collectionView.contentSize.height
        noMoreView.frame = CGRect(
            x: 0,
            y: contentHeight + top + 10,
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

extension EditorMusicListViewController {
    
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
