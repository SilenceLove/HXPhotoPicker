//
//  WeChatViewController.swift
//  Example
//
//  Created by Slience on 2021/8/9.
//

import UIKit
import HXPHPicker
import Photos

class WeChatViewController: UIViewController {
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.separatorStyle = .none
        view.backgroundColor = UIColor(hexString: "#eeeeee")
        view.dataSource = self
        view.delegate = self
        view.register(WeChatViewCell.classForCoder(), forCellReuseIdentifier: "WeChatViewCellID")
        return view
    }()
    lazy var pickerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("点击选择照片/视频", for: .normal)
        button.setTitleColor(UIColor(hexString: "333333"), for: .normal)
        button.backgroundColor = .white
        button.addTarget(self, action: #selector(didPickerClick), for: .touchUpInside)
        return button
    }()
    @objc func didPickerClick() {
        let config = PhotoTools.getWXPickerConfig()
        let picker = PhotoPickerController(
            picker: config,
            delegate: self
        )
        present(picker, animated: true, completion: nil)
    }
    
    var photoAssets: [PhotoAsset] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "WeChat"
        view.backgroundColor = .white
        view.addSubview(tableView)
        view.addSubview(pickerButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: 0, y: 0, width: view.hx.width, height: view.hx.height - UIDevice.bottomMargin)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        pickerButton.frame = CGRect(
            x: 0,
            y: view.hx.height - UIDevice.bottomMargin - 50,
            width: view.hx.width,
            height: 50
        )
    }
}

extension WeChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photoAssets.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "WeChatViewCellID"
        ) as! WeChatViewCell
        cell.photoAsset = photoAssets[indexPath.row]
        cell.showPicture = { [weak self] myCell in
            guard let self = self,
                  let myIndexPath = self.tableView.indexPath(for: myCell)
            else { return }
            PhotoBrowser.show(
                self.photoAssets,
                pageIndex: myIndexPath.row,
                transitionalImage: myCell.pictureView.image
            ) { index in
                let indexPath = IndexPath(
                    row: index,
                    section: 0
                )
                let cell = self.tableView.cellForRow(
                    at: indexPath
                ) as? WeChatViewCell
                return cell?.pictureView
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photoAsset = photoAssets[indexPath.row]
        return photoAsset.pictureSize.height + 20
    }
}

extension WeChatViewController: PhotoPickerControllerDelegate {
    func pickerController(
        _ pickerController: PhotoPickerController,
        didFinishSelection result: PickerResult
    ) {
        if result.photoAssets.isEmpty {
            return
        }
        var indexPaths: [IndexPath] = []
        for index in 0..<result.photoAssets.count {
            indexPaths.append(IndexPath(row: photoAssets.count + index, section: 0))
        }
        photoAssets.append(contentsOf: result.photoAssets)
        tableView.insertRows(at: indexPaths, with: .fade)
        tableView.scrollToRow(at: indexPaths.last!, at: .bottom, animated: true)
    }
}

