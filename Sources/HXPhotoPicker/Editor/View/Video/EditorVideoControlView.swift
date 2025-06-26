//
//  EditorVideoControlView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/13.
//

import UIKit
import AVFoundation

protocol EditorVideoControlViewDelegate: AnyObject {
    func controlView(_ controlView: EditorVideoControlView, didPlayAt isSelected: Bool)
    func controlView(_ controlView: EditorVideoControlView, leftDidChangedValidRectAt time: CMTime)
    func controlView(_ controlView: EditorVideoControlView, leftEndChangedValidRectAt time: CMTime)
    func controlView(_ controlView: EditorVideoControlView, rightDidChangedValidRectAt time: CMTime)
    func controlView(_ controlView: EditorVideoControlView, rightEndChangedValidRectAt time: CMTime)
    func controlView(_ controlView: EditorVideoControlView, progressLineDragBeganAt time: CMTime)
    func controlView(_ controlView: EditorVideoControlView, progressLineDragChangedAt time: CMTime)
    func controlView(_ controlView: EditorVideoControlView, progressLineDragEndAt time: CMTime)
    func controlView(_ controlView: EditorVideoControlView, didScrollAt time: CMTime)
    func controlView(_ controlView: EditorVideoControlView, endScrollAt time: CMTime)
}

// swiftlint:disable type_body_length
class EditorVideoControlView: UIView {
    // swiftlint:enable type_body_length
    
    weak var delegate: EditorVideoControlViewDelegate?
    let config: EditorConfiguration.Video.CropTime
    
    private var playView: UIVisualEffectView!
    private var playButton: UIButton!
    private var frameMaskView: EditorVideoControlMaskView!
    private var flowLayout: UICollectionViewFlowLayout!
    private var bgView: UIVisualEffectView!
    private var collectionView: UICollectionView!
    private var beginLineFrame: CGRect = .zero
    private var progressLineView: UIView!
    private var currentLineView: UIView!
    private var currentTimeView: UIVisualEffectView!
    private var currentTimeLb: UILabel!
    private var startLineView: UIView!
    private var endLineView: UIView!
    private var startTimeView: UIVisualEffectView!
    private var startTimeLb: UILabel!
    private var endTimeView: UIVisualEffectView!
    private var endTimeLb: UILabel!
    private var totalTimeView: UIVisualEffectView!
    private var totalTimeLb: UILabel!
    
    var isPlaying: Bool {
        get {
            playButton.isSelected
        }
        set {
            playButton.isSelected = newValue
            if newValue {
                startLineAnimation()
            }else {
                stopLineAnimation()
            }
        }
    }
    
    init(config: EditorConfiguration.Video.CropTime) {
        self.config = config
        super.init(frame: .zero)
        initViews()
    }
    
