//
//  VideoEditorMusicLyricViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/26.
//

import UIKit

class VideoEditorMusicLyricViewCell: UICollectionViewCell {
    
    lazy var lyricLb: UILabel = {
        let label = UILabel.init()
        label.font = .mediumPingFang(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    var lyric: VideoEditorLyric! {
        didSet {
            lyricLb.text = lyric.lyric
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
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
