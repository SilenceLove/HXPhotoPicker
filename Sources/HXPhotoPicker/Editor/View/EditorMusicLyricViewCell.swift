//
//  EditorMusicLyricViewCell.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/20.
//

import UIKit

class EditorMusicLyricViewCell: UICollectionViewCell {
    
    var lyricLb: UILabel!
    
    var lyric: VideoEditorLyric! {
        didSet {
            lyricLb.text = lyric.lyric
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        lyricLb = UILabel()
        lyricLb.font = .mediumPingFang(ofSize: 16)
        lyricLb.textColor = .white
        contentView.addSubview(lyricLb)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        lyricLb.frame = bounds
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