    private func initViews() {
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        collectionView = HXCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(
            EditorVideoControlViewCell.self,
            forCellWithReuseIdentifier: "EditorVideoControlViewCellID"
        )
        
        frameMaskView = EditorVideoControlMaskView()
        frameMaskView.frameHighlightedColor = config.frameHighlightedColor
        frameMaskView.arrowNormalColor = config.arrowNormalColor
        frameMaskView.arrowHighlightedColor = config.arrowHighlightedColor
        frameMaskView.delegate = self
        
        bgView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        bgView.contentView.addSubview(collectionView)
        bgView.contentView.addSubview(frameMaskView)
        bgView.layer.cornerRadius = 4
        bgView.layer.masksToBounds = true
        addSubview(bgView)
        
        playButton = UIButton(type: .custom)
        playButton.setImage(.imageResource.editor.video.play.image, for: .normal)
        playButton.setImage(.imageResource.editor.video.pause.image, for: .selected)
        playButton.addTarget(self, action: #selector(didPlayButtonClick), for: .touchUpInside)
        playView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        playView.contentView.addSubview(playButton)
        playView.layer.cornerRadius = 4
        playView.layer.masksToBounds = true
        addSubview(playView)
        
        progressLineView = UIView()
        progressLineView.backgroundColor = .white
        if #available(iOS 11.0, *) {
            progressLineView.cornersRound(radius: 2, corner: .allCorners)
        }
        progressLineView.layer.borderColor = UIColor.black.cgColor
        progressLineView.layer.borderWidth = 0.25
        progressLineView.alpha = 0
        progressLineView.addGestureRecognizer(
            PhotoPanGestureRecognizer(
                target: self,
                action: #selector(progressLinePanGestureClick(pan:))
            )
        )
        addSubview(progressLineView)
        
        startTimeLb = UILabel()
        startTimeLb.font = .systemFont(ofSize: 12)
        startTimeLb.textColor = .white
        startTimeView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        startTimeView.contentView.addSubview(startTimeLb)
        startTimeView.layer.cornerRadius = 4
        startTimeView.layer.masksToBounds = true
        startTimeView.alpha = 0
        addSubview(startTimeView)
        
        startLineView = UIView()
        startLineView.backgroundColor = .white
        startLineView.size = .init(width: 1, height: 10)
        startLineView.cornersRound(radius: 0.5, corner: .allCorners)
        startLineView.alpha = 0
        addSubview(startLineView)
        
        endTimeLb = UILabel()
        endTimeLb.textAlignment = .right
        endTimeLb.font = .systemFont(ofSize: 12)
        endTimeLb.textColor = .white
        endTimeView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        endTimeView.contentView.addSubview(endTimeLb)
        endTimeView.layer.cornerRadius = 4
        endTimeView.layer.masksToBounds = true
        endTimeView.alpha = 0
        addSubview(endTimeView)
        
        endLineView = UIView()
        endLineView.backgroundColor = .white
        endLineView.size = .init(width: 1, height: 10)
        endLineView.cornersRound(radius: 0.5, corner: .allCorners)
        endLineView.alpha = 0
        addSubview(endLineView)
        
        currentTimeLb = UILabel()
        currentTimeLb.font = .systemFont(ofSize: 12)
        currentTimeLb.textColor = .white
        currentTimeView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        currentTimeView.contentView.addSubview(currentTimeLb)
        currentTimeView.layer.cornerRadius = 4
        currentTimeView.layer.masksToBounds = true
        currentTimeView.alpha = 0
        addSubview(currentTimeView)
        
        currentLineView = UIView()
        currentLineView.backgroundColor = .white
        currentLineView.size = .init(width: 1, height: 10)
        currentLineView.cornersRound(radius: 0.5, corner: .allCorners)
        currentLineView.alpha = 0
        addSubview(currentLineView)
        
        totalTimeLb = UILabel.init()
        totalTimeLb.textAlignment = .center
        totalTimeLb.font = .systemFont(ofSize: 12)
        totalTimeLb.textColor = .white
        totalTimeView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        totalTimeView.contentView.addSubview(totalTimeLb)
        totalTimeView.layer.cornerRadius = 4
        totalTimeView.layer.masksToBounds = true
        totalTimeView.alpha = 0
        addSubview(totalTimeView)
    }
    
    @objc
    private func didPlayButtonClick() {
        playButton.isSelected = !playButton.isSelected
        delegate?.controlView(self, didPlayAt: playButton.isSelected)
        if playButton.isSelected {
            startLineAnimation()
        }else {
            stopLineAnimation()
        }
    }
    
    private let controlWidth: CGFloat = 18
    private var contentWidth: CGFloat = 0
    private var videoFrameCount: Int = 0
    
    private var videoFrameMap: [Int: CGImage] = [:]
    private var videoFrameLock: DispatchQueue = .init(label: "com.hxpicker.editorvideoframelock")
    var videoSize: CGSize = .zero
    /// 一个item代表多少秒
    private var interval: CGFloat = -1
    private var itemWidth: CGFloat = 0
    private var imageGenerator: AVAssetImageGenerator?
    private var assetDuration: TimeInterval = 0
    private weak var timeLabelsTimer: Timer?
    private var avAsset: AVAsset?
    private var margin: CGFloat {
        var leftMargin: CGFloat = 15 + UIDevice.leftMargin
        var rightMargin: CGFloat = UIDevice.rightMargin + 15
        if (width - leftMargin - rightMargin) > 450 {
            let maxWidth = max(width * 0.5, 450)
            leftMargin = (width - maxWidth) * 0.5
            rightMargin = leftMargin
        }
        return leftMargin - UIDevice.leftMargin
    }
    private var bgWidth: CGFloat {
        if UIDevice.isPortrait {
            return width - UIDevice.rightMargin - margin - (margin + UIDevice.leftMargin + playWidth) - 1
        }else {
            return width - UIDevice.rightMargin - margin - (margin + UIDevice.leftMargin + playWidth) - 1
        }
    }
    private var isBeginScrolling: Bool = false
    private var isFirstLoad: Bool = true
    private var playWidth: CGFloat {
        if UIDevice.isPortrait {
            return height
        }else {
            return height * 1.5
        }
    }
    var currentDuration: Double {
        let lineFrame = progressLineView.layer.presentation()?.frame ?? progressLineView.frame
        let scale = (
            lineFrame.minX - bgView.x - frameMaskView.validRect.minX
        ) / (
            frameMaskView.validRect.width - lineFrame.width
        )
        let totalDuration = endDuration - startDuration
        let time = startDuration + totalDuration * scale
        return time
    }
    private var currentTime: CMTime {
        CMTimeMakeWithSeconds(
            Float64(currentDuration),
            preferredTimescale: 1000
        )
    }
    
