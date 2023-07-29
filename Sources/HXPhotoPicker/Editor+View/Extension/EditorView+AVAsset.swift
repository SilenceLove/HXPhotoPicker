//
//  EditorView+AVAsset.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/2/25.
//

import UIKit
import AVFoundation

extension AVAsset {
     
    var videoOrientation: EditorVideoOrientation {
        guard let videoTrack = tracks(withMediaType: .video).first else {
            return .landscapeRight
        }
        
        let t = videoTrack.preferredTransform
        
        if (t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) ||
            (t.a == 0 && t.b == 1.0 && t.c == 1.0 && t.d == 0) {
            return .portrait // 90
        } else if (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) ||
                    (t.a == 0 && t.b == -1.0 && t.c == -1.0 && t.d == 0) {
            return .portraitUpsideDown // 270
        } else if t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0 {
            return .landscapeRight // 0
        } else if t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0 {
            return .landscapeLeft // 180
        } else {
            return .landscapeRight
        }
    }
}
