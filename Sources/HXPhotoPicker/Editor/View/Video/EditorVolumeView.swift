//
//  EditorVolumeView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/20.
//

import UIKit

protocol EditorVolumeViewDelegate: AnyObject {
    func volumeView(didChanged volumeView: EditorVolumeView)
}

class EditorVolumeView: UIView {
    weak var delegate: EditorVolumeViewDelegate?
    private var bgColorView: UIView!
    private var bgView: UIVisualEffectView!
    private var musicTitleLb: UILabel!
    private var musicVolumeSlider: UISlider!
    private var musicVolumeNumberLb: UILabel!
    private var originalTitleLb: UILabel!
    private var originalVolumeSlider: UISlider!
    private var originalVolumeNumberLb: UILabel!
    
    var hasOriginalSound: Bool = true {
        didSet {
            originalTitleLb.alpha = hasOriginalSound ? 1 : 0.3
            originalVolumeSlider.alpha = hasOriginalSound ? 1 : 0.3
            originalVolumeSlider.isUserInteractionEnabled = hasOriginalSound
            originalVolumeNumberLb.alpha = hasOriginalSound ? 1 : 0.3
        }
    }
    var hasMusic: Bool = true {
        didSet {
            musicTitleLb.alpha = hasMusic ? 1 : 0.3
            musicVolumeSlider.alpha = hasMusic ? 1 : 0.3
            musicVolumeSlider.isUserInteractionEnabled = hasMusic
            musicVolumeNumberLb.alpha = hasMusic ? 1 : 0.3
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
        
        bgColorView = UIView()
        bgColorView.backgroundColor = .black.withAlphaComponent(0.2)
        if #available(iOS 11.0, *) {
            bgColorView.cornersRound(radius: 12, corner: .allCorners)
        }
        addSubview(bgColorView)
        
        bgView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        bgView.layer.cornerRadius = 12
        bgView.layer.masksToBounds = true
        addSubview(bgView)
        
        musicTitleLb = UILabel()
        musicTitleLb.text = .textManager.editor.music.volumeMusicButtonTitle.text
        musicTitleLb.textColor = .white
        musicTitleLb.font = .textManager.editor.music.volumeMusicButtonTitleFont
        musicTitleLb.adjustsFontSizeToFitWidth = true
        addSubview(musicTitleLb)
        
        musicVolumeSlider = UISlider()
        let musicVolumeImage = UIImage.image(for: .white, havingSize: .init(width: 15, height: 15), radius: 7.5)
        musicVolumeSlider.setThumbImage(musicVolumeImage, for: .normal)
        musicVolumeSlider.setThumbImage(musicVolumeImage, for: .highlighted)
        musicVolumeSlider.value = 1
        musicVolumeSlider.addTarget(
            self,
            action: #selector(sliderDidChanged(_:)),
            for: .valueChanged
        )
        addSubview(musicVolumeSlider)
        musicVolumeSlider.minimumTrackTintColor = color
        
        musicVolumeNumberLb = UILabel()
        musicVolumeNumberLb.text = "100"
        musicVolumeNumberLb.textColor = .white
        musicVolumeNumberLb.font = .systemFont(ofSize: 15)
        addSubview(musicVolumeNumberLb)
        
        originalTitleLb = UILabel()
        originalTitleLb.text = .textManager.editor.music.volumeOriginalButtonTitle.text
        originalTitleLb.textColor = .white
        originalTitleLb.font = .textManager.editor.music.volumeOriginalButtonTitleFont
        originalTitleLb.adjustsFontSizeToFitWidth = true
        addSubview(originalTitleLb)
        
        originalVolumeSlider = UISlider()
        let originalVolumeImage = UIImage.image(for: .white, havingSize: .init(width: 15, height: 15), radius: 7.5)
        originalVolumeSlider.setThumbImage(originalVolumeImage, for: .normal)
        originalVolumeSlider.setThumbImage(originalVolumeImage, for: .highlighted)
        originalVolumeSlider.value = 1
        originalVolumeSlider.addTarget(
            self,
            action: #selector(sliderDidChanged(_:)),
            for: .valueChanged
        )
        addSubview(originalVolumeSlider)
        originalVolumeSlider.minimumTrackTintColor = color
        
        originalVolumeNumberLb = UILabel()
        originalVolumeNumberLb.text = "100"
        originalVolumeNumberLb.textColor = .white
        originalVolumeNumberLb.font = .systemFont(ofSize: 15)
        addSubview(originalVolumeNumberLb)
    }
    
    @objc
    private func sliderDidChanged(_ slider: UISlider) {
        if slider == musicVolumeSlider {
            musicVolume = slider.value
        }else {
            originalVolume = slider.value
        }
        delegate?.volumeView(didChanged: self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgColorView.frame = bounds
        bgView.frame = bounds
        
        musicTitleLb.x = 30
        musicTitleLb.y = 30
        musicTitleLb.width = musicTitleLb.textWidth
        musicTitleLb.height = musicTitleLb.textHeight
        
        musicVolumeNumberLb.frame = .init(x: width - 10 - 50, y: 0, width: 50, height: 20)
        musicVolumeNumberLb.centerY = musicTitleLb.centerY
        
        let sliderWidth: CGFloat = 130.0 / 375.0
        musicVolumeSlider.size = .init(width: UIDevice.screenSize.width * sliderWidth, height: 20)
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
        guard #available(iOS 11.0, *) else {
            bgColorView.cornersRound(radius: 12, corner: .allCorners)
            return
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
