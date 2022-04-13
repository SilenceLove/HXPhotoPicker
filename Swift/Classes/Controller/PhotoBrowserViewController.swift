//
//  PhotoBrowserViewController.swift
//  Example
//
//  Created by Slience on 2021/8/7.
//

import UIKit
import HXPHPicker

class PhotoBrowserViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        return flowLayout
    }()
    lazy var collectionView: UICollectionView = {
        let view = UICollectionView.init(frame: .zero, collectionViewLayout: flowLayout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        view.register(ResultViewCell.self, forCellWithReuseIdentifier: "PhotoBrowserViewCellId")
        return view
    }()
    
    var row_Count: Int = UIDevice.current.userInterfaceIdiom == .pad ? 5 : 3
    var previewAssets: [PhotoAsset] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Photo Browser"
        view.backgroundColor = .white
        view.addSubview(collectionView)
        
        let networkVideoURL = URL.init(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/IMG_3385.MP4")!
        let networkVideoAsset = PhotoAsset.init(networkVideoAsset: .init(videoURL: networkVideoURL))
        previewAssets.append(networkVideoAsset)
        
        let networkVideoURL1 = URL.init(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/picker_examle_video.mp4")!
        let networkVideoAsset1 = PhotoAsset.init(networkVideoAsset: .init(videoURL: networkVideoURL1))
        previewAssets.append(networkVideoAsset1)
        
        #if canImport(Kingfisher)
        let networkImageURL = URL.init(string: "https://wx4.sinaimg.cn/large/a6a681ebgy1gojng2qw07g208c093qv6.gif")!
        let networkImageAsset = PhotoAsset.init(networkImageAsset: NetworkImageAsset.init(thumbnailURL: networkImageURL, originalURL: networkImageURL)) // swiftlint:disable:this line_length
        previewAssets.append(networkImageAsset)
        #endif
        
        if let filePath = Bundle.main.path(forResource: "picker_example_gif_image", ofType: "GIF") {
            let gifAsset = PhotoAsset.init(localImageAsset: .init(imageURL: URL.init(fileURLWithPath: filePath)))
            previewAssets.append(gifAsset)
        }
        if let filePath = Bundle.main.path(forResource: "videoeditormatter", ofType: "MP4") {
            let videoAsset = PhotoAsset.init(localVideoAsset: .init(videoURL: URL.init(fileURLWithPath: filePath)))
            previewAssets.append(videoAsset)
        }
        
        let networkVideoURL2 = URL.init(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/395826883-1-208.mp4")! // swiftlint:disable:this line_length
        let networkVideoAsset2 = PhotoAsset.init(networkVideoAsset: .init(videoURL: networkVideoURL2))
        previewAssets.append(networkVideoAsset2)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let itemWidth = Int((view.hx.width - 24 - CGFloat(row_Count - 1))) / row_Count
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
        flowLayout.sectionInset = UIEdgeInsets(top: 20, left: 12, bottom: 20, right: 12)
        let collectionViewY = navigationController?.navigationBar.frame.maxY ?? UIDevice.navigationBarHeight
        collectionView.frame = CGRect(
            x: 0,
            y: collectionViewY,
            width: view.hx.width,
            height: view.hx.height - collectionViewY
        )
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return previewAssets.count
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "PhotoBrowserViewCellId",
            for: indexPath
        ) as! ResultViewCell
        cell.photoAsset = previewAssets[indexPath.item]
        cell.hideDelete()
        return cell
    }
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        let cell = collectionView.cellForItem(
            at: indexPath
        ) as? ResultViewCell
        
        PhotoBrowser.show(
            previewAssets,
            pageIndex: indexPath.item,
            transitionalImage: cell?.photoView.image
        ) {
            self.collectionView.cellForItem(
                at: IndexPath(
                    item: $0,
                    section: 0
                )
            )
        }
    }
    
    @available(iOS 13.0, *)
    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ResultViewCell else {
            return nil
        }
        let viewSize = view.hx.size
        return .init(
            identifier: indexPath as NSCopying
        ) {
            let imageSize = cell.photoAsset.imageSize
            let aspectRatio = imageSize.width / imageSize.height
            let maxWidth = viewSize.width - UIDevice.leftMargin - UIDevice.rightMargin - 60
            let maxHeight = UIScreen.main.bounds.height * 0.659
            var width = imageSize.width
            var height = imageSize.height
            if width > maxWidth {
                width = maxWidth
                height = min(width / aspectRatio, maxHeight)
            }
            if height > maxHeight {
                height = maxHeight
                width = min(height * aspectRatio, maxWidth)
            }
            width = max(120, width)
            height = max(120, height)
            // 不下载，直接播放
            PhotoManager.shared.loadNetworkVideoMode = .play
            let vc = PhotoPeekViewController(cell.photoAsset)
            vc.preferredContentSize = CGSize(width: width, height: height)
            return vc
        }
    }
    
    @available(iOS 13.0, *)
    public func collectionView(
        _ collectionView: UICollectionView,
        willPerformPreviewActionForMenuWith
            configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionCommitAnimating
    ) {
        guard let indexPath = configuration.identifier as? IndexPath else {
            return
        }
        let cell = collectionView.cellForItem(
            at: indexPath
        ) as? ResultViewCell
        animator.addCompletion { [weak self] in
            guard let self = self else { return }
            PhotoBrowser.show(
                self.previewAssets,
                pageIndex: indexPath.item,
                transitionalImage: cell?.photoView.image
            ) { index in
                self.collectionView.cellForItem(
                    at: IndexPath(
                        item: index,
                        section: 0
                    )
                )
            }
        }
    }
}
