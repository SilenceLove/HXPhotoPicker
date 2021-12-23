//
//  EditorChartletView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/24.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

protocol EditorChartletViewDelegate: AnyObject {
    func chartletView(backClick chartletView: EditorChartletView)
    func chartletView(
        _ chartletView: EditorChartletView,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse
    )
    func chartletView(
        _ chartletView: EditorChartletView,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping EditorChartletListResponse
    )
    func chartletView(_ chartletView: EditorChartletView, didSelectImage image: UIImage, imageData: Data?)
}

class EditorChartletView: UIView {
    weak var delegate: EditorChartletViewDelegate?
    lazy var loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .white)
        view.hidesWhenStopped = true
        return view
    }()
    lazy var titleBgView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: effect)
        return view
    }()
    lazy var bgView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: effect)
        return view
    }()
    lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setImage("hx_photo_edit_pull_down".image, for: .normal)
        button.addTarget(self, action: #selector(didBackButtonClick), for: .touchUpInside)
        return button
    }()
    @objc func didBackButtonClick() {
        delegate?.chartletView(backClick: self)
    }
    lazy var titleFlowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 15
        flowLayout.minimumInteritemSpacing = 0
        return flowLayout
    }()
    lazy var titleView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: titleFlowLayout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        view.register(EditorChartletViewCell.self, forCellWithReuseIdentifier: "EditorChartletViewCellTitleID")
        let pan = UIPanGestureRecognizer(
            target: self,
            action: #selector(titleBgViewPanGestureRecognizerClick(pan:))
        )
        view.addGestureRecognizer(pan)
        return view
    }()
    var initialY: CGFloat = 0
    @objc
    func titleBgViewPanGestureRecognizerClick(pan: UIPanGestureRecognizer) {
        let point = pan.translation(in: titleBgView)
        switch pan.state {
        case .began:
            initialY = self.y
        case .changed:
            if point.y < 0 {
                y = initialY
            }else {
                y = initialY + point.y
            }
        case .ended, .cancelled, .failed:
            if point.y > 100 {
                delegate?.chartletView(backClick: self)
            }else {
                UIView.animate(withDuration: 0.25) {
                    self.y = self.initialY
                }
            }
        default:
            break
        }
    }
    lazy var listFlowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        return flowLayout
    }()
    
    lazy var listView: UICollectionView = {
        let view = UICollectionView.init(frame: .zero, collectionViewLayout: listFlowLayout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.isPagingEnabled = true
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        view.register(EditorChartletViewListCell.self, forCellWithReuseIdentifier: "EditorChartletViewListCell_ID")
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressClick(longPress:)))
        view.addGestureRecognizer(longPress)
        return view
    }()
    let editorType: EditorController.EditorType
    var previewView: EditorChartletPreviewView?
    var previewIndex: Int = -1
    let config: EditorChartletConfiguration
    var titles: [EditorChartletTitle] = []
    var selectedTitleIndex: Int = 0
    var configTitles: [EditorChartlet] = []
    init(
        config: EditorChartletConfiguration,
        editorType: EditorController.EditorType
    ) {
        self.config = config
        self.editorType = editorType
        super.init(frame: .zero)
        setupTitles(config.titles)
        addSubview(bgView)
        addSubview(listView)
        addSubview(titleBgView)
        addSubview(titleView)
        addSubview(backButton)
        addSubview(loadingView)
    }
    
    func setupTitles(_ titleChartlets: [EditorChartlet]) {
        configTitles = titleChartlets
        for (index, title) in titleChartlets.enumerated() {
            let titleChartlet: EditorChartletTitle
            if let image = title.image {
                titleChartlet = EditorChartletTitle(image: image)
            }else {
                #if canImport(Kingfisher)
                if let url = title.url {
                    titleChartlet = EditorChartletTitle(url: url)
                }else {
                    titleChartlet = .init(image: "hx_picker_album_empty".image)
                }
                #else
                titleChartlet = .init(image: "hx_picker_album_empty".image)
                #endif
            }
            if index == 0 {
                titleChartlet.isSelected = true
            }
            titles.append(titleChartlet)
        }
    }
    
    @objc func longPressClick(longPress: UILongPressGestureRecognizer) {
        guard let listCell = listView.cellForItem(
                at: IndexPath(
                    item: selectedTitleIndex,
                    section: 0
                )
        ) as? EditorChartletViewListCell else {
            return
        }
        switch longPress.state {
        case .began, .changed:
            let point = longPress.location(in: listCell.collectionView)
            if let indexPath = listCell.collectionView.indexPathForItem(at: point),
               let cell = listCell.collectionView.cellForItem(at: indexPath) as? EditorChartletViewCell {
                if previewIndex == indexPath.item {
                    return
                }
                if let beforeCell = listCell.collectionView.cellForItem(
                    at: IndexPath(
                        item: previewIndex,
                        section: 0
                    )
                ) as? EditorChartletViewCell {
                    beforeCell.showSelectedBgView = false
                }
                previewView?.removeFromSuperview()
                previewView = nil
                previewIndex = indexPath.item
                let keyWindow = UIApplication.shared.keyWindow
                let rect = cell.convert(cell.bounds, to: keyWindow)
                let touchCenter = CGPoint(x: rect.midX, y: rect.midY)
                #if canImport(Kingfisher)
                if let image = cell.chartlet.image {
                    previewView = EditorChartletPreviewView(
                        image: image,
                        touch: touchCenter,
                        touchView: cell.size
                    )
                    keyWindow?.addSubview(previewView!)
                }else if let url = cell.chartlet.url {
                    previewView = EditorChartletPreviewView(
                        imageURL: url,
                        editorType: editorType,
                        touch: touchCenter,
                        touchView: cell.size
                    )
                    keyWindow?.addSubview(previewView!)
                }
                #else
                if let image = cell.chartlet.image {
                    previewView = EditorChartletPreviewView(
                        image: image,
                        touch: touchCenter,
                        touchView: cell.size
                    )
                    keyWindow?.addSubview(previewView!)
                }
                #endif
                cell.showSelectedBgView = true
            }
        case .cancelled, .ended, .failed:
            if let cell = listCell.collectionView.cellForItem(
                at: IndexPath(
                    item: previewIndex,
                    section: 0
                )
            ) as? EditorChartletViewCell {
                cell.showSelectedBgView = false
            }
            UIView.animate(withDuration: 0.2) {
                self.previewView?.alpha = 0
            } completion: { _ in
                self.previewView?.removeFromSuperview()
                self.previewView = nil
                self.previewIndex = -1
            }
        default:
            break
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleBgView.frame = CGRect(x: 0, y: 0, width: width, height: 50)
        backButton.frame = CGRect(x: width - 50 - UIDevice.rightMargin, y: 0, width: 50, height: 50)
        bgView.frame = CGRect(x: 0, y: titleBgView.frame.maxY, width: width, height: height - titleBgView.height)
        titleView.frame = CGRect(x: 0, y: 0, width: width, height: 50)
        titleView.contentInset = UIEdgeInsets(
            top: 5,
            left: 15 + UIDevice.leftMargin,
            bottom: 5,
            right: backButton.width + UIDevice.rightMargin
        )
        listView.frame = bounds
        loadingView.center = CGPoint(x: width * 0.5, y: height * 0.5)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorChartletView: UICollectionViewDataSource,
                              UICollectionViewDelegate,
                              UICollectionViewDelegateFlowLayout,
                              EditorChartletViewListCellDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        titles.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if collectionView == titleView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "EditorChartletViewCellTitleID",
                for: indexPath
            ) as! EditorChartletViewCell
            cell.editorType = editorType
            let titleChartlet = titles[indexPath.item]
            cell.titleChartlet = titleChartlet
            return cell
        }else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "EditorChartletViewListCell_ID",
                for: indexPath
            ) as! EditorChartletViewListCell
            cell.editorType = editorType
            cell.rowCount = config.rowCount
            cell.delegate = self
            return cell
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if collectionView == titleView {
            return CGSize(width: 40, height: 40)
        }else {
            return listView.size
        }
    }
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if collectionView != listView {
            return
        }
        if config.loadScene == .cellDisplay {
            requestData(index: indexPath.item)
        }
        let titleChartlet = titles[indexPath.item]
        if !titleChartlet.chartletList.isEmpty || !titleChartlet.isLoading {
            let listCell = cell as! EditorChartletViewListCell
            listCell.chartletList = titleChartlet.chartletList
            return
        }
        let listCell = cell as! EditorChartletViewListCell
        listCell.startLoading()
    }
    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if collectionView != listView {
            return
        }
        let listCell = cell as! EditorChartletViewListCell
        listCell.stopLoad()
    }
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: false)
        if collectionView == titleView {
            listView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            requestData(index: indexPath.item)
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != listView {
            return
        }
        let currentIndex = currentIndex()
        if currentIndex == selectedTitleIndex {
            return
        }
        let indexPath = IndexPath(item: currentIndex, section: 0)
        titleView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        let titleCell = titleView.cellForItem(at: indexPath) as? EditorChartletViewCell
        titleCell?.isSelectedTitle = true
        titles[currentIndex].isSelected = true
        
        let selectedCell = titleView.cellForItem(
            at: IndexPath(
                item: selectedTitleIndex,
                section: 0
            )
        ) as? EditorChartletViewCell
        selectedCell?.isSelectedTitle = false
        titles[selectedTitleIndex].isSelected = false
        
        selectedTitleIndex = currentIndex
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView != listView {
            return
        }
        if config.loadScene == .scrollStop {
            requestData(index: currentIndex())
        }
    }
    
    func currentIndex() -> Int {
        let offsetX = listView.contentOffset.x  + (listView.width) * 0.5
        var currentIndex = Int(offsetX / listView.width)
        if currentIndex > titles.count - 1 {
            currentIndex = titles.count - 1
        }
        if currentIndex < 0 {
            currentIndex = 0
        }
        return currentIndex
    }
    
    func requestData(index: Int) {
        let titleChartle = titles[index]
        if !titleChartle.chartletList.isEmpty || titleChartle.isLoading || configTitles.isEmpty {
            return
        }
        titleChartle.isLoading = true
        if let listHandler = config.listHandler {
            listHandler(index) { [weak self] titleIndex, chartletList in
                guard let self = self else { return }
                titleChartle.isLoading = false
                self.titles[titleIndex].chartletList = chartletList
                let cell = self.listView.cellForItem(
                    at: IndexPath(item: titleIndex, section: 0)
                ) as? EditorChartletViewListCell
                cell?.chartletList = titleChartle.chartletList
                cell?.stopLoad()
            }
            return
        }
        delegate?.chartletView(
            self,
            titleChartlet: configTitles[index],
            titleIndex: index,
            loadChartletList: { [weak self] item, chartletList in
                guard let self = self else { return }
                titleChartle.isLoading = false
                self.titles[item].chartletList = chartletList
                let cell = self.listView.cellForItem(
                    at: IndexPath(item: item, section: 0)
                ) as? EditorChartletViewListCell
                cell?.chartletList = titleChartle.chartletList
                cell?.stopLoad()
        })
    }
    func firstRequest() {
        if titles.isEmpty {
            loadingView.startAnimating()
            if let titleHandler = config.titleHandler {
                titleHandler { [weak self] titleChartlets in
                    self?.loadTitlesCompletion(titleChartlets)
                }
            }else {
                delegate?.chartletView(self, loadTitleChartlet: { [weak self] titleChartlets in
                    self?.loadTitlesCompletion(titleChartlets)
                })
            }
            return
        }
        requestData(index: 0)
    }
    func loadTitlesCompletion(_ titles: [EditorChartlet]) {
        loadingView.stopAnimating()
        setupTitles(titles)
        if config.loadScene == .scrollStop {
            requestData(index: 0)
        }
        titleView.reloadData()
        listView.reloadData()
    }
    func listCell(_ cell: EditorChartletViewListCell, didSelectImage image: UIImage, imageData: Data?) {
        delegate?.chartletView(self, didSelectImage: image, imageData: imageData)
    }
}
