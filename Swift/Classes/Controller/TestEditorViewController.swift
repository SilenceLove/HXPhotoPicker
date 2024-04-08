//
//  TestEditorViewController.swift
//  Example
//
//  Created by Slience on 2022/11/8.
//

import UIKit
import HXPhotoPicker
import AVFoundation
#if canImport(GDPerformanceView_Swift)
import GDPerformanceView_Swift
#endif

class TestEditorViewController: HXBaseViewController {
    
    lazy var contentView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.addSubview(editorView)
        return view
    }()
    
    var image: UIImage? = .init(named: "wx_bg_image")
    var videoURL: URL!
    
    var imageResult: ImageEditedResult?
    var videoResult: VideoEditedResult?
    
    lazy var editorView: EditorView = {
        let view = EditorView()
        view.backgroundColor = self.view.backgroundColor
        view.editDelegate = self
        // 这样设置边距 进入/退出 编辑状态不会有 缩小/放大 动画
//        view.contentInset = .init(top: 20, left: 20, bottom: 20 + UIDevice.bottomMargin, right: 20)
        // 这样设置边距 进入/退出 编辑状态会有 缩小/放大 动画
        view.editContentInset = { _ in
            .init(top: 20, left: UIDevice.leftMargin + 20, bottom: 20 + UIDevice.bottomMargin, right: UIDevice.rightMargin + 20)
        }
        view.maskType = .blurEffect(style: .light)
        if let result = imageResult {
            view.setImage(image)
            setmosaicImage()
            view.setAdjustmentData(result.data)
        }else if let result = videoResult {
            view.setAVAsset(.init(url: videoURL))
            view.setAdjustmentData(result.data)
            view.loadVideo(isPlay: true)
        }else {
            view.setImage(image)
            setmosaicImage()
//            view.state = .edit
        }
//        view.isResetIgnoreFixedRatio = false
//        view.setRoundMask(animated: false)
        return view
    }()
    var currentAngle: CGFloat = 0
    var editedAngle: CGFloat = 0
    var audioPlayers: [TestPlayAuido] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "菜单",
            style: .plain,
            target: self,
            action: #selector(showAlert)
        )
        view.addSubview(contentView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didViewClick))
        editorView.addGestureRecognizer(tap)
    }
    
    var isShowVideoControl: Bool = false
    weak var videoTimer: Timer?
    @objc
    func didViewClick() {
        if editorView.state != .normal || editorView.type != .video {
            return
        }
        if !isShowVideoControl {
            editorView.showVideoControl(true)
            delayHideVideoControl()
        }else {
            editorView.hideVideoControl(true)
            videoTimer?.invalidate()
            videoTimer = nil
        }
        isShowVideoControl = !isShowVideoControl
    }
    
    func delayHideVideoControl() {
        if let timer = videoTimer {
            timer.invalidate()
        }
        videoTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
            self?.editorView.hideVideoControl(true)
            self?.isShowVideoControl = false
            self?.videoTimer = nil
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.frame = .init(x: 0, y: navigationController?.navigationBar.frame.maxY ?? 88, width: view.width, height: 0)
        contentView.height = view.height - contentView.y
        if editorView.frame.isEmpty {
            editorView.frame = contentView.bounds
        }else {
            if !editorView.frame.equalTo(contentView.bounds) {
                editorView.frame = contentView.bounds
                editorView.update()
            }
        }
    }
    
    @objc
    func showAlert() {
        let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        if editorView.type != .unknown {
            alert.addAction(.init(title: "使用编辑器继续编辑", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                var editConfig = EditorConfiguration()
                let edtiorAsset: EditorAsset
                if self.editorView.type == .image {
                    var result: EditedResult?
                    if self.editorView.isCropedImage {
                        result = .image(.init(data: self.editorView.adjustmentData), .init(cropSize: .init(isFixedRatio: self.editorView.isFixedRatio, aspectRatio: self.editorView.aspectRatio, angle: self.editorView.state == .edit ? self.currentAngle : self.editedAngle)))
                    }
                    edtiorAsset = .init(type: .image(self.image!), result: result)
                    if self.editorView.state == .edit {
                        editConfig.photo.defaultSelectedToolOption = .cropSize
                    }
                }else if self.editorView.type == .video {
                    var result: EditedResult?
                    if self.editorView.isCropedVideo {
                        var music: VideoEditedMusic?
                        if let player = self.audioPlayers.first {
                            music = .init(
                                hasOriginalSound: true,
                                videoSoundVolume: 1,
                                backgroundMusicURL: player.audio.url,
                                backgroundMusicVolume: 1,
                                musicIdentifier: player.audio.identifier,
                                music: .init(audioURL: player.audio.url, lrc: player.audioLrc.lrc)
                            )
                        }
                        result = .video(.init(data: self.editorView.adjustmentData), .init(music: music,cropSize: .init(isFixedRatio: self.editorView.isFixedRatio, aspectRatio: self.editorView.aspectRatio, angle: self.editorView.state == .edit ? self.currentAngle : self.editedAngle)))
                    }
                    edtiorAsset = .init(type: .video(self.videoURL), result: result)
                    if self.editorView.state == .edit {
                        editConfig.video.defaultSelectedToolOption = .cropSize
                    }
                }else {
                    return
                }
                let vc = EditorViewController(edtiorAsset, config: editConfig) { [weak self] editorAsset, _ in
                    guard let self = self, let result = editorAsset.result else {
                        return
                    }
                    let vc = TestEditorViewController()
                    switch result {
                    case .image(let image, _):
                        vc.image = editorAsset.type.image!
                        vc.imageResult = image
                    case .video(let video, _):
                        vc.videoURL = editorAsset.type.videoURL!
                        vc.videoResult = video
                    }
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                self.present(vc, animated: true)
                self.editorView.pauseVideo()
                for audioPlayer in self.audioPlayers {
                    audioPlayer.stopPlay()
                }
            }))
            func preview(_ isPreview: Bool) {
                if self.editorView.type == .video {
                    self.editorView.cancelVideoCroped()
                    self.view.hx.show()
                    var audios: [EditorVideoFactor.Audio] = []
                    for audioPlayer in audioPlayers {
                        audios.append(.init(url: audioPlayer.audio.url.url!))
                    }
                    self.editorView.cropVideo(
                        factor: .init(audios: audios, preset: .ratio_960x540, quality: 6),
                        progress: { progress in
                        print("video_progress: \(progress)")
                    }, completion: { [weak self] videoResult in
                        guard let self = self else { return }
                        switch videoResult {
                        case .success(let result):
                            self.view.hx.hide()
                            print(result)
                            self.editorView.pauseVideo()
                            for audioPlayer in self.audioPlayers {
                                audioPlayer.stopPlay()
                            }
                            if !isPreview {
                                let vc = TestEditorViewController()
                                vc.videoURL = self.videoURL
                                vc.videoResult = result
                                self.navigationController?.pushViewController(vc, animated: true)
                                return
                            }
                            HXPhotoPicker.PhotoBrowser.show(
                                [.init(.init(videoURL: result.url))],
                                transitionalImage: PhotoTools.getVideoThumbnailImage(videoURL: result.url, atTime: 0.1)
                            ) { _, _ in
                                self.editorView.finalView
                            } longPressHandler: { _, photoAsset, photoBrowser in
                                photoBrowser.view.hx.show()
                                photoAsset.saveToSystemAlbum { result in
                                    photoBrowser.view.hx.hide()
                                    switch result {
                                    case .success:
                                        photoBrowser.view.hx.showSuccess(text: "保存成功", delayHide: 1.5, animated: true)
                                    case .failure:
                                        photoBrowser.view.hx.showWarning(text: "保存失败", delayHide: 1.5, animated: true)
                                    }
                                }
                            }
                        case .failure(let error):
                            print("error: \(error)")
                            if !error.isCancel {
                                self.view.hx.hide()
                            }
                        }
                    })
                    return
                }
                self.view.hx.show()
                self.editorView.cropImage({ [weak self] imageResult in
                    guard let self = self else { return }
                    self.view.hx.hide()
                    switch imageResult {
                    case .success(let result):
                        print(result)
                        if !isPreview {
                            let vc = TestEditorViewController()
                            vc.image = self.image
                            vc.imageResult = result
                            self.navigationController?.pushViewController(vc, animated: true)
                            return
                        }
                        HXPhotoPicker.PhotoBrowser.show(
                            [.init(.init(result.url))],
                            transitionalImage: result.image
                        ) { _, _ in
                            self.editorView.finalView
                        } longPressHandler: { _, photoAsset, photoBrowser in
                            photoBrowser.view.hx.show()
                            photoAsset.saveToSystemAlbum { result in
                                photoBrowser.view.hx.hide()
                                switch result {
                                case .success:
                                    photoBrowser.view.hx.showSuccess(text: "保存成功", delayHide: 1.5, animated: true)
                                case .failure:
                                    photoBrowser.view.hx.showWarning(text: "保存失败", delayHide: 1.5, animated: true)
                                }
                            }
                        }
                    case .failure(let error):
                        print("error: \(error)")
                    }
                })
            }
            if editorView.isCropedImage || editorView.isCropedVideo {
                alert.addAction(.init(title: "裁剪", style: .default, handler: { _ in
                    preview(false)
                }))
                alert.addAction(.init(title: "预览", style: .default, handler: { _ in
                    preview(true)
                }))
            }
        }
        if editorView.state == .edit {
            if editorView.canReset {
                alert.addAction(.init(title: "还原", style: .default, handler: { [weak self] _ in
                    self?.currentAngle = 0
                    self?.editorView.reset(true)
                }))
            }
            alert.addAction(.init(title: "旋转", style: .default, handler: { [weak self] _ in
                let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(.init(title: "旋转任意角度", style: .default, handler: { [weak self] _ in
                    let textAlert = UIAlertController(title: "输入旋转的角度", message: nil, preferredStyle: .alert)
                    textAlert.addTextField { textField in
                        textField.keyboardType = .numberPad
                    }
                    textAlert.addAction(.init(title: "确定", style: .default, handler: { [weak self] _ in
                        guard let self = self else { return }
                        let textFiled = textAlert.textFields?.first
                        let text = textFiled?.text ?? "0"
                        let angle = CGFloat(Int(text) ?? 0)
                        self.currentAngle -= angle
                        self.editorView.rotate(angle, animated: true)
                    }))
                    textAlert.addAction(.init(title: "取消", style: .cancel))
                    self?.presendAlert(textAlert)
                }))
                alert.addAction(.init(title: "向左旋转90°", style: .default, handler: { [weak self] _ in
                    self?.editorView.rotateLeft(true)
                }))
                alert.addAction(.init(title: "向右旋转90°", style: .default, handler: { [weak self] _ in
                    self?.editorView.rotateRight(true)
                }))
                alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
                self?.presendAlert(alert)
            }))
            alert.addAction(.init(title: "镜像", style: .default, handler: { [weak self] _ in
                let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(.init(title: "水平镜像", style: .default, handler: { [weak self] _ in
                    self?.editorView.mirrorHorizontally(true)
                }))
                alert.addAction(.init(title: "垂直镜像", style: .default, handler: { [weak self] _ in
                    self?.editorView.mirrorVertically(true)
                }))
                alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
                self?.presendAlert(alert)
            }))
            alert.addAction(.init(title: editorView.isFixedRatio ? "取消固定比例" : "固定比例", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.editorView.isFixedRatio = !self.editorView.isFixedRatio
                if !self.editorView.isFixedRatio && self.editorView.isRoundMask {
                    self.editorView.setRoundMask(false, animated: true)
                }
            }))
            alert.addAction(.init(title: editorView.isRoundMask ? "取消圆切" : "圆切", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                if self.editorView.isRoundMask {
                    self.editorView.isResetIgnoreFixedRatio = true
                    self.editorView.setRoundMask(false, animated: true)
                }else {
                    self.editorView.isFixedRatio = false
                    self.editorView.isResetIgnoreFixedRatio = false
                    self.editorView.setRoundMask(true, animated: true)
                }
            }))
            alert.addAction(.init(title: "修改裁剪框比例", style: .default, handler: { [weak self] _ in
                let alert = UIAlertController.init(title: "修改比例", message: nil, preferredStyle: .alert)
                alert.addTextField { (textfield) in
                    textfield.keyboardType = .numberPad
                    textfield.placeholder = "输入宽度比"
                }
                alert.addTextField { (textfield) in
                    textfield.keyboardType = .numberPad
                    textfield.placeholder = "输入高度比"
                }
                alert.addAction(
                    UIAlertAction(
                        title: "确定",
                        style: .default,
                        handler: { [weak self] (action) in
                            guard let self = self else { return }
                    let widthTextFiled = alert.textFields?.first
                    let widthRatioStr = widthTextFiled?.text ?? "0"
                    let widthRatio = Int(widthRatioStr.count == 0 ? "0" : widthRatioStr)!
                    let heightTextFiled = alert.textFields?.last
                    let heightRatioStr = heightTextFiled?.text ?? "0"
                    let heightRatio = Int(heightRatioStr.count == 0 ? "0" : heightRatioStr)!
                    self.editorView.isResetIgnoreFixedRatio = true
                    self.editorView.setAspectRatio(.init(width: widthRatio, height: heightRatio), animated: true)
                }))
                alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
                self?.presendAlert(alert)
            }))
            alert.addAction(.init(title: editorView.isShowScaleSize ? "隐藏比例大小" : "显示比例大小", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.editorView.isShowScaleSize = !self.editorView.isShowScaleSize
            }))
            alert.addAction(.init(title: "添加蒙版", style: .default, handler: { [weak self] _ in
                let maskAlert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
                maskAlert.addAction(.init(title: "Love", style: .default, handler: { [weak self] _ in
                    if let path = Bundle.main.path(forResource: "love", ofType: "png"),
                       let image = UIImage(contentsOfFile: path) {
                        self?.editorView.setMaskImage(image, animated: true)
                        self?.editorView.setAspectRatio(.init(width: image.size.width, height: image.size.height), animated: true)
                        self?.editorView.isFixedRatio = true
                    }
                }))
                maskAlert.addAction(.init(title: "Love Text", style: .default, handler: { [weak self] _ in
                    if let path = Bundle.main.path(forResource: "love_text", ofType: "png"),
                       let image = UIImage(contentsOfFile: path) {
                        self?.editorView.setMaskImage(image, animated: true)
                        self?.editorView.setAspectRatio(.init(width: image.size.width, height: image.size.height), animated: true)
                        self?.editorView.isFixedRatio = true
                    }
                }))
                maskAlert.addAction(.init(title: "Stars", style: .default, handler: { [weak self] _ in
                    if let path = Bundle.main.path(forResource: "stars", ofType: "png"),
                       let image = UIImage(contentsOfFile: path) {
                        self?.editorView.setMaskImage(image, animated: true)
                        self?.editorView.setAspectRatio(.init(width: image.size.width, height: image.size.height), animated: true)
                        self?.editorView.isFixedRatio = true
                    }
                }))
                maskAlert.addAction(.init(title: "Text", style: .default, handler: { [weak self] _ in
                    if let path = Bundle.main.path(forResource: "text", ofType: "png"),
                       let image = UIImage(contentsOfFile: path) {
                        self?.editorView.setMaskImage(image, animated: true)
                        self?.editorView.setAspectRatio(.init(width: image.size.width, height: image.size.height), animated: true)
                        self?.editorView.isFixedRatio = true
                    }
                }))
                maskAlert.addAction(.init(title: "Portrait", style: .default, handler: { [weak self] _ in
                    if let path = Bundle.main.path(forResource: "portrait", ofType: "png"),
                       let image = UIImage(contentsOfFile: path) {
                        self?.editorView.setMaskImage(image, animated: true)
                        self?.editorView.setAspectRatio(.init(width: image.size.width, height: image.size.height), animated: true)
                        self?.editorView.isFixedRatio = true
                    }
                }))
                maskAlert.addAction(.init(title: "QIY", style: .default, handler: { [weak self] _ in
                    if let path = Bundle.main.path(forResource: "qiy", ofType: "png"),
                       let image = UIImage(contentsOfFile: path) {
                        self?.editorView.setMaskImage(image, animated: true)
                        self?.editorView.setAspectRatio(.init(width: image.size.width, height: image.size.height), animated: true)
                        self?.editorView.isFixedRatio = true
                    }
                }))
                maskAlert.addAction(.init(title: "移除蒙版", style: .destructive, handler: { [weak self] _ in
                    self?.editorView.setMaskImage(nil, animated: true)
                    self?.editorView.isFixedRatio = false
                }))
                maskAlert.addAction(.init(title: "取消", style: .cancel))
                self?.presendAlert(maskAlert)
            }))
            alert.addAction(.init(title: "修改遮罩类型", style: .default, handler: { [weak self] _ in
                let maskAlert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
                maskAlert.addAction(.init(title: "blackColor", style: .default, handler: { [weak self] _ in
                    self?.editorView.setMaskType(.customColor(color: .black.withAlphaComponent(0.7)), animated: true)
                }))
                maskAlert.addAction(.init(title: "redColor", style: .default, handler: { [weak self] _ in
                    self?.editorView.setMaskType(.customColor(color: .red.withAlphaComponent(0.7)), animated: true)
                }))
                maskAlert.addAction(.init(title: "darkBlurEffect", style: .default, handler: { [weak self] _ in
                    self?.editorView.setMaskType(.blurEffect(style: .dark), animated: true)
                }))
                maskAlert.addAction(.init(title: "lightBlurEffect", style: .default, handler: { [weak self] _ in
                    self?.editorView.setMaskType(.blurEffect(style: .light), animated: true)
                }))
                maskAlert.addAction(.init(title: "取消", style: .cancel))
                self?.presendAlert(maskAlert)
            }))
            alert.addAction(.init(title: "确认编辑", style: .default, handler: { [weak self] _ in
                guard let self else { return }
                self.editedAngle = self.currentAngle
                self.editorView.finishEdit(true)
                self.isShowVideoControl = false
                self.editorView.isStickerEnabled = true
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            }))
            alert.addAction(.init(title: "取消编辑", style: .default, handler: { [weak self] _ in
                self?.editorView.cancelEdit(true)
                self?.isShowVideoControl = false
                self?.editorView.isStickerEnabled = true
                self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            }))
        }else {
            alert.addAction(.init(title: "添加贴纸", style: .default, handler: { [weak self] _ in
                var config = PickerConfiguration()
                config.selectMode = .single
                config.selectOptions = [.gifPhoto]
                config.previewView.bottomView.isHiddenOriginalButton = true
                Photo.picker(config) { [weak self] pickerResult, _ in
                    guard let self = self else {
                        return
                    }
                    let asset = pickerResult.photoAssets.first
                    self.view.hx.show()
                    asset?.getAssetURL {
                        self.view.hx.hide()
                        switch $0 {
                        case .success(let urlResult):
                            if let data = try? Data(contentsOf: urlResult.url) {
                                self.editorView.addSticker(data, isSelected: true)
                                return
                            }
                            if let image = UIImage(contentsOfFile: urlResult.url.path) {
                                self.editorView.addSticker(image, isSelected: true)
                            }
                        default:
                            break
                        }
                    }
                }
            }))
            if editorView.type == .video {
                alert.addAction(.init(title: "添加音乐贴纸", style: .default, handler: { [weak self] _ in
                    func addStickerAudio(_ fileName: String) {
                        guard let self = self,
                              let lyricUrl = Bundle.main.url(forResource: fileName, withExtension: nil),
                              let lrc = try? String(contentsOfFile: lyricUrl.path) else {
                            return
                        }
                        let musicURL = VideoEditorMusicURL.bundle(resource: fileName, type: "mp3")
                        let audio = EditorStickerAudio(musicURL) { [weak self] in
                            guard let self = self else {
                                return nil
                            }
                            for audioPlayer in self.audioPlayers where audioPlayer.audio == $0 {
                                var texts: [EditorStickerAudioText] = []
                                for lyric in audioPlayer.audioLrc.lyrics {
                                    texts.append(.init(text: lyric.lyric, startTime: lyric.startTime, endTime: lyric.endTime))
                                }
                                return .init(time: audioPlayer.audioLrc.time ?? 0, texts: texts)
                            }
                            return nil
                        }
                        let itemView = self.editorView.addSticker(audio, isSelected: true)
                        let audioPlayer = TestPlayAuido.init(audio, lyric: lrc, itemView: itemView)
                        audioPlayer.musicURL = musicURL
                        self.audioPlayers.append(audioPlayer)
                    }
                    let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
                    let fileNames = ["世间美好与你环环相扣"]
                    for fileName in fileNames {
                        alert.addAction(.init(title: fileName, style: .default, handler: {
                            guard let title = $0.title else {
                                return
                            }
                            addStickerAudio(title)
                        }))
                    }
                    alert.addAction(.init(title: "取消", style: .cancel))
                    self?.presendAlert(alert)
                }))
            }
            alert.addAction(.init(title: !editorView.isDrawEnabled ? "开启绘画" : "关闭绘画", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.editorView.isDrawEnabled = !self.editorView.isDrawEnabled
                if self.editorView.isDrawEnabled {
                    self.editorView.isMosaicEnabled = false
                }
                self.editorView.isStickerEnabled = !self.editorView.isDrawEnabled
            }))
            alert.addAction(.init(title: "绘画设置", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(.init(title: "画笔宽度", style: .default, handler: { [weak self] _ in
                    guard let self = self else { return }
                    let alert = UIAlertController.init(title: "画笔宽比", message: nil, preferredStyle: .alert)
                    alert.addTextField { (textfield) in
                        textfield.keyboardType = .numberPad
                        textfield.placeholder = "输入画笔宽比"
                    }
                    alert.addAction(
                        UIAlertAction(
                            title: "确定",
                            style: .default,
                            handler: { [weak self] (action) in
                                guard let self = self,
                                      let textFiled = alert.textFields?.first,
                                      let text = textFiled.text,
                                      !text.isEmpty else {
                                    return
                                }
                                let lineWidth = CGFloat(Int(text)!)
                                self.editorView.drawLineWidth = lineWidth
                    }))
                    alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
                    self.presendAlert(alert)
                }))
                alert.addAction(.init(title: "画笔颜色", style: .default, handler: { [weak self] _ in
                    guard let self = self else { return }
                    if #available(iOS 14.0, *) {
                        let vc = UIColorPickerViewController()
                        vc.selectedColor = self.editorView.drawLineColor
                        vc.delegate = self
                        self.present(vc, animated: true, completion: nil)
                    }
                }))
                alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
                self.presendAlert(alert)
            }))
            if self.editorView.isCanUndoDraw {
                alert.addAction(.init(title: "撤销上一次的绘画", style: .default, handler: { [weak self] _ in
                    self?.editorView.undoDraw()
                }))
                alert.addAction(.init(title: "撤销所有的绘画", style: .default, handler: { [weak self] _ in
                    self?.editorView.undoAllDraw()
                }))
            }
            if editorView.type == .image {
                alert.addAction(.init(title: !editorView.isMosaicEnabled ? "开启马赛克涂抹" : "关闭马赛克涂抹", style: .default, handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.editorView.isMosaicEnabled = !self.editorView.isMosaicEnabled
                    if self.editorView.isMosaicEnabled {
                        self.editorView.isDrawEnabled = false
                    }
                    self.editorView.isStickerEnabled = !self.editorView.isMosaicEnabled
                }))
                alert.addAction(.init(title: "马赛克涂抹设置", style: .default, handler: { [weak self] _ in
                    guard let self = self else { return }
                    let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
                    alert.addAction(.init(title: "马赛克宽度", style: .default, handler: { [weak self] _ in
                        guard let self = self else { return }
                        let alert = UIAlertController.init(title: "马赛克宽比", message: nil, preferredStyle: .alert)
                        alert.addTextField { (textfield) in
                            textfield.keyboardType = .numberPad
                            textfield.placeholder = "输入马赛克宽比"
                        }
                        alert.addAction(
                            UIAlertAction(
                                title: "确定",
                                style: .default,
                                handler: { [weak self] (action) in
                                    guard let self = self,
                                          let textFiled = alert.textFields?.first,
                                          let text = textFiled.text,
                                          !text.isEmpty else {
                                        return
                                    }
                                    let mosaicWidth = CGFloat(Int(text)!)
                                    self.editorView.mosaicWidth = mosaicWidth
                        }))
                        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
                        self.presendAlert(alert)
                    }))
                    alert.addAction(.init(title: "涂抹宽度", style: .default, handler: { [weak self] _ in
                        guard let self = self else { return }
                        let alert = UIAlertController.init(title: "涂抹宽比", message: nil, preferredStyle: .alert)
                        alert.addTextField { (textfield) in
                            textfield.keyboardType = .numberPad
                            textfield.placeholder = "输入涂抹宽比"
                        }
                        alert.addAction(
                            UIAlertAction(
                                title: "确定",
                                style: .default,
                                handler: { [weak self] (action) in
                                    guard let self = self,
                                          let textFiled = alert.textFields?.first,
                                          let text = textFiled.text,
                                          !text.isEmpty else {
                                        return
                                    }
                                    let smearWidth = CGFloat(Int(text)!)
                                    self.editorView.smearWidth = smearWidth
                        }))
                        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
                        self.presendAlert(alert)
                    }))
                    alert.addAction(.init(title: "切换至" + (self.editorView.mosaicType == .mosaic ? "涂抹" : "马赛克"), style: .default, handler: { [weak self] _ in
                        guard let self = self else { return }
                        if self.editorView.mosaicType == .mosaic {
                            self.editorView.mosaicType = .smear
                        }else {
                            self.editorView.mosaicType = .mosaic
                        }
                    }))
                    alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
                    self.presendAlert(alert)
                }))
                if self.editorView.isCanUndoMosaic {
                    alert.addAction(.init(title: "撤销上一次的马赛克涂抹", style: .default, handler: { [weak self] _ in
                        self?.editorView.undoMosaic()
                    }))
                    alert.addAction(.init(title: "撤销所有的马赛克涂抹", style: .default, handler: { [weak self] _ in
                        self?.editorView.undoAllMosaic()
                    }))
                }
            }
            if editorView.type == .video {
                if !editorView.isVideoPlaying {
                    alert.addAction(.init(title: "播放视频", style: .default, handler: { [weak self] _ in
                        self?.editorView.playVideo()
                    }))
                }else {
                    alert.addAction(.init(title: "暂停视频", style: .default, handler: { [weak self] _ in
                        self?.editorView.pauseVideo()
                    }))
                }
            }
            alert.addAction(.init(title: "进入编辑模式", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.currentAngle = self.editedAngle
                if self.editorView.isRoundMask {
                    self.editorView.isResetIgnoreFixedRatio = false
                }
                self.editorView.startEdit(true)
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            }))
        }
        alert.addAction(.init(title: "选择编辑的照片/视频", style: .default, handler: { [weak self] _ in
            self?.openPickerController()
        }))
        alert.addAction(.init(title: "取消", style: .cancel))
        presendAlert(alert)
    }
    
    @objc
    func openPickerController() {
        var config = PickerConfiguration()
        config.selectMode = .single
        config.selectOptions = [.gifPhoto, .video]
        config.previewView.bottomView.isHiddenOriginalButton = true
        config.isAutoBack = false
        hx.present(
            picker: config
        ) { [weak self] result, pickerController in
            guard let self = self else { return }
            pickerController.dismiss(true)
            let asset = result.photoAssets.first
            self.view.hx.show()
            asset?.getAssetURL {
                self.view.hx.hide()
                switch $0 {
                case .success(let urlResult):
                    if urlResult.mediaType == .photo {
                        self.image = UIImage(contentsOfFile: urlResult.url.path)
                        let imageData = try? Data(contentsOf: urlResult.url)
                        self.editorView.setImageData(imageData)

//                        let image = UIImage(contentsOfFile: urlResult.url.path)
//                        self.editorView.setImage(image)
//                        self.editorView.updateImage(image)
                        self.setmosaicImage()
                    }else {
                        self.videoURL = urlResult.url
                        let avAsset = AVAsset(url: urlResult.url)
                        self.editorView.setAVAsset(avAsset)
                        self.editorView.loadVideo(isPlay: true)
                    }
                    self.isShowVideoControl = false
                default:
                    break
                }
            }
        }
    }
    
    lazy var context: CIContext = .init()
    
    func setmosaicImage() {
        let screenScale = 20 / max(UIDevice.screenSize.width, UIDevice.screenSize.height)
        DispatchQueue.global(qos: .userInteractive).async {
            guard let cgImage = self.image?.cgImage else {
                return
            }
            let ciImage = CIImage(cgImage: cgImage)
            let scale = ciImage.extent.width * screenScale
            let image = ciImage.applyingFilter("CIPixellate", parameters: [kCIInputScaleKey: scale])
            guard let mosaicImage = self.context.createCGImage(image, from: image.extent) else {
                return
            }
            DispatchQueue.main.async {
                self.editorView.mosaicCGImage = mosaicImage
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if canImport(GDPerformanceView_Swift)
        PerformanceMonitor.shared().show()
        #endif
        if editorView.state == .edit {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    open override var prefersHomeIndicatorAutoHidden: Bool {
        false
    }
    open override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        .all
    }
    
    deinit {
        print("deinit: \(self)")
    }
}

extension TestEditorViewController: EditorViewDelegate {
    
    func editorView(_ editorView: EditorView, shouldRemoveStickerItem itemView: EditorStickersItemBaseView) {
        for (index, player) in audioPlayers.enumerated() where player.itemView == itemView {
            audioPlayers.remove(at: index)
        }
    }
    
    func editorView(_ editorView: EditorView, resetItemViews itemViews: [EditorStickersItemBaseView]) {
        for itemView in itemViews {
            for player in audioPlayers where itemView.audio == player.audio {
                player.itemView = itemView
                break
            }
        }
    }
    
    func editorView(_ editorView: EditorView, videoDidPlayAt time: CMTime) {
        delayHideVideoControl()
    }
    func editorView(_ editorView: EditorView, videoDidPauseAt time: CMTime) {
        delayHideVideoControl()
    }
    
    func editorView(_ editorView: EditorView, videoControlDidChangedTimeAt time: TimeInterval, for event: VideoControlEvent) {
        if event == .touchDown {
            videoTimer?.invalidate()
            videoTimer = nil
        }else if event == .touchUpInSide {
            delayHideVideoControl()
        }
    }
}

@available(iOS 14.0, *)
extension TestEditorViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        editorView.drawLineColor = color
    }
}

