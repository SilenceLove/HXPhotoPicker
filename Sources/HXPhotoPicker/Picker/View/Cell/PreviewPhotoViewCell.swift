//
//  PreviewPhotoViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit
 
class PreviewPhotoViewCell: PhotoPreviewViewCell, PhotoPreviewContentViewDelete {
     
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = PhotoPreviewContentPhotoView()
        scrollContentView.delegate = self
        initView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func contentView(requestSucceed contentView: PhotoPreviewContentViewProtocol) {
        delegate?.cell(requestSucceed: self)
    }
    func contentView(requestFailed contentView: PhotoPreviewContentViewProtocol) {
        delegate?.cell(requestFailed: self)
    }
    func contentView(updateContentSize contentView: PhotoPreviewContentViewProtocol) {
        setupScrollViewContentSize()
    }
    
    func contentView(networkImagedownloadSuccess contentView: PhotoPreviewContentViewProtocol) {
        delegate?.photoCell(networkImagedownloadSuccess: self)
    }
    func contentView(networkImagedownloadFailed contentView: PhotoPreviewContentViewProtocol) {
        delegate?.photoCell(networkImagedownloadFailed: self)
    }
}