    func loadData(_ avAsset: AVAsset) {
        self.avAsset = avAsset
        videoSize = PhotoTools.getVideoThumbnailImage(avAsset: avAsset, atTime: 0.1)?.size ?? .zero
        assetDuration = avAsset.duration.seconds
        imageGenerator?.cancelAllCGImageGeneration()
        videoFrameMap.removeAll()
        
        collectionView.contentInset = UIEdgeInsets(
            top: 4,
            left: controlWidth,
            bottom: 4,
            right: controlWidth
        )
        loadItemSize()
        resetValidRect()
        collectionView.reloadData()
        loadVideoFrame(avAsset)
        updateTimeLabels()
        updateTimeLabelsFrame()
        let totalDuration = endDuration - startDuration
        frameMaskView.isShowFrame = totalDuration < assetDuration
        frameMaskView.updateFrameView()
        showLineView(at: startTime)
    }
    
    func loadItemSize() {
        if videoSize == .zero {
            return
        }
        let cellHeight = height - 8
        itemWidth = cellHeight / 16 * 9
        var imgWidth = videoSize.width
        let imgHeight = videoSize.height
        imgWidth = cellHeight / imgHeight * imgWidth
        if imgWidth > itemWidth {
            itemWidth = cellHeight / imgHeight * videoSize.width
            if itemWidth > imgHeight / 9 * 16 {
                itemWidth = imgHeight / 9 * 16
            }
        }
        var videoSecond = assetDuration
        if videoSecond <= 0 {
            videoSecond = 1
        }
        let maxWidth = bgWidth - controlWidth * 2
        var singleItemSecond: CGFloat
        let videoMaximumCropDuration = CGFloat(config.maximumTime)
        if videoSecond <= videoMaximumCropDuration || videoMaximumCropDuration <= 0 {
            let itemCount = maxWidth / itemWidth
            singleItemSecond = videoSecond / itemCount
            
            contentWidth = maxWidth
            videoFrameCount = Int(ceilf(Float(itemCount)))
            interval = singleItemSecond
        }else {
            let singleSecondWidth = maxWidth / videoMaximumCropDuration
            singleItemSecond = itemWidth / singleSecondWidth
            
            contentWidth = singleSecondWidth * videoSecond
            videoFrameCount = Int(ceilf(Float(contentWidth / itemWidth)))
            interval = singleItemSecond
        }
        if round(videoSecond) <= 0 {
            frameMaskView.minWidth = contentWidth
        }else {
            var videoMinimunCropDuration = CGFloat(config.minimumTime)
            if videoMinimunCropDuration < 1 {
                videoMinimunCropDuration = 1
            }
            let scale = videoMinimunCropDuration / videoSecond
            frameMaskView.minWidth = contentWidth * scale
        }
    }
    
    func loadVideoFrame(_ avAsset: AVAsset) {
        if videoFrameCount < 0 {
            return
        }
        imageGenerator = AVAssetImageGenerator(asset: avAsset)
        imageGenerator?.maximumSize = CGSize(width: itemWidth * 2, height: height * 2)
        imageGenerator?.appliesPreferredTrackTransform = true
        imageGenerator?.requestedTimeToleranceAfter = .zero
        imageGenerator?.requestedTimeToleranceBefore = .zero
         
        var times: [NSValue] = []
        for index in 0..<videoFrameCount {
            let time = getVideoCurrentTime(for: index)
            times.append(NSValue.init(time: time))
        }
        var index: Int = 0
        var hasError = false
        var errorIndex: [Int] = []
        imageGenerator?.generateCGImagesAsynchronously(forTimes: times) { (_, cgImage, _, result, _) in
            if result != .cancelled {
                if let cgImage = cgImage {
                    self.videoFrameLock.sync {
                        self.videoFrameMap[index] = cgImage
                    }
                    if hasError {
                        for inde in errorIndex {
                            self.setCurrentCell(image: UIImage(cgImage: cgImage), index: inde)
                        }
                        errorIndex.removeAll()
                        hasError = false
                    }
                    self.setCurrentCell(image: UIImage(cgImage: cgImage), index: index)
                }else {
                    var cg_image: CGImage?
                    self.videoFrameLock.sync {
                        cg_image = self.videoFrameMap[index - 1]
                    }
                    if let cgImage = cg_image {
                        self.setCurrentCell(image: UIImage(cgImage: cgImage), index: index)
                    }else {
                        errorIndex.append(index)
                        hasError = true
                    }
                }
                index += 1
            }
        }
    }
    
