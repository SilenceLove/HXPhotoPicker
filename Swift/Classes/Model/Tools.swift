//
//  Tools.swift
//  Example
//
//  Created by Silence on 2023/5/31.
//

import UIKit
import HXPhotoPicker

struct Tools {
    
    static var musicInfos: [VideoEditorMusicInfo] {
        var musics: [VideoEditorMusicInfo] = []
        
//        let lyricUrl1 = Bundle.main.url(forResource: "天外来物", withExtension: nil)!
//        let lrc1 = try! String(contentsOfFile: lyricUrl1.path) // swiftlint:disable:this force_try
//        let music1 = VideoEditorMusicInfo(audioURL: .network(url: URL(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/%E5%A4%A9%E5%A4%96%E6%9D%A5%E7%89%A9.mp3")!), // swiftlint:disable:this line_length
//                                               lrc: lrc1)
//        musics.append(music1)
        
        let lyricUrl7 = Bundle.main.url(forResource: "世间美好与你环环相扣", withExtension: nil)!
        let lrc7 = try! String(contentsOfFile: lyricUrl7.path) // swiftlint:disable:this force_try
        let music7 = VideoEditorMusicInfo.init(audioURL: .bundle(resource: "世间美好与你环环相扣", type: "mp3"),
                                               lrc: lrc7)
        musics.append(music7)
        return musics
    }
}
