//
//  Core+AVAsset.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/1/12.
//

import UIKit
import AVFoundation

extension AVAsset: HXPickerCompatibleValue {
    func getImage(at time: TimeInterval) -> UIImage? {
        let assetImageGenerator = AVAssetImageGenerator(asset: self)
        assetImageGenerator.appliesPreferredTrackTransform = true
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
            let time = CMTime(value: CMTimeValue(time), timescale: self.duration.timescale)
            let array = [NSValue(time: time)]
            generator.generateCGImagesAsynchronously(
                forTimes: array
            ) { (requestedTime, cgImage, actualTime, result, error) in
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

public extension HXPickerWrapper where Base == AVAsset {
    
    func getImage(at time: TimeInterval) -> UIImage? {
        base.getImage(at: time)
    }
    
    func getImage(
        at time: TimeInterval,
        imageGenerator: ((AVAssetImageGenerator) -> Void)? = nil,
        completion: @escaping (AVAsset, UIImage?, AVAssetImageGenerator.Result) -> Void
    ) {
        base.getImage(
            at: time,
            imageGenerator: imageGenerator,
            completion: completion
        )
    }
}
