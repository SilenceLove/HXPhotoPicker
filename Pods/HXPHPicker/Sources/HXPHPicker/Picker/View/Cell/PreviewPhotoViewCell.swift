//
//  PreviewPhotoViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit
 
class PreviewPhotoViewCell: PhotoPreviewViewCell, PhotoPreviewContentViewDelete {
     
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = PhotoPreviewContentView.init(type: .photo)
        scrollContentView.delegate = self
        initView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func contentView(requestSucceed contentView: PhotoPreviewContentView) {
        delegate?.cell(requestSucceed: self)
    }
    func contentView(requestFailed contentView: PhotoPreviewContentView) {
        delegate?.cell(requestFailed: self)
    }
    func contentView(updateContentSize contentView: PhotoPreviewContentView) {
        setupScrollViewContentSize()
    }
    
    func contentView(networkImagedownloadSuccess contentView: PhotoPreviewContentView) {
        delegate?.photoCell(networkImagedownloadSuccess: self)
    }
    func contentView(networkImagedownloadFailed contentView: PhotoPreviewContentView) {
        delegate?.photoCell(networkImagedownloadFailed: self)
    }
}
