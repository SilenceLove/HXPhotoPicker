//
//  VideoEditorCropView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit
import AVKit

protocol VideoEditorCropViewDelegate: AnyObject {
    func cropView(_ cropView: VideoEditorCropView, didChangedValidRectAt time: CMTime)
    func cropView(_ cropView: VideoEditorCropView, endChangedValidRectAt time: CMTime)
    func cropView(_ cropView: VideoEditorCropView, progressLineDragBeganAt time: CMTime)
    func cropView(_ cropView: VideoEditorCropView, progressLineDragChangedAt time: CMTime)
    func cropView(_ cropView: VideoEditorCropView, progressLineDragEndAt time: CMTime)
    func cropView(_ cropView: VideoEditorCropView, didScrollAt time: CMTime)
    func cropView(_ cropView: VideoEditorCropView, endScrollAt time: CMTime)
}

class VideoEditorCropView: UIView {
    
    weak var delegate: VideoEditorCropViewDelegate?
    
    let imageWidth: CGFloat = 8
    var validRectX: CGFloat {
        30 + UIDevice.leftMargin
    }
    var contentWidth: CGFloat = 0
    var avAsset: AVAsset! {
        didSet {
            videoSize = PhotoTools.getVideoThumbnailImage(avAsset: avAsset, atTime: 0.1)?.size ?? .zero
        }
    }
    var config: VideoCropTimeConfiguration
    
