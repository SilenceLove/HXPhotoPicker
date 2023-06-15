//
//  EditorMusicLyricViewCell.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/20.
//

import UIKit

class EditorMusicLyricViewCell: UICollectionViewCell {
    
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