class TestPlayAuido: NSObject, AVAudioPlayerDelegate {
    
    lazy var player: AVAudioPlayer? = {
        let player = try? AVAudioPlayer(contentsOf: audio.url.url!)
        player?.delegate = self
        player?.prepareToPlay()
        return player
    }()
    
    lazy var audioLrc: TestEditorAudioLrc = {
        let audioLrc = TestEditorAudioLrc(audioURL: audio.url.url!, lrc: lyric)
        audioLrc.parseLrc()
        return audioLrc
    }()
    
    var audio: EditorStickerAudio
    let lyric: String
    var itemView: EditorStickersItemBaseView
    var musicURL: VideoEditorMusicURL?
    
    weak var timer: Timer?
    
    init(
        _ audio: EditorStickerAudio,
        lyric: String,
        itemView: EditorStickersItemBaseView
    ) {
        self.audio = audio
        self.lyric = lyric
        self.itemView = itemView
        super.init()
        startPlay()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            player.currentTime = 0
            player.play()
        }
    }
    
    func startPlay() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [weak self] _ in
            guard let currentTime = self?.player?.currentTime,
                  let lyric = self?.audioLrc.lyric(atTime: currentTime)?.lyric else {
                return
            }
            self?.audio.text = lyric
        })
        player?.play()
    }
    
    func stopPlay() {
        timer?.invalidate()
        player?.stop()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("deinit: \(self)")
        stopPlay()
    }
    
    static func getVideoTime(forVideo duration: String) -> TimeInterval {
        var m = 0
        var s = 0
        var ms = 0
        let components = duration.components(
            separatedBy: CharacterSet.init(charactersIn: ":.")
        )
        if components.count >= 2 {
            m = Int(components[0]) ?? 0
            s = Int(components[1]) ?? 0
            if components.count == 3 {
                ms = Int(components[2]) ?? 0
            }
        }else {
            s = Int(INT_MAX)
        }
        return TimeInterval(CGFloat(m * 60) + CGFloat(s) + CGFloat(ms) * 0.001)
    }
}

