//
//  VideoEditorVolumeView.swift
//  HXPHPicker
//
//  Created by Slience on 2022/1/11.
//

import UIKit

protocol VideoEditorVolumeViewDelegate: AnyObject {
    func volumeView(didChanged volumeView: VideoEditorVolumeView)
}

class VideoEditorVolumeView: UIView {
    weak var delegate: VideoEditorVolumeViewDelegate?
    lazy var bgMaskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(false)
        return layer
    }()
    lazy var bgView: UIVisualEffectView = {
        let visualEffect = UIBlurEffect.init(style: .light)
        let view = UIVisualEffectView.init(effect: visualEffect)
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()

    lazy var musicTitleLb: UILabel = {
        let label = UILabel()
        label.text = "配乐".localized
        label.textColor = .white
        label.font = .systemFont(ofSize: 15)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    lazy var musicVolumeSlider: UISlider = {
        let slider = UISlider()
        let image = UIImage.image(for: .white, havingSize: .init(width: 15, height: 15), radius: 7.5)
        slider.setThumbImage(image, for: .normal)
        slider.setThumbImage(image, for: .highlighted)
        slider.value = 1
        slider.addTarget(
            self,
            action: #selector(sliderDidChanged(_:)),
            for: .valueChanged
        )
        return slider
    }()
    
    lazy var musicVolumeNumberLb: UILabel = {
        let label = UILabel()
        label.text = "100"
        label.textColor = .white
        label.font = .systemFont(ofSize: 15)
        return label
    }()
    
    lazy var originalTitleLb: UILabel = {
        let label = UILabel()
        label.text = "视频原声".localized
        label.textColor = .white
        label.font = .systemFont(ofSize: 15)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    lazy var originalVolumeSlider: UISlider = {
        let slider = UISlider()
        let image = UIImage.image(for: .white, havingSize: .init(width: 15, height: 15), radius: 7.5)
        slider.setThumbImage(image, for: .normal)
        slider.setThumbImage(image, for: .highlighted)
        slider.value = 1
        slider.addTarget(
            self,
            action: #selector(sliderDidChanged(_:)),
            for: .valueChanged
        )
        return slider
    }()
    
    lazy var originalVolumeNumberLb: UILabel = {
        let label = UILabel()
        label.text = "100"
        label.textColor = .white
        label.font = .systemFont(ofSize: 15)
        return label
    }()
    
    @objc
    func sliderDidChanged(_ slider: UISlider) {
        if slider == musicVolumeSlider {
            musicVolume = slider.value
        }else {
            originalVolume = slider.value
        }
        delegate?.volumeView(didChanged: self)
    }
    var hasOriginalSound: Bool = true {
        didSet {
            originalTitleLb.alpha = hasOriginalSound ? 1 : 0.3
            originalVolumeSlider.alpha = hasOriginalSound ? 1 : 0.3
            originalVolumeSlider.isUserInteractionEnabled = hasOriginalSound
            originalVolumeNumberLb.alpha = hasOriginalSound ? 1 : 0.3
        }
    }
    
    var originalVolume: Float = 1 {
        didSet {
            if oldValue == originalVolume { return }
            originalVolumeSlider.value = originalVolume
            originalVolumeNumberLb.text = String(Int(originalVolume * 100))
        }
    }
    
    var musicVolume: Float = 1 {
        didSet {
            if oldValue == musicVolume { return }
            musicVolumeSlider.value = musicVolume
            musicVolumeNumberLb.text = String(Int(musicVolume * 100))
        }
    }
    
    init(_ color: UIColor) {
        super.init(frame: .zero)
        layer.addSublayer(bgMaskLayer)
        addSubview(bgView)
        addSubview(musicTitleLb)
        addSubview(musicVolumeSlider)
        musicVolumeSlider.minimumTrackTintColor = color
        addSubview(musicVolumeNumberLb)
        addSubview(originalTitleLb)
        addSubview(originalVolumeSlider)
        originalVolumeSlider.minimumTrackTintColor = color
        addSubview(originalVolumeNumberLb)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bgMaskLayer.frame = CGRect(
            x: -UIDevice.leftMargin - 15,
            y: -20,
            width: width + UIDevice.leftMargin + UIDevice.rightMargin + 30,
            height: height + 40 + UIDevice.bottomMargin
        )
        bgView.frame = bounds
        
        musicTitleLb.x = 30
        musicTitleLb.y = 30
        musicTitleLb.width = musicTitleLb.textWidth
        musicTitleLb.height = musicTitleLb.textHeight
        
        musicVolumeNumberLb.frame = .init(x: width - 10 - 50, y: 0, width: 50, height: 20)
        musicVolumeNumberLb.centerY = musicTitleLb.centerY
        
        let sliderWidth: CGFloat = 130.0 / 375.0
        musicVolumeSlider.size = .init(width: UIScreen.main.bounds.width * sliderWidth, height: 20)
        musicVolumeSlider.x = musicVolumeNumberLb.x - 15 - musicVolumeSlider.width
        musicVolumeSlider.centerY = musicTitleLb.centerY
        
        if musicTitleLb.frame.maxX > musicVolumeSlider.x {
            musicTitleLb.width = musicVolumeSlider.x - musicTitleLb.x - 5
        }
        
        originalTitleLb.x = musicTitleLb.x
        originalTitleLb.y = musicTitleLb.frame.maxY + 30
        originalTitleLb.width = originalTitleLb.textWidth
        originalTitleLb.height = originalTitleLb.textHeight
        
        originalVolumeNumberLb.frame = .init(x: width - 10 - 50, y: 0, width: 50, height: 20)
        originalVolumeNumberLb.centerY = originalTitleLb.centerY
        
        originalVolumeSlider.size = musicVolumeSlider.size
        originalVolumeSlider.x = originalVolumeNumberLb.x - 15 - originalVolumeSlider.width
        originalVolumeSlider.centerY = originalTitleLb.centerY
        
        if originalTitleLb.frame.maxX > originalVolumeSlider.x {
            originalTitleLb.width = originalVolumeSlider.x - originalTitleLb.x - 5
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
