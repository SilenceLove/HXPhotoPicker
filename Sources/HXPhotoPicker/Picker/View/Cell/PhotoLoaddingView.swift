//
//  PhotoLoaddingView.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2023/6/17.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit

class PhotoLoaddingView: UIView {
    
    lazy var loaddingView: ProgressIndefiniteView = {
        let view = ProgressIndefiniteView(frame: .init(origin: .zero, size: .init(width: 20, height: 20)))
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black.withAlphaComponent(0.6)
        addSubview(loaddingView)
    }
    
    var progress: CGFloat = 0 {
        didSet {
            if loaddingView.isAnimating {
                loaddingView.stopAnimating()
            }
            if loaddingView.circleLayer.mask != nil {
                loaddingView.circleLayer.mask = nil
            }
            loaddingView.progress = progress
        }
    }
    
    func startAnimating() {
        loaddingView.resetMask()
        loaddingView.startAnimating()
    }
    
    func stopAnimating() {
        loaddingView.stopAnimating()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        loaddingView.center = .init(x: width / 2, y: height / 2)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