class TestEditorAudioLrc: Equatable, Codable {
    let audioURL: URL
    let lrc: String
    init(
        audioURL: URL,
        lrc: String
    ) {
        self.audioURL = audioURL
        self.lrc = lrc
    }
    
    var isLoading: Bool = false
    var isSelected: Bool = false
    
    var localAudioPath: String?
    var metaData: [String: String] = [:]
    var lyrics: [TestEditorLyric] = []
    var lyricIsEmpty = false
    var songName: String? { metaData["ti"] }
    var singer: String? { metaData["ar"] }
    var time: TimeInterval? {
        if let time = metaData["t_time"]?.replacingOccurrences(
            of: "(",
            with: "").replacingOccurrences(
                of: ")",
                with: ""
            ) {
            return TestPlayAuido.getVideoTime(forVideo: time)
        }else if let lastLyric = lyrics.last {
            return lastLyric.startTime + 5
        }
        return nil
    }
    
    func parseLrc() {
        let lines = lrc.replacingOccurrences(
            of: "\r",
            with: ""
        ).components(
            separatedBy: "\n"
        )
        let tags = ["ti", "ar", "al", "by", "offset", "t_time"]
        let pattern1 = "(\\[\\d{0,2}:\\d{0,2}([.|:]\\d{0,3})?\\])"
        let pattern2 = "(\\[\\d{0,2}:\\d{0,2}([.|:]\\d{0,3})?\\])+"
        let regular1 = try? NSRegularExpression(
            pattern: pattern1,
            options: .caseInsensitive
        )
        let regular2 = try? NSRegularExpression(
            pattern: pattern2,
            options: .caseInsensitive
        )
        for line in lines {
            if line.count <= 1 {
                continue
            }
            var isTag = false
            for tag in tags where metaData[tag] == nil {
                let prefix = "[" + tag + ":"
                if line.hasPrefix(prefix) && line.hasSuffix("]") {
                    let loc = prefix.count
                    let len = line.count - 2
                    let info = line[loc...len]
                    metaData[tag] = info
                    isTag = true
                    break
                }
            }
            if isTag {
                continue
            }
            if let reg1 = regular1,
               let reg2 = regular2 {
                let matches = reg1.matches(
                    in: line,
                    options: .reportProgress,
                    range: NSRange(location: 0, length: line.count)
                )
                let modifyString = reg2.stringByReplacingMatches(
                    in: line,
                    options: .reportProgress,
                    range: NSRange(location: 0, length: line.count),
                    withTemplate: ""
                ).trimmingCharacters(in: .whitespacesAndNewlines)
                for result in matches {
                    if result.range.location == NSNotFound {
                        continue
                    }
                    var sec = line[
                        result.range.location...(
                            result.range.location + result.range.length - 1
                        )
                    ]
                    sec = sec.replacingOccurrences(of: "[", with: "")
                    sec = sec.replacingOccurrences(of: "]", with: "")
                    if sec.count == 0 {
                        continue
                    }
                    let lyric = TestEditorLyric.init(lyric: modifyString)
                    lyric.update(second: sec, isEnd: false)
                    lyrics.append(lyric)
                }
                if matches.isEmpty {
                    let lyric = TestEditorLyric.init(lyric: line)
                    lyrics.append(lyric)
                }
            }
        }
        let sorted = lyrics.sorted { (lyric1, lyric2) -> Bool in
            lyric1.startTime < lyric2.startTime
        }
        var first: TestEditorLyric?
        var second: TestEditorLyric?
        for (index, lyric) in sorted.enumerated() {
            first = lyric
            if index + 1 >= sorted.count {
                if let time = metaData["t_time"]?.replacingOccurrences(
                    of: "(",
                    with: "").replacingOccurrences(
                        of: ")",
                        with: ""
                    ) {
                    first?.update(second: time, isEnd: true)
                }else {
                    first?.update(second: "60000:50:00", isEnd: true)
                }
            }else {
                second = sorted[index + 1]
                first?.update(second: second!.second, isEnd: true)
            }
        }
        lyrics = sorted
        if lyrics.isEmpty {
            lyricIsEmpty = true
            lyrics.append(.init(lyric: "此歌曲暂无歌词，请您欣赏"))
        }
    }
     
