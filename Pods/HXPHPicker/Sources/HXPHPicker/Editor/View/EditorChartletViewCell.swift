//
//  EditorChartletViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

class EditorChartletViewCell: UICollectionViewCell {
    lazy var selectedBgView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: effect)
        view.isHidden = true
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var imageView: ImageView = {
        let view = ImageView()
        view.imageView.contentMode = .scaleAspectFit
        return view
    }()
    var editorType: EditorController.EditorType = .photo
    var downloadCompletion = false
    
    var titleChartlet: EditorChartletTitle! {
        didSet {
            selectedBgView.isHidden = !titleChartlet.isSelected
            #if canImport(Kingfisher)
            setupImage(image: titleChartlet.image, url: titleChartlet.url)
            #else
            setupImage(image: titleChartlet.image)
            #endif
        }
    }
    
    var isSelectedTitle: Bool = false {
        didSet {
            titleChartlet.isSelected = isSelectedTitle
            selectedBgView.isHidden = !titleChartlet.isSelected
        }
    }
    
    var showSelectedBgView: Bool = false {
        didSet {
            selectedBgView.isHidden = !showSelectedBgView
        }
    }
    
    var chartlet: EditorChartlet! {
        didSet {
            selectedBgView.isHidden = true
            #if canImport(Kingfisher)
            setupImage(image: chartlet.image, url: chartlet.url)
            #else
            setupImage(image: chartlet.image)
            #endif
        }
    }
    
    func setupImage(image: UIImage?, url: URL? = nil) {
        downloadCompletion = false
        imageView.image = nil
        #if canImport(Kingfisher)
        if let image = image {
            imageView.image = image
            downloadCompletion = true
        }else if let url = url {
            imageView.my.kf.indicatorType = .activity
            (imageView.my.kf.indicator?.view as? UIActivityIndicatorView)?.color = .white
            let processor = DownsamplingImageProcessor(
                size: CGSize(
                    width: width * 2,
                    height: height * 2
                )
            )
            let options: KingfisherOptionsInfo
            if url.isGif && editorType == .video {
                options = [.memoryCacheExpiration(.expired)]
            }else {
                options = [
                    .cacheOriginalImage,
                    .processor(processor),
                    .backgroundDecode
                ]
            }
            imageView.my.kf.setImage(
                with: url,
                options: options
            ) { [weak self] result in
                switch result {
                case .success(_):
                    self?.downloadCompletion = true
                default:
                    break
                }
            }
        }
        #else
        if let image = image {
            imageView.image = image
        }
        #endif
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(selectedBgView)
        contentView.addSubview(imageView)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        selectedBgView.frame = bounds
        if titleChartlet != nil {
            imageView.size = CGSize(width: 25, height: 25)
            imageView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        }else {
            imageView.frame = CGRect(x: 5, y: 5, width: width - 10, height: height - 10)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