class WeChatViewCell: UITableViewCell {
    lazy var avatarView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "wx_head_icon"))
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    lazy var playIcon: UIImageView = {
        let view = UIImageView(image: UIImage(named: "hx_picker_cell_video_play"))
        view.hx.size = CGSize(width: 50, height: 50)
        return view
    }()
    lazy var stateView: UIView = {
        let view = UIView()
        view.layer.addSublayer(stateMaskLayer)
        view.addSubview(stateLb)
        return view
    }()
    lazy var stateLb: UILabel = {
        let label = UILabel()
        label.font = UIFont.mediumPingFang(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .right
        return label
    }()
    lazy var stateMaskLayer: CAGradientLayer = {
        let layer = CAGradientLayer.init()
        layer.contentsScale = UIScreen.main.scale
        let blackColor = UIColor.black
        layer.colors = [blackColor.withAlphaComponent(0).cgColor,
                        blackColor.withAlphaComponent(0.15).cgColor,
                        blackColor.withAlphaComponent(0.35).cgColor,
                        blackColor.withAlphaComponent(0.6).cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 0, y: 1)
        layer.locations = [0.15, 0.35, 0.6, 0.9]
        layer.borderWidth = 0.0
        return layer
    }()
    lazy var pictureView: PhotoThumbnailView = {
        let view = PhotoThumbnailView()
        view.backgroundColor = UIColor(hexString: "#dadada")
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didPictureClick)))
        view.addSubview(stateView)
        view.addSubview(playIcon)
        return view
    }()
    @objc func didPictureClick() {
        showPicture?(self)
    }
    lazy var loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.hidesWhenStopped = true
        return view
    }()
    var avAsset: AVAsset?
    var photoAsset: PhotoAsset! {
        didSet {
            avAsset?.cancelLoading()
            pictureView.cancelRequest()
            pictureView.photoAsset = photoAsset
            if photoAsset.isGifAsset {
                if let photoEdit = photoAsset.photoEdit {
                    stateLb.text = photoEdit.imageType == .gif ? "GIF" : nil
                    stateMaskLayer.isHidden = photoEdit.imageType != .gif
                }else {
                    stateLb.text = "GIF"
                    stateMaskLayer.isHidden = false
                }
            }else if photoAsset.mediaSubType == .livePhoto ||
                        photoAsset.mediaSubType == .localLivePhoto {
                stateLb.text = "Live"
                stateMaskLayer.isHidden = false
            }else {
                if photoAsset.mediaType == .video {
                    if let videoTime = photoAsset.videoTime {
                        stateLb.text = videoTime
                    }else {
                        stateLb.text = nil
                        avAsset = PhotoTools.getVideoDuration(for: photoAsset) { [weak self] (asset, duration) in
                            guard let self = self else { return }
                            if self.photoAsset == asset {
                                self.stateLb.text = asset.videoTime
                            }
                        }
                    }
                    stateMaskLayer.isHidden = false
                }else {
                    stateLb.text = nil
                    stateMaskLayer.isHidden = true
                }
            }
            playIcon.isHidden = true
            loadingView.startAnimating()
            pictureView.placeholder = nil
            let targetWidth = hx.width * 2
            pictureView.requestThumbnailImage(
                targetWidth: targetWidth
            ) { [weak self] image, photoAsset in
                guard let self = self else { return }
                self.loadingView.stopAnimating()
                if self.photoAsset == photoAsset {
                    if photoAsset.mediaType == .video {
                        self.playIcon.isHidden = false
                    }
                }
            }
        }
    }
    var showPicture: ((WeChatViewCell) -> Void)?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor(hexString: "#eeeeee")
        contentView.addSubview(avatarView)
        contentView.addSubview(pictureView)
        contentView.addSubview(loadingView)
        if #available(iOS 13.0, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            pictureView.addInteraction(interaction)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarView.frame = CGRect(x: hx.width - 12 - 50, y: 20, width: 40, height: 40)
        pictureView.frame = CGRect(
            origin: .init(
                x: avatarView.hx.x - 10 - photoAsset.pictureSize.width,
                y: 20
            ),
            size: photoAsset.pictureSize
        )
        loadingView.center = pictureView.center
        playIcon.center = CGPoint(x: pictureView.hx.width * 0.5, y: pictureView.hx.height * 0.5)
        stateView.frame = CGRect(x: 0, y: pictureView.hx.height - 25, width: pictureView.hx.width, height: 25)
        stateMaskLayer.frame = CGRect(x: 0, y: -5, width: stateView.hx.width, height: 30)
        stateLb.frame = CGRect(x: 0, y: stateView.hx.height - 20, width: stateView.hx.width - 5, height: 18)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 13.0, *)
extension WeChatViewCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let viewSize = hx.viewController?.view.hx.size else {
            return nil
        }
        return .init(identifier: nil) {
            let imageSize = self.photoAsset.imageSize
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
            let vc = PhotoPeekViewController(self.photoAsset)
            vc.preferredContentSize = CGSize(width: width, height: height)
            return vc
        }
    }
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion { [weak self] in
            guard let self = self else { return }
            self.showPicture?(self)
        }
    }
}

fileprivate extension PhotoAsset {
    var pictureSize: CGSize {
        let maxWidth: CGFloat = 180
        let maxHeight: CGFloat = maxWidth / 9 * 16
        let aspectRatio = imageSize.width / imageSize.height
        var pictureWidth = imageSize.width
        var pictureHeight = imageSize.height
        if pictureWidth > maxWidth {
            pictureWidth = maxWidth
            pictureHeight = min(pictureWidth / aspectRatio, maxHeight)
        }
        if pictureHeight > maxHeight {
            pictureHeight = maxHeight
            pictureWidth = min(pictureHeight * aspectRatio, maxWidth)
        }
        pictureWidth = max(100, pictureWidth)
        pictureHeight = max(100, pictureHeight)
        return CGSize(width: pictureWidth, height: pictureHeight)
    }
}