    func lyric(
        atTime time: TimeInterval
    ) -> TestEditorLyric? {
        if lyricIsEmpty {
            return .init(lyric: "此歌曲暂无歌词，请您欣赏")
        }
        for lyric in lyrics {
            if lyric.second.isEmpty || lyric.second == "60000:50:00" {
                continue
            }
            if time >= lyric.startTime
                && time <= lyric.endTime {
                return lyric
            }
        }
        return nil
    }
    
    func lyric(
        atRange range: NSRange
    ) -> [TestEditorLyric] {
        if range.location == NSNotFound || lyrics.isEmpty {
            return []
        }
        let count = lyrics.count
        let loc = range.location
        var len = range.length
        
        if loc >= count {
            return []
        }
        if count - loc < len {
            len = count - loc
        }
        return Array(lyrics[loc..<(loc + len)])
    }
    func lyric(
        atLine line: Int
    ) -> TestEditorLyric? {
        lyric(
            atRange:
                NSRange(
                    location: line,
                    length: 1
                )
        ).first
    }
    
    public static func == (
        lhs: TestEditorAudioLrc,
        rhs: TestEditorAudioLrc
    ) -> Bool {
        lhs === rhs
    }
}

class TestEditorLyric: Equatable, Codable {
    
    /// 歌词
    let lyric: String
    
    var second: String = ""
    var startTime: TimeInterval = 0
    var endTime: TimeInterval = 0
    init(lyric: String) {
        self.lyric = lyric
    }
    
    func update(
        second: String,
        isEnd: Bool
    ) {
        if !second.isEmpty {
            self.second = second
        }
        let time = TestPlayAuido.getVideoTime(
            forVideo: self.second
        )
        if isEnd {
            endTime = time
        }else {
            startTime = time
        }
    }
    
    static func == (
        lhs: TestEditorLyric,
        rhs: TestEditorLyric
    ) -> Bool {
        lhs === rhs
    }
}
