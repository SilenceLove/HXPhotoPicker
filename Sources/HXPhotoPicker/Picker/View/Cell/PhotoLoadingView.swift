//
//  PhotoLoadingView.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2023/6/17.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

class PhotoLoadingView: UIView {
    
    private var loadingView: ProgressIndefiniteView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black.withAlphaComponent(0.6)
        loadingView = ProgressIndefiniteView(frame: .init(origin: .zero, size: .init(width: 20, height: 20)))
        addSubview(loadingView)
    }
    
    var progress: CGFloat = 0 {
        didSet {
            if loadingView.isAnimating {
                loadingView.stopAnimating()
            }
            if loadingView.circleLayer.mask != nil {
                loadingView.circleLayer.mask = nil
            }
            loadingView.progress = progress
        }
    }
    
    func startAnimating() {
        loadingView.stopAnimating()
        loadingView.resetMask()
        loadingView.startAnimating()
    }
    
    func stopAnimating() {
        loadingView.stopAnimating()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        loadingView.center = .init(x: width / 2, y: height / 2)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
