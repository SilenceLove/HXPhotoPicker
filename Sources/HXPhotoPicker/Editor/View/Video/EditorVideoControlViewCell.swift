//
//  EditorVideoControlViewCell.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/13.
//

import UIKit

class EditorVideoControlViewCell: UICollectionViewCell {
    
    private var imageView: UIImageView!
    
    var image: UIImage? {
        didSet {
            guard let image else { return }
            imageView.setImage(image, animated: true)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        contentView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
}