    func reloadVideo() {
        guard let avAsset = avAsset else {
            return
        }
        imageGenerator?.cancelAllCGImageGeneration()
        loadItemSize()
        collectionView.reloadData()
        loadVideoFrame(avAsset)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let lineFrame = progressLineView.layer.presentation()?.frame ?? progressLineView.frame
        let rect = lineFrame.inset(by: .init(top: 4, left: 10, bottom: 4, right: 10))
        if rect.contains(point) {
            return progressLineView
        }
        return super.hitTest(point, with: event)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        progressLineView.size = .init(width: 4, height: height - 4)
        progressLineView.centerY = height / 2
        if UIDevice.isPortrait {
            let leftMargin: CGFloat = margin + UIDevice.leftMargin
            let rightMargin: CGFloat = UIDevice.rightMargin + margin
            playView.frame = .init(x: leftMargin, y: 0, width: playWidth, height: height)
            bgView.frame = .init(
                x: playView.frame.maxX + 1,
                y: 0,
                width: width - rightMargin - playView.frame.maxX - 1,
                height: height
            )
        }else {
            playView.frame = .init(x: margin + UIDevice.leftMargin, y: 0, width: playWidth, height: height)
            bgView.frame = .init(
                x: playView.frame.maxX + 1,
                y: 0,
                width: width - UIDevice.rightMargin - margin - playView.frame.maxX - 1,
                height: height
            )
        }
        playButton.frame = playView.bounds
        collectionView.frame = bgView.bounds
        frameMaskView.frame = bgView.bounds
        if isFirstLoad {
            resetValidRect()
            isFirstLoad = false
        }
        guard #available(iOS 11.0, *) else {
            progressLineView.cornersRound(radius: 2, corner: .allCorners)
            return
        }
    }
    deinit {
        imageGenerator?.cancelAllCGImageGeneration()
        videoFrameMap.removeAll()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorVideoControlView {
    @objc
    private func progressLinePanGestureClick(pan: UIPanGestureRecognizer) {
        if isHidden {
            return
        }
        let point = pan.translation(in: progressLineView)
        switch pan.state {
        case .began:
            if playButton.isSelected {
                didPlayButtonClick()
            }
            beginLineFrame = progressLineView.frame
            hideTimeLabels(false)
            updateCurrentTime()
            showCurrentTime()
            delegate?.controlView(self, progressLineDragBeganAt: currentTime)
        case .changed:
            var lineX = beginLineFrame.minX + point.x
            if lineX < bgView.x + frameMaskView.validRect.minX {
                lineX = bgView.x + frameMaskView.validRect.minX
            }
            if lineX > bgView.x + frameMaskView.validRect.maxX - progressLineView.width {
                lineX = bgView.x + frameMaskView.validRect.maxX - progressLineView.width
            }
            progressLineView.x = lineX
            updateCurrentTime()
            delegate?.controlView(self, progressLineDragChangedAt: currentTime)
        case .ended, .cancelled, .failed:
            hideCurrentTime()
            delegate?.controlView(self, progressLineDragEndAt: currentTime)
        default:
            break
        }
    }
    func updateCurrentTime() {
        currentTimeLb.text = currentDuration.time
        currentTimeLb.size = currentTimeLb.textSize
        currentTimeView.size = .init(width: currentTimeLb.width + 10, height: currentTimeLb.size.height + 5)
        currentTimeLb.center = .init(x: currentTimeView.width / 2, y: currentTimeView.height / 2)
        currentLineView.y = -currentLineView.height - 5
        currentLineView.centerX = progressLineView.centerX
        currentTimeView.y = currentLineView.y - currentTimeView.height - 2
        currentTimeView.centerX = currentLineView.centerX
        if currentTimeView.frame.maxX + margin + UIDevice.rightMargin > width {
            currentTimeView.x = width - margin - UIDevice.rightMargin - currentTimeView.width
        }
    }
    func showCurrentTime() {
        if currentLineView.alpha == 1 {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.currentLineView.alpha = 1
            self.currentTimeView.alpha = 1
        }
    }
    
    func hideCurrentTime() {
        UIView.animate(withDuration: 0.2) {
            self.currentLineView.alpha = 0
            self.currentTimeView.alpha = 0
        }
    }
    func resetLineViewFrsme(at time: CMTime) {
        updateLineViewFrame(at: time)
        if isPlaying {
            startLineAnimation()
        }
    }
    func updateLineViewFrame(at time: CMTime) {
        stopLineAnimation()
        let totalDuration = endDuration - startDuration
        let seconds = (time.seconds - startDuration) / totalDuration
        progressLineView.x = bgView.x + frameMaskView.validRect.minX + (
            frameMaskView.validRect.width - progressLineView.width
        ) * CGFloat(seconds)
    }
    func updateLineViewFrame(at time: TimeInterval) {
        stopLineAnimation()
        let totalDuration = endDuration - startDuration
        let seconds = (time - startDuration) / totalDuration
        progressLineView.x = bgView.x + frameMaskView.validRect.minX + (
            frameMaskView.validRect.width - progressLineView.width
        ) * CGFloat(seconds)
    }
    func showLineView(at time: CMTime? = nil) {
        stopLineAnimation()
        if let time = time {
            updateLineViewFrame(at: time)
        }
        if progressLineView.alpha == 1 {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.progressLineView.alpha = 1
        }
    }
    func hideLineView(at time: CMTime? = nil) {
        stopLineAnimation()
        if let time = time {
            updateLineViewFrame(at: time)
        }
        if progressLineView.alpha == 0 {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.progressLineView.alpha = 0
        }
    }
    func startLineAnimation() {
        stopLineAnimation()
        let scale = (
            progressLineView.x - bgView.x - frameMaskView.validRect.minX
        ) / (
            frameMaskView.validRect.width - progressLineView.width
        )
        let totalDuration = endDuration - startDuration
        let duration = totalDuration - totalDuration * scale
        let toX = bgView.x + frameMaskView.validRect.maxX - progressLineView.width
        setLineAnimation(toX: toX, duration: duration)
    }
    func setLineAnimation(toX: CGFloat, duration: TimeInterval) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveLinear, .allowUserInteraction, .overrideInheritedDuration, .overrideInheritedCurve]
        ) {
            self.progressLineView.x = toX
        } completion: { (isFinished) in
            if isFinished {
                self.stopLineAnimation()
                let startX = self.bgView.x + self.frameMaskView.validRect.minX
                self.progressLineView.x = startX
                let totalDuration = self.endDuration - self.startDuration
                self.setLineAnimation(toX: toX, duration: totalDuration)
            }
        }
    }
    func stopLineAnimation() {
        guard let animationKeys = progressLineView.layer.animationKeys(),
              !animationKeys.isEmpty else {
            return
        }
        let rect = progressLineView.layer.presentation()?.frame ?? progressLineView.frame
        progressLineView.layer.removeAllAnimations()
        progressLineView.frame = rect
    }
    func resetValidRect() {
        frameMaskView.validRect = CGRect(
            x: controlWidth,
            y: 0,
            width: bgView.width - controlWidth * 2,
            height: bgView.height
        )
    }
    func updateTimeLabels() {
        if assetDuration == 0 {
            return
        }
        var endDuration = self.endDuration
        if let duration = Double(String(format: "%.2f", arguments: [endDuration])) {
            endDuration = duration
        }
        var startDuration = self.startDuration
        if let duration = Double(String(format: "%.2f", arguments: [startDuration])) {
            startDuration = duration
        }
        var totalDuration = endDuration - startDuration
        if totalDuration > config.maximumTime && config.maximumTime > 0 {
            totalDuration = config.maximumTime
        }
        if endDuration > startDuration + totalDuration {
            endDuration = startDuration + totalDuration
        }
        endTimeLb.text = endDuration.time
        totalTimeLb.text = totalDuration.time
        startTimeLb.text = startDuration.time
        startTimeLb.size = startTimeLb.textSize
        totalTimeLb.size = totalTimeLb.textSize
        endTimeLb.size = endTimeLb.textSize
    }
    var middleDuration: Double {
        endDuration - startDuration
    }
    var startDuration: Double {
        var offsetX = collectionView.contentOffset.x + collectionView.contentInset.left
        let validX = frameMaskView.validRect.minX - controlWidth
        let maxOfssetX = contentWidth - (collectionView.width - collectionView.contentInset.left * 2.0)
        if offsetX > maxOfssetX {
            offsetX = maxOfssetX
        }
        var second = (offsetX + validX) / contentWidth * assetDuration
        if second < 0 {
            second = 0
        }else if second > assetDuration {
            second = assetDuration
        }
        return second
    }
    var startTime: CMTime {
        CMTimeMakeWithSeconds(
            Float64(startDuration),
            preferredTimescale: 1000
        )
    }
    var endDuration: Double {
        let videoSecond = assetDuration
        let validWidth = frameMaskView.validRect.width
        var second = startDuration + validWidth / contentWidth * videoSecond
        if second > videoSecond {
            second = videoSecond
        }
        return second
    }
    var endTime: CMTime {
        CMTimeMakeWithSeconds(
            Float64(endDuration),
            preferredTimescale: 1000
        )
    }
    func stopScroll() {
        let inset = collectionView.contentInset
        var currentOffset = collectionView.contentOffset
        let maxOffsetX = contentWidth - (collectionView.width - inset.left)
        if currentOffset.x < -inset.left {
            currentOffset.x = -inset.left
        }else if currentOffset.x > maxOffsetX {
            currentOffset.x = maxOffsetX
        }
        collectionView.setContentOffset(currentOffset, animated: false)
    }
    
    func showTimeLabels() {
        if assetDuration == 0 {
            return
        }
        timeLabelsTimer?.invalidate()
        if startLineView.alpha == 1 {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.startLineView.alpha = 1
            self.startTimeView.alpha = 1
            self.endLineView.alpha = 1
            self.endTimeView.alpha = 1
            self.totalTimeView.alpha = 1
        }
    }
    
    func hideTimeLabels(_ isDelay: Bool = true) {
        timeLabelsTimer?.invalidate()
        if isDelay {
            timeLabelsTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { [weak self] _ in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.2) {
                    self.startLineView.alpha = 0
                    self.startTimeView.alpha = 0
                    self.endLineView.alpha = 0
                    self.endTimeView.alpha = 0
                    self.totalTimeView.alpha = 0
                }
            })
        }else {
            if startLineView.alpha == 0 {
                return
            }
            UIView.animate(withDuration: 0.2) {
                self.startLineView.alpha = 0
                self.startTimeView.alpha = 0
                self.endLineView.alpha = 0
                self.endTimeView.alpha = 0
                self.totalTimeView.alpha = 0
            }
        }
    }
    
    func updateTimeLabelsFrame() {
        startTimeLb.size = startTimeLb.textSize
        startTimeView.size = .init(width: startTimeLb.width + 10, height: startTimeLb.size.height + 5)
        startTimeLb.center = .init(x: startTimeView.width / 2, y: startTimeView.height / 2)
        totalTimeLb.size = totalTimeLb.textSize
        totalTimeView.size = .init(width: totalTimeLb.width + 10, height: totalTimeLb.size.height + 5)
        totalTimeLb.center = .init(x: totalTimeView.width / 2, y: totalTimeView.height / 2)
        endTimeLb.size = endTimeLb.textSize
        endTimeView.size = .init(width: endTimeLb.width + 10, height: endTimeLb.size.height + 5)
        endTimeLb.center = .init(x: endTimeView.width / 2, y: endTimeView.height / 2)
        
        startLineView.y = -startLineView.height - 5
        startLineView.centerX = bgView.x + frameMaskView.validRect.minX
        
        var startTimeX = startLineView.centerX - startTimeView.width / 2
        startTimeView.y = startLineView.y - startTimeView.height - 2
        
        endLineView.y = -endLineView.height - 5
        endLineView.centerX = bgView.x + frameMaskView.validRect.maxX
        
        var endTimeX = endLineView.centerX - endTimeView.width / 2
        endTimeView.y = endLineView.y - endTimeView.height - 2
        
        if endTimeX + endTimeView.width + margin + UIDevice.rightMargin > width {
            endTimeX = width - margin - UIDevice.rightMargin - endTimeView.width
        }
        if startTimeX + startTimeView.width + 5 > endTimeX {
            startTimeX = endTimeX - 5 - startTimeView.width
        }
        if startTimeX < UIDevice.leftMargin + margin {
            startTimeX = UIDevice.leftMargin + margin
        }
        if endTimeX < startTimeX + startTimeView.width + 5 {
            endTimeX = startTimeX + startTimeView.width + 5
        }
        startTimeView.x = startTimeX
        endTimeView.x = endTimeX
        
        totalTimeView.centerX = bgView.x + frameMaskView.validRect.minX + frameMaskView.validRect.width * 0.5
        if totalTimeView.frame.maxX > width - UIDevice.rightMargin - margin {
            totalTimeView.x = width - UIDevice.rightMargin - margin - totalTimeView.width
        }
        totalTimeView.y = height + 5
    }
}
extension EditorVideoControlView: UICollectionViewDataSource,
                               UICollectionViewDelegate,
                               UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        videoFrameCount
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorVideoControlViewCellID",
            for: indexPath
        ) as! EditorVideoControlViewCell
        return cell
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if indexPath.item < videoFrameCount - 1 {
            return CGSize(width: itemWidth, height: height - 8)
        }
        let itemW = contentWidth - CGFloat(indexPath.item) * itemWidth
        return CGSize(width: itemW, height: height - 8)
    }
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let myCell = cell as! EditorVideoControlViewCell
        self.videoFrameLock.sync {
            if videoFrameMap.keys.contains(indexPath.item),
               let cgImage = videoFrameMap[indexPath.item] {
                myCell.image = UIImage(cgImage: cgImage)
            }else {
                if let result = videoFrameMap.first {
                    myCell.image = UIImage(cgImage: result.value)
                }
            }
        }
    }
    func setCurrentCell(image: UIImage, index: Int) {
        DispatchQueue.main.async {
            let cell = self.collectionView.cellForItem(
                at: IndexPath(item: index, section: 0)
            ) as? EditorVideoControlViewCell
            cell?.image = image
        }
    }
    func getVideoCurrentTime(for index: Int) -> CMTime {
        var second: CGFloat
        let maxIndex = videoFrameCount - 1
        if index == 0 {
            second = 0.1
        }else if index >= maxIndex {
            if assetDuration < 1 {
                second = CGFloat(assetDuration - 0.1)
            }else {
                second = CGFloat(assetDuration - 0.5)
            }
        }else {
            if assetDuration < 1 {
                second = 0
            }else {
                second = CGFloat(index) * interval + interval * 0.5
            }
        }
        let time = CMTimeMakeWithSeconds(Float64(second), preferredTimescale: 1000)
        return time
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if videoFrameCount > 0 {
            if !scrollView.isTracking && !scrollView.isDragging && !scrollView.isDecelerating {
                return
            }
            isBeginScrolling = true
            delegate?.controlView(self, didScrollAt: startTime)
            updateTimeLabels()
            updateTimeLabelsFrame()
            if scrollView.isTracking {
                showTimeLabels()
                hideLineView()
                stopLineAnimation()
            }
        }
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate && isBeginScrolling {
            showLineView(at: startTime)
            delegate?.controlView(self, endScrollAt: startTime)
            updateTimeLabels()
            updateTimeLabelsFrame()
            hideTimeLabels()
        }
        isBeginScrolling = false
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !isBeginScrolling {
            return
        }
        showLineView(at: startTime)
        delegate?.controlView(self, endScrollAt: startTime)
        updateTimeLabels()
        updateTimeLabelsFrame()
        hideTimeLabels()
        isBeginScrolling = false
    }
}