    var videoFrameCount: Int = 0
    lazy var frameMaskView: VideoEditorFrameMaskView = {
        let frameMaskView = VideoEditorFrameMaskView.init()
        frameMaskView.delegate = self
        return frameMaskView
    }()
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        return flowLayout
    }()
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView.init(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(VideoEditorCropViewCell.self, forCellWithReuseIdentifier: "VideoEditorCropViewCellID")
        return collectionView
    }()
    lazy var startTimeLb: UILabel = {
        let startTimeLb = UILabel.init()
        startTimeLb.font = UIFont.mediumPingFang(ofSize: 12)
        startTimeLb.textColor = .white
        return startTimeLb
    }()
    lazy var endTimeLb: UILabel = {
        let endTimeLb = UILabel.init()
        endTimeLb.textAlignment = .right
        endTimeLb.font = UIFont.mediumPingFang(ofSize: 12)
        endTimeLb.textColor = .white
        return endTimeLb
    }()
    lazy var totalTimeLb: UILabel = {
        let totalTimeLb = UILabel.init()
        totalTimeLb.textAlignment = .center
        totalTimeLb.font = UIFont.mediumPingFang(ofSize: 12)
        totalTimeLb.textColor = .white
        return totalTimeLb
    }()
    lazy var progressLineView: UIView = {
        let lineView = UIView.init()
        lineView.backgroundColor = .white
        lineView.layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        lineView.layer.shadowOpacity = 0.5
        lineView.isHidden = true
        return lineView
    }()
    lazy var videoFrameMap: [Int: CGImage] = [:]
    
    var videoSize: CGSize = .zero
    /// 一个item代表多少秒
    var interval: CGFloat = -1
    var itemWidth: CGFloat = 0
    var itemHeight: CGFloat = 60
    var lineDidAnimate = false
    var imageGenerator: AVAssetImageGenerator?
    
    convenience init(avAsset: AVAsset, config: VideoCropTimeConfiguration) {
        self.init(config: config)
        self.avAsset = avAsset
        videoSize = PhotoTools.getVideoThumbnailImage(avAsset: avAsset, atTime: 0.1)?.size ?? .zero
    }
    
    init(config: VideoCropTimeConfiguration) {
        self.config = config
        super.init(frame: .zero)
        addSubview(collectionView)
        addSubview(frameMaskView)
        addSubview(startTimeLb)
        addSubview(endTimeLb)
        addSubview(totalTimeLb)
        addSubview(progressLineView)
    }
    
    func configData() {
        imageGenerator?.cancelAllCGImageGeneration()
        videoFrameMap.removeAll()
        
        collectionView.contentInset = UIEdgeInsets(
            top: 2,
            left: validRectX + imageWidth,
            bottom: 2,
            right: validRectX + imageWidth
        )
        let cellHeight = itemHeight - 4
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
        resetValidRect()
        var videoSecond = videoDuration()
        if videoSecond <= 0 {
            videoSecond = 1
        }
        let maxWidth = width - validRectX * 2 - imageWidth * 2
        var singleItemSecond: CGFloat
        var videoMaximumCropDuration: CGFloat = CGFloat(config.maximumVideoCroppingTime)
        if videoMaximumCropDuration < 1 {
            videoMaximumCropDuration = 1
        }
        if videoSecond <= videoMaximumCropDuration {
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
            var videoMinimunCropDuration = CGFloat(config.minimumVideoCroppingTime)
            if videoMinimunCropDuration < 1 {
                videoMinimunCropDuration = 1
            }
            let scale = videoMinimunCropDuration / videoSecond
            frameMaskView.minWidth = contentWidth * scale
        }
        collectionView.reloadData()
        getVideoFrame()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        startTimeLb.frame = CGRect(x: validRectX, y: 0, width: 100, height: 20)
        endTimeLb.frame = CGRect(x: width - validRectX - 100, y: 0, width: 100, height: 20)
        collectionView.frame = CGRect(x: 0, y: 20, width: width, height: itemHeight)
        frameMaskView.frame = collectionView.frame
        totalTimeLb.frame = CGRect(x: 0, y: collectionView.frame.maxY, width: 100, height: 20)
        totalTimeLb.centerX = width * 0.5
        if frameMaskView.validRect.equalTo(.zero) {
            resetValidRect()
        }
    }
    deinit {
        imageGenerator?.cancelAllCGImageGeneration()
        videoFrameMap.removeAll()
//        print("deinit \(self)")
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// MARK: function
extension VideoEditorCropView {
    func startLineAnimation(at time: CMTime) {
//        if lineDidAnimate {
//            return
//        }
//        lineDidAnimate = true
//        let duration = getEndDuration() - CGFloat(time.seconds)
        let duration = getEndDuration(real: true) - CGFloat(time.seconds)
        let mixX = frameMaskView.leftControl.frame.maxX
        var x: CGFloat
        if time.seconds == getStartTime(real: true).seconds {
            x = mixX
        }else {
            x = CGFloat(time.seconds / avAsset.duration.seconds) * contentWidth - collectionView.contentOffset.x
        }
        setLineAnimation(x: x, duration: TimeInterval(duration))
    }
    func setLineAnimation(x: CGFloat, duration: TimeInterval) {
        progressLineView.layer.removeAllAnimations()
        let maxX = frameMaskView.validRect.maxX - 2 - imageWidth * 0.5
        progressLineView.frame = CGRect(x: x, y: collectionView.y, width: 2, height: collectionView.height)
        progressLineView.isHidden = false
        UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear]) {
            self.progressLineView.x = maxX
        } completion: { (isFinished) in
//            if self.lineDidAnimate && isFinished {
//                let mixX = self.frameMaskView.leftControl.frame.maxX
//                let duration = self.getEndDuration(real: true) - self.getStartDuration(real: true)
//                self.setLineAnimation(x: mixX, duration: TimeInterval(duration))
//            }
        }
    }
    func stopLineAnimation() {
        lineDidAnimate = false
        progressLineView.isHidden = true
        progressLineView.layer.removeAllAnimations()
    }
    func resetValidRect() {
        let imgWidth = imageWidth * 0.5
        frameMaskView.validRect = CGRect(
            x: validRectX + imgWidth,
            y: 0,
            width: width - (validRectX + imgWidth) * 2,
            height: itemHeight
        )
    }
    func videoDuration(real: Bool = false) -> CGFloat {
        if real {
            return CGFloat(avAsset.duration.seconds)
        }
        return CGFloat(round(avAsset.duration.seconds))
    }
    func getRotateBeforeData() -> (  // swiftlint:disable:this large_tuple
        offsetXScale: CGFloat,
        validXScale: CGFloat,
        validWithScale: CGFloat
    ) {
        return getRotateBeforeData(
            offsetX: collectionView.contentOffset.x,
            validX: frameMaskView.validRect.minX,
            validWidth: frameMaskView.validRect.width
        )
    }
    func getRotateBeforeData(
        offsetX: CGFloat,
        validX: CGFloat,
        validWidth: CGFloat
    ) -> ( // swiftlint:disable:this large_tuple
        offsetXScale: CGFloat,
        validXScale: CGFloat,
        validWithScale: CGFloat
    ) {
        let insert = collectionView.contentInset
        let offsetXScale = (offsetX + insert.left) / contentWidth
        let validInitialX = validRectX + imageWidth * 0.5
        let validMaxWidth = width - validInitialX * 2
        let validXScale = (validX - validInitialX) / validMaxWidth
        let validWithScale = validWidth / validMaxWidth
        return (offsetXScale, validXScale, validWithScale)
    }
    func rotateAfterSetData(
        offsetXScale: CGFloat,
        validXScale: CGFloat,
        validWithScale: CGFloat
    ) {
        let insert = collectionView.contentInset
        let offsetX = -insert.left + contentWidth * offsetXScale
        collectionView.setContentOffset(CGPoint(x: offsetX, y: -insert.top), animated: false)
        let validInitialX = validRectX + imageWidth * 0.5
        let validMaxWidth = width - validInitialX * 2
        let validX = validMaxWidth * validXScale + validInitialX
        let vaildWidth = validMaxWidth * validWithScale
        frameMaskView.validRect = CGRect(x: validX, y: 0, width: vaildWidth, height: itemHeight)
    }
    func updateTimeLabels() {
        if avAsset == nil {
            return
        }
        let startDuration = getStartDuration(real: true)
        var endDuration = round(getEndDuration(real: true))
        var totalDuration = round(endDuration - startDuration)
        if totalDuration > CGFloat(config.maximumVideoCroppingTime) {
            totalDuration = CGFloat(config.maximumVideoCroppingTime)
        }
        if endDuration > startDuration + totalDuration {
            endDuration = startDuration + totalDuration
        }
        endTimeLb.text = PhotoTools.transformVideoDurationToString(
            duration: TimeInterval(
                endDuration
            )
        )
        totalTimeLb.text = PhotoTools.transformVideoDurationToString(
            duration: TimeInterval(
                totalDuration
            )
        )
        startTimeLb.text = PhotoTools.transformVideoDurationToString(
            duration: TimeInterval(
                round(startDuration)
            )
        )
    }
    func getMiddleDuration(real: Bool = false) -> CGFloat {
        let validWidth = frameMaskView.validRect.width - imageWidth
        let second = validWidth / contentWidth * videoDuration(real: real)
        return second
    }
    func getStartDuration(real: Bool = false) -> CGFloat {
        var offsetX = collectionView.contentOffset.x + collectionView.contentInset.left
        let validX = frameMaskView.validRect.minX + imageWidth * 0.5 - collectionView.contentInset.left
        let maxOfssetX = contentWidth - (collectionView.width - collectionView.contentInset.left * 2.0)
        if offsetX > maxOfssetX {
            offsetX = maxOfssetX
        }
        var second = (offsetX + validX) / contentWidth * videoDuration(real: real)
        if second < 0 {
            second = 0
        }else if second > videoDuration(real: real) {
            second = videoDuration(real: real)
        }
        return second
    }
    func getStartTime(real: Bool = false) -> CMTime {
        CMTimeMakeWithSeconds(
            Float64(getStartDuration(real: real)),
            preferredTimescale: avAsset.duration.timescale
        )
    }
    func getEndDuration(real: Bool = false) -> CGFloat {
        let videoSecond = videoDuration(real: real)
        let validWidth = frameMaskView.validRect.width - imageWidth * 0.5
        var second = getStartDuration(real: real) + validWidth / contentWidth * videoSecond
        if second > videoSecond {
            second = videoSecond
        }
        return second
    }
    func getEndTime(real: Bool = false) -> CMTime {
        CMTimeMakeWithSeconds(
            Float64(getEndDuration(real: real)),
            preferredTimescale: avAsset.duration.timescale
        )
    }
    func stopScroll(_ offset: CGPoint?) {
        let inset = collectionView.contentInset
        var currentOffset = offset ?? collectionView.contentOffset
        let maxOffsetX = contentWidth - (collectionView.width - inset.left)
        if currentOffset.x < -inset.left {
            currentOffset.x = -inset.left
        }else if currentOffset.x > maxOffsetX {
            currentOffset.x = maxOffsetX
        }
        collectionView.setContentOffset(currentOffset, animated: false)
    }
}
extension VideoEditorCropView: UICollectionViewDataSource,
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
            withReuseIdentifier: "VideoEditorCropViewCellID",
            for: indexPath
        ) as! VideoEditorCropViewCell
        return cell
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if indexPath.item < videoFrameCount - 1 {
            return CGSize(width: itemWidth, height: itemHeight - 4)
        }
        let itemW = contentWidth - CGFloat(indexPath.item) * itemWidth
        return CGSize(width: itemW, height: itemHeight - 4)
    }
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if let cgImage = videoFrameMap[indexPath.item] {
            let myCell = cell as! VideoEditorCropViewCell
            myCell.image = UIImage.init(cgImage: cgImage)
        }
    }
    func setCurrentCell(image: UIImage, index: Int) {
        DispatchQueue.main.async {
            let cell = self.collectionView.cellForItem(
                at: IndexPath(item: index, section: 0)
            ) as? VideoEditorCropViewCell
            cell?.image = image
        }
    }
    func getVideoCurrentTime(for index: Int) -> CMTime {
        var second: CGFloat
        let maxIndex = videoFrameCount - 1
        if index == 0 {
            second = 0.1
        }else if index >= maxIndex {
            if avAsset.duration.seconds < 1 {
                second = CGFloat(avAsset.duration.seconds - 0.1)
            }else {
                second = CGFloat(avAsset.duration.seconds - 0.5)
            }
        }else {
            if avAsset.duration.seconds < 1 {
                second = 0
            }else {
                second = CGFloat(index) * interval + interval * 0.5
            }
        }
        let time = CMTimeMakeWithSeconds(Float64(second), preferredTimescale: avAsset.duration.timescale)
        return time
    }
    func getVideoFrame() {
        if videoFrameCount < 0 {
            return
        }
        imageGenerator = AVAssetImageGenerator(asset: avAsset)
        imageGenerator?.maximumSize = CGSize(width: itemWidth * 2, height: itemHeight * 2)
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
        imageGenerator?.generateCGImagesAsynchronously(forTimes: times) { (time, cgImage, actualTime, result, error) in
            if result != .cancelled {
                if let cgImage = cgImage {
                    self.videoFrameMap[index] = cgImage
                    if hasError {
                        for inde in errorIndex {
                            self.setCurrentCell(image: UIImage.init(cgImage: cgImage), index: inde)
                        }
                        errorIndex.removeAll()
                        hasError = false
                    }
                    self.setCurrentCell(image: UIImage.init(cgImage: cgImage), index: index)
                }else {
                    if let cgImage = self.videoFrameMap[index - 1] {
                        self.setCurrentCell(image: UIImage.init(cgImage: cgImage), index: index)
                    }else {
                        errorIndex.append(index)
                        hasError = true
                    }
                }
                index += 1
            }
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if videoFrameCount > 0 {
            delegate?.cropView(self, didScrollAt: getStartTime(real: true))
            updateTimeLabels()
        }
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            delegate?.cropView(self, endScrollAt: getStartTime(real: true))
            updateTimeLabels()
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.cropView(self, endScrollAt: getStartTime(real: true))
        updateTimeLabels()
    }
}

extension VideoEditorCropView: VideoEditorFrameMaskViewDelegate {
    func frameMaskView(validRectDidChanged frameMaskView: VideoEditorFrameMaskView) {
        delegate?.cropView(self, didChangedValidRectAt: getStartTime(real: true))
        updateTimeLabels()
    }
    func frameMaskView(validRectEndChanged frameMaskView: VideoEditorFrameMaskView) {
        delegate?.cropView(self, endChangedValidRectAt: getStartTime(real: true))
        updateTimeLabels()
    }
}
