//
//  PhotoBrowserViewController.swift
//  Example
//
//  Created by Slience on 2021/8/7.
//

import UIKit
import HXPhotoPicker
import Kingfisher

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
        
        let clearBtn = UIBarButtonItem.init(
            title: "清空缓存",
            style: .done,
            target: self,
            action: #selector(didClearButtonClick)
        )
        navigationItem.rightBarButtonItems = [clearBtn]
        
        let networkVideoURL = URL.init(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/IMG_3385.MP4")!
        let networkVideoAsset = PhotoAsset.init(networkVideoAsset: .init(videoURL: networkVideoURL))
        previewAssets.append(networkVideoAsset)
        
        // swiftlint:disable line_length
        let networkVideoURL1 = URL.init(string: "https://vd4.bdstatic.com/mda-niumk6kecunfhcqw/sc/cae_h264/1664464908581666807/mda-niumk6kecunfhcqw.mp4?v_from_s=hkapp-haokan-nanjing&auth_key=1671876955-0-0-d5348c926143621c0bab7727cb920cb7&bcevod_channel=searchbox_feed&pd=1&cd=0&pt=3&logid=2755343050&vid=4949060647341250402&abtest=106570_1-106693_2&klogid=2755343050")!
        let networkVideoAsset1 = PhotoAsset.init(networkVideoAsset: .init(videoURL: networkVideoURL1))
        previewAssets.append(networkVideoAsset1)
        
        #if canImport(Kingfisher)
        let networkImageURL = URL.init(string: "https://wx4.sinaimg.cn/large/a6a681ebgy1gojng2qw07g208c093qv6.gif")!
        let networkImageAsset = PhotoAsset.init(networkImageAsset: NetworkImageAsset.init(thumbnailURL: networkImageURL, originalURL: networkImageURL)) // swiftlint:disable:this line_length
        previewAssets.append(networkImageAsset)
        #endif
        
        if let filePath = Bundle.main.path(forResource: "IMG_0168", ofType: "GIF") {
            let gifAsset = PhotoAsset.init(localImageAsset: .init(imageURL: URL.init(fileURLWithPath: filePath)))
            previewAssets.append(gifAsset)
        }
        if let filePath = Bundle.main.path(forResource: "videoeditormatter", ofType: "MP4") {
            let videoAsset = PhotoAsset.init(localVideoAsset: .init(videoURL: URL.init(fileURLWithPath: filePath)))
            previewAssets.append(videoAsset)
        }
        
       let localLivePhotoAsset = PhotoAsset(
           localLivePhoto: .init(
               imageURL: URL(string: "https://f7.baidu.com/it/u=500783997,1623136713&fm=222&app=108&f=PNG@s_0,w_800,h_1000,q_80,f_auto")!,
               videoURL: URL(string: "https://vd3.bdstatic.com/mda-nadbjpk0hnxwyndu/720p/h264_delogo/1642148105214867253/mda-nadbjpk0hnxwyndu.mp4?v_from_s=hkapp-haokan-nanjing&auth_key=1671854745-0-0-fa941c9ac0a6fe5e56d7c6fd5739ff92&bcevod_channel=searchbox_feed&pd=1&cd=0&pt=3&logid=2145586357&vid=5423681428712102654&abtest=106570_1-106693_2&klogid=2145586357")!
           )
       )
        previewAssets.append(localLivePhotoAsset)
        
        let networkImageAsset1 = PhotoAsset(NetworkImageAsset(
            thumbnailURL: URL(string: "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fimg.bugela.com%2Fuploads%2F2021%2F04%2F19%2F9c91167166fbb24fa92e2c1b42994bc6.jpg&refer=http%3A%2F%2Fimg.bugela.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1674462223&t=445ae11e5b013d9ed8f3e5ce513122fe")!,
            originalURL: URL(string: "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fup.enterdesk.com%2Fedpic%2Fd0%2F72%2F0d%2Fd0720db0956708d6a9f0b387597be31f.jpg&refer=http%3A%2F%2Fup.enterdesk.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1674462223&t=1764652e87980463227cba3c6fb6fe25")!,
            thumbnailLoadMode: .varied,
            originalLoadMode: .alwaysThumbnail
        ))
        previewAssets.append(networkImageAsset1)
        
        let networkImageAsset2 = PhotoAsset(NetworkImageAsset(
            thumbnailURL: URL(string: "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fup.enterdesk.com%2Fedpic%2F75%2Fdc%2F50%2F75dc50577d3d3d2bd5fd8db728e7bf77.jpg&refer=http%3A%2F%2Fup.enterdesk.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1674462223&t=d216c4dae3c9d5f6fee735ec7fbe8771")!,
            originalURL: URL(string: "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fup.enterdesk.com%2Fedpic_source%2Fb0%2Fd1%2Ff3%2Fb0d1f35504e4106d48c84434f2298ada.jpg&refer=http%3A%2F%2Fup.enterdesk.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1674462223&t=4c1031ae2527d6b98a17481ca24058db")!,
            thumbnailLoadMode: .varied,
            originalLoadMode: .alwaysThumbnail
        ))
        previewAssets.append(networkImageAsset2)
        
        let networkImageAsset3 = PhotoAsset(NetworkImageAsset(
            thumbnailURL: URL(string: "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fup.enterdesk.com%2Fedpic%2Fc9%2F08%2F4a%2Fc9084a6750e3293e6aeaf981f653b734.jpg&refer=http%3A%2F%2Fup.enterdesk.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1674462223&t=22adb67d04d85fa543daeb2f49de3671")!,
            originalURL: URL(string: "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fup.enterdesk.com%2Fedpic_source%2F3d%2F42%2F3e%2F3d423e3cb05d7edc35c38e3173af2a0d.jpg&refer=http%3A%2F%2Fup.enterdesk.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1674462223&t=5ccb00c0328b8ba0d522ac2e17e3a7bd")!,
            thumbnailLoadMode: .alwaysThumbnail,
            originalLoadMode: .alwaysThumbnail
        ))
        // swiftlint:enable line_length
        previewAssets.append(networkImageAsset3)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let itemWidth = Int((view.width - 24 - CGFloat(row_Count - 1))) / row_Count
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
        flowLayout.sectionInset = UIEdgeInsets(top: 20, left: 12, bottom: 20, right: 12)
        let collectionViewY = navigationController?.navigationBar.frame.maxY ?? UIDevice.navigationBarHeight
        collectionView.frame = CGRect(
            x: 0,
            y: collectionViewY,
            width: view.width,
            height: view.height - collectionViewY
        )
    }
    
    @objc func didClearButtonClick() {
        PhotoTools.removeCache()
        ImageCache.default.clearCache()
        collectionView.reloadData()
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
        cell.deleteButton.isHidden = true
        cell.photoAsset = previewAssets[indexPath.item]
        return cell
    }
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let cell = collectionView.cellForItem(
            at: indexPath
        ) as? ResultViewCell
        
        let browser = HXPhotoPicker.PhotoBrowser.show(
            previewAssets,
            pageIndex: indexPath.item,
            transitionalImage: cell?.photoView.image
        ) { index, _ in
            self.collectionView.cellForItem(
                at: IndexPath(
                    item: index,
                    section: 0
                )
            )
        }
        let button = UIButton(type: .custom)
        button.setTitle("更多", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .regularPingFang(ofSize: 16)
        button.addTarget(self, action: #selector(shwoMoreClick(button:)), for: .touchUpInside)
        browser.addRightItem(customView: button)
        currentBrowser = browser
//        browser.addRightItem(title: "更多") { [weak self] browser in
//            self?.shwoMoreAction(browser)
//        }
    }
    weak var currentBrowser: HXPhotoPicker.PhotoBrowser?
    @objc
    func shwoMoreClick(button: UIButton) {
        guard let photoBrowser = currentBrowser,
              let photoAsset = photoBrowser.currentAsset else {
            return
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if let originalURL = photoAsset.networkImageAsset?.originalURL,
           !originalURL.isCache {
            alert.addAction(.init(title: "查看原图", style: .default, handler: { [weak self] _ in
                photoAsset.loadNetworkOriginalImage { [weak self] in
                    guard let self = self else { return }
                    if let index = self.previewAssets.firstIndex(of: $0) {
                        self.collectionView.reloadItems(at: [.init(item: index, section: 0)])
                    }else {
                        self.collectionView.reloadData()
                    }
                }
            }))
        }
        alert.addAction(
            .init(
                title: "保存",
                style: .default,
                handler: { _ in
                    photoBrowser.view.hx.show(animated: true)
                    photoAsset.saveToSystemAlbum { result in
                        photoBrowser.view.hx.hide(animated: true)
                        switch result {
                        case .success:
                            photoBrowser.view.hx.showSuccess(text: "保存成功", delayHide: 1.5, animated: true)
                        case .failure:
                            photoBrowser.view.hx.showWarning(text: "保存失败", delayHide: 1.5, animated: true)
                        }
                    }
                }
            )
        )
        alert.addAction(.init(title: "取消", style: .cancel, handler: nil))
        if UIDevice.isPad {
            let pop = alert.popoverPresentationController
            pop?.permittedArrowDirections = .any
            pop?.sourceView = button
            pop?.sourceRect = CGRect(
                x: button.width * 0.5,
                y: button.height,
                width: 0,
                height: 0
            )
        }
        photoBrowser.present(alert, animated: true, completion: nil)
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
        let viewSize = view.size
        return .init(
            identifier: indexPath as NSCopying
        ) {
            let imageSize = cell.photoAsset.imageSize
            let aspectRatio = imageSize.width / imageSize.height
            let maxWidth = viewSize.width - UIDevice.leftMargin - UIDevice.rightMargin - 60
            let maxHeight = UIDevice.screenSize.height * 0.659
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
            let browser = HXPhotoPicker.PhotoBrowser.show(
                self.previewAssets,
                pageIndex: indexPath.item,
                transitionalImage: cell?.photoView.image
            ) { index, _ in
                self.collectionView.cellForItem(
                    at: IndexPath(
                        item: index,
                        section: 0
                    )
                )
            }
            let button = UIButton(type: .custom)
            button.setTitle("更多", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .regularPingFang(ofSize: 16)
            button.addTarget(self, action: #selector(self.shwoMoreClick(button:)), for: .touchUpInside)
            browser.addRightItem(customView: button)
            self.currentBrowser = browser
//            browser.addRightItem(title: "更多") { [weak self] browser in
//                self?.shwoMoreAction(browser)
//            }
        }
    }
}