extension EditorVideoControlView: EditorVideoControlMaskViewDelegate {
    func frameMaskView(leftValidRectDidChanged frameMaskView: EditorVideoControlMaskView) {
        updateTimes(true)
        hideLineView(at: startTime)
        delegate?.controlView(self, leftDidChangedValidRectAt: startTime)
    }
    func frameMaskView(leftValidRectEndChanged frameMaskView: EditorVideoControlMaskView) {
        updateTimes(false)
        showLineView(at: startTime)
        delegate?.controlView(self, leftEndChangedValidRectAt: startTime)
    }
    func frameMaskView(rightValidRectDidChanged frameMaskView: EditorVideoControlMaskView) {
        updateTimes(true)
        hideLineView(at: endTime)
        delegate?.controlView(self, rightDidChangedValidRectAt: endTime)
    }
    func frameMaskView(rightValidRectEndChanged frameMaskView: EditorVideoControlMaskView) {
        updateTimes(false)
        showLineView(at: endTime)
        delegate?.controlView(self, rightEndChangedValidRectAt: endTime)
    }
    
    func updateTimes(_ isShow: Bool) {
        let totalDuration = endDuration - startDuration
        frameMaskView.isShowFrame = totalDuration < assetDuration
        updateTimeLabels()
        updateTimeLabelsFrame()
        if isShow {
            showTimeLabels()
        }else {
            hideTimeLabels()
        }
    }
}

