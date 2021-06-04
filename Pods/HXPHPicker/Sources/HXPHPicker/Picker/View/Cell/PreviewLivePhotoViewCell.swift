//
//  PreviewLivePhotoViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit

class PreviewLivePhotoViewCell: PhotoPreviewViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = PhotoPreviewContentView.init(type: .livePhoto)
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
