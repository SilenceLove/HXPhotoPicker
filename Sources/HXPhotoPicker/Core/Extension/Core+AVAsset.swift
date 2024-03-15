//
//  Core+AVAsset.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/1/12.
//

import UIKit
import AVFoundation

extension AVAsset {
    func getImage(at time: TimeInterval, videoComposition: AVVideoComposition? = nil) -> UIImage? {
        let assetImageGenerator = AVAssetImageGenerator(asset: self)
        assetImageGenerator.appliesPreferredTrackTransform = true
        assetImageGenerator.videoComposition = videoComposition
        assetImageGenerator.apertureMode = .encodedPixels
        do {
            let thumbnailImageRef = try assetImageGenerator.copyCGImage(
                at: CMTime(
                    value: CMTimeValue(time),
                    timescale: duration.timescale
                ),
                actualTime: nil
            )
            let image = UIImage.init(cgImage: thumbnailImageRef)
            return image
        } catch {
            return nil
        }
    }
    func getImage(
        at time: TimeInterval,
        videoComposition: AVVideoComposition? = nil,
        imageGenerator: ((AVAssetImageGenerator) -> Void)? = nil,
        completion: @escaping (AVAsset, UIImage?, AVAssetImageGenerator.Result) -> Void
    ) {
        loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(.init(), nil, .failed)
                }
                return
            }
            if self.statusOfValue(forKey: "duration", error: nil) != .loaded {
                DispatchQueue.main.async {
                    completion(self, nil, .failed)
                }
                return
            }
            let generator = AVAssetImageGenerator(asset: self)
            generator.appliesPreferredTrackTransform = true
            generator.videoComposition = videoComposition
            let time = CMTime(value: CMTimeValue(time), timescale: self.duration.timescale)
            let array = [NSValue(time: time)]
            generator.generateCGImagesAsynchronously(
                forTimes: array
            ) { (_, cgImage, _, result, _) in
                if let image = cgImage, result == .succeeded {
                    var image = UIImage(cgImage: image)
                    if image.imageOrientation != .up,
                       let img = image.normalizedImage() {
                        image = img
                    }
                    DispatchQueue.main.async {
                        completion(self, image, result)
                    }
                }else {
                    DispatchQueue.main.async {
                        completion(self, nil, result)
                    }
                }
            }
            DispatchQueue.main.async {
                imageGenerator?(generator)
            }
        }
    }
}