struct EditorVideoControlInfo: Codable {
    let offsetXScale: CGFloat
    let validXScale: CGFloat
    let validWithScale: CGFloat
}

extension EditorVideoControlView {
    
    var controlInfo: EditorVideoControlInfo {
        let offsetX = collectionView.contentOffset.x
        let validX = frameMaskView.validRect.minX
        let validWidth = frameMaskView.validRect.width
        
        let insert = collectionView.contentInset
        let offsetXScale = (offsetX + insert.left) / contentWidth
        let validInitialX = controlWidth
        let validMaxWidth = bgView.width - validInitialX * 2
        let validXScale = (validX - validInitialX) / validMaxWidth
        let validWithScale = validWidth / validMaxWidth
        return .init(offsetXScale: offsetXScale, validXScale: validXScale, validWithScale: validWithScale)
    }
    
    func setControlInfo(_ info: EditorVideoControlInfo) {
        if avAsset == nil {
            return
        }
        let insert = collectionView.contentInset
        let offsetX = -insert.left + contentWidth * info.offsetXScale
        collectionView.setContentOffset(CGPoint(x: offsetX, y: -insert.top), animated: false)
        let validInitialX = controlWidth
        let validMaxWidth = bgView.width - validInitialX * 2
        let validX = validMaxWidth * info.validXScale + validInitialX
        let vaildWidth = validMaxWidth * info.validWithScale
        frameMaskView.validRect = CGRect(x: validX, y: 0, width: vaildWidth, height: bgView.height)
        let totalDuration = endDuration - startDuration
        frameMaskView.isShowFrame = totalDuration < assetDuration
        frameMaskView.updateFrameView()
        updateTimeLabels()
        updateTimeLabelsFrame()
        showLineView(at: startTime)
    }
}

