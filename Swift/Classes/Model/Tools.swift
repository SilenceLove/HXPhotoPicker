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
        let lyricUrl1 = Bundle.main.url(forResource: "天外来物", withExtension: nil)!
        let lrc1 = try! String(contentsOfFile: lyricUrl1.path) // swiftlint:disable:this force_try
        let music1 = VideoEditorMusicInfo(audioURL: .network(url: URL(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/%E5%A4%A9%E5%A4%96%E6%9D%A5%E7%89%A9.mp3")!), // swiftlint:disable:this line_length
                                               lrc: lrc1)
        musics.append(music1)
        let lyricUrl2 = Bundle.main.url(forResource: "嘉宾", withExtension: nil)!
        let lrc2 = try! String(contentsOfFile: lyricUrl2.path) // swiftlint:disable:this force_try
        let music2 = VideoEditorMusicInfo(audioURL: .bundle(resource: "嘉宾", type: "mp3"),
                                               lrc: lrc2)
        musics.append(music2)
        let lyricUrl3 = Bundle.main.url(forResource: "少女的祈祷", withExtension: nil)!
        let lrc3 = try! String(contentsOfFile: lyricUrl3.path) // swiftlint:disable:this force_try
        let music3 = VideoEditorMusicInfo.init(audioURL: .bundle(resource: "少女的祈祷", type: "mp3"),
                                               lrc: lrc3)
        musics.append(music3)
        let lyricUrl4 = Bundle.main.url(forResource: "野孩子", withExtension: nil)!
        let lrc4 = try! String(contentsOfFile: lyricUrl4.path) // swiftlint:disable:this force_try
        let music4 = VideoEditorMusicInfo.init(audioURL: .bundle(resource: "野孩子", type: "mp3"),
                                               lrc: lrc4)
        musics.append(music4)
        let lyricUrl5 = Bundle.main.url(forResource: "无赖", withExtension: nil)!
        let lrc5 = try! String(contentsOfFile: lyricUrl5.path) // swiftlint:disable:this force_try
        let music5 = VideoEditorMusicInfo.init(audioURL: .bundle(resource: "无赖", type: "mp3"),
                                               lrc: lrc5)
        musics.append(music5)
        let lyricUrl6 = Bundle.main.url(forResource: "时光正好", withExtension: nil)!
        let lrc6 = try! String(contentsOfFile: lyricUrl6.path) // swiftlint:disable:this force_try
        let music6 = VideoEditorMusicInfo.init(audioURL: .bundle(resource: "时光正好", type: "mp3"),
                                               lrc: lrc6)
        musics.append(music6)
        let lyricUrl7 = Bundle.main.url(forResource: "世间美好与你环环相扣", withExtension: nil)!
        let lrc7 = try! String(contentsOfFile: lyricUrl7.path) // swiftlint:disable:this force_try
        let music7 = VideoEditorMusicInfo.init(audioURL: .bundle(resource: "世间美好与你环环相扣", type: "mp3"),
                                               lrc: lrc7)
        musics.append(music7)
        let lyricUrl8 = Bundle.main.url(forResource: "爱你", withExtension: nil)!
        let lrc8 = try! String(contentsOfFile: lyricUrl8.path) // swiftlint:disable:this force_try
        let music8 = VideoEditorMusicInfo.init(audioURL: .bundle(resource: "爱你", type: "mp3"),
                                               lrc: lrc8)
        musics.append(music8)
        return musics
    }
}
