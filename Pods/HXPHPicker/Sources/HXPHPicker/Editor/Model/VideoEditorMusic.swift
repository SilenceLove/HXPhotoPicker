//
//  VideoEditorMusic.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/21.
//

import UIKit

public struct VideoEditorMusicInfo {
    
    public enum URLType: Int, Codable {
        case unknown
        case local
        case network
    }
    
    /// 音频文件本地/网络地址(MP3格式)
    public let audioURL: URL
    
    /// 歌词lrc内容(包含歌名和歌手名的话会显示)
    /// 内容必须有 t_time 如: [t_time:(00:38)] 音频时长
    /// 每段歌词必须包含时间点 [00:00.000]
    /// 如果不包含的话那么显示歌词功能将会出错
    public let lrc: String
    
    public init(
        audioURL: URL,
        lrc: String) {
        self.audioURL = audioURL
        self.lrc = lrc
    }
}

class VideoEditorMusic: Equatable, Codable {
    let audioURL: URL
    let lrc: String
    init(audioURL: URL,
         lrc: String) {
        self.audioURL = audioURL
        self.lrc = lrc
    }
    
    var isLoading: Bool = false
    var isSelected: Bool = false
    
    var localAudioPath: String?
    var metaData: [String: String] = [:]
    var lyrics: [VideoEditorLyric] = []
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
            return PhotoTools.getVideoTime(forVideo: time)
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
                    let lyric = VideoEditorLyric.init(lyric: modifyString)
                    lyric.update(second: sec, isEnd: false)
                    lyrics.append(lyric)
                }
                if matches.isEmpty {
                    let lyric = VideoEditorLyric.init(lyric: line)
                    lyrics.append(lyric)
                }
            }
        }
        let sorted = lyrics.sorted { (lyric1, lyric2) -> Bool in
            lyric1.startTime < lyric2.startTime
        }
        var first: VideoEditorLyric?
        var second: VideoEditorLyric?
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
            lyrics.append(.init(lyric: "此歌曲暂无歌词，请您欣赏".localized))
        }
    }
     
    func lyric(
        atTime time: TimeInterval
    ) -> VideoEditorLyric? {
        if lyricIsEmpty {
            return .init(lyric: "此歌曲暂无歌词，请您欣赏".localized)
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
    ) -> [VideoEditorLyric] {
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
    ) -> VideoEditorLyric? {
        lyric(
            atRange:
                NSRange(
                    location: line,
                    length: 1
                )
        ).first
    }
    public static func == (
        lhs: VideoEditorMusic,
        rhs: VideoEditorMusic
    ) -> Bool {
        lhs === rhs
    }
}

class VideoEditorLyric: Equatable, Codable {
    
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
        let time = PhotoTools.getVideoTime(
            forVideo: self.second
        )
        if isEnd {
            endTime = time
        }else {
            startTime = time
        }
    }
    
    static func == (
        lhs: VideoEditorLyric,
        rhs: VideoEditorLyric
    ) -> Bool {
        lhs === rhs
    }
}