fileprivate extension Double {
    var time: String {
        if self < 60 {
            let sec = Double(String(format: "%.2f", arguments: [self])) ?? self
            if sec < 10 {
                return String(format: "00:0%.2f", arguments: [sec])
            }else {
                return String(format: "00:%.2f", arguments: [sec])
            }
        }else {
            var min = Double(Int(self / 60))
            let sec = Double(String(format: "%.2f", arguments: [self - (min * 60)])) ?? self - (min * 60)
            if min < 60 {
                if min < 10 {
                    if sec < 10 {
                        return String(format: "0%.0f:0%.2f", arguments: [min, sec])
                    }else {
                        return String(format: "0%.0f:%.2f", arguments: [min, sec])
                    }
                }else {
                    if sec < 10 {
                        return String(format: "%.0f:0%.2f", arguments: [min, sec])
                    }else {
                        return String(format: "%.0f:%.2f", arguments: [min, sec])
                    }
                }
            }else {
                let hour = Double(Int(min / 60))
                min -= hour * 60
                if hour < 10 {
                    if min < 10 {
                        if sec < 10 {
                            return String(format: "0%.0f:0%.0f:0%.2f", arguments: [hour, min, sec])
                        }else {
                            return String(format: "0%.0f:0%.0f:%.2f", arguments: [hour, min, sec])
                        }
                    }else {
                        if sec < 10 {
                            return String(format: "0%.0f:%.0f:0%.2f", arguments: [hour, min, sec])
                        }else {
                            return String(format: "0%.0f:%.0f:%.2f", arguments: [hour, min, sec])
                        }
                    }
                }
                if min < 10 {
                    if sec < 10 {
                        return String(format: "%.0f:0%.0f:0%.2f", arguments: [hour, min, sec])
                    }else {
                        return String(format: "%.0f:0%.0f:%.2f", arguments: [hour, min, sec])
                    }
                }else {
                    if sec < 10 {
                        return String(format: "%.0f:%.0f:0%.2f", arguments: [hour, min, sec])
                    }else {
                        return String(format: "%.0f:%.0f:%.2f", arguments: [hour, min, sec])
                    }
                }
            }
        }
    }
}
