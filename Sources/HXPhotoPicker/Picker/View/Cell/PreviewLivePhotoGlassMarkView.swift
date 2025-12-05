//
//  PreviewLivePhotoGlassMarkView.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/12/2.
//  Copyright © 2025 Silence. All rights reserved.
//

import UIKit

@available(iOS 26.0, *)
protocol PreviewLivePhotoGlassMarkViewDelegate: AnyObject {
    func livePhotoGlsasMarkView(didLeftClick livePhotoGlsasMarkView: PreviewLivePhotoGlassMarkView)
    func livePhotoGlsasMarkView(didRightClick livePhotoGlsasMarkView: PreviewLivePhotoGlassMarkView)
}

@available(iOS 26.0, *)
class PreviewLivePhotoGlassMarkView: UIToolbar {
    
    weak var mark_delegate: PreviewLivePhotoGlassMarkViewDelegate?
    
    var leftItem: UIBarButtonItem!
    var leftBtn: UIButton!
    var rightItem: UIBarButtonItem!
    var rightBtn: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initViews() {
        leftBtn = ExpandButton(type: .system)
        var leftCfg = UIButton.Configuration.plain()
        leftCfg.background.backgroundColorTransformer = UIConfigurationColorTransformer { _ in .clear }
        leftCfg.background.visualEffect = nil
        leftCfg.contentInsets = .init(top: 2, leading: 5, bottom: 2, trailing: 5)
        leftCfg.baseForegroundColor = .label
        leftCfg.imagePadding = 4
        leftBtn.configuration = leftCfg
        leftBtn.setTitle(.textManager.picker.preview.livePhotoTitle.text, for: .normal)
        leftBtn.setImage(.init(systemName: "livephoto")?.withRenderingMode(.alwaysTemplate), for: .normal)
        leftBtn.setImage(.init(systemName: "livephoto.slash")?.withRenderingMode(.alwaysTemplate), for: .selected)
        leftBtn.addTarget(self, action: #selector(didLeftButtonClick), for: .touchUpInside)
        leftItem = .init(customView: leftBtn)
        
        rightBtn = ExpandButton(type: .system)
        var rightCfg = UIButton.Configuration.plain()
        rightCfg.background.backgroundColorTransformer = UIConfigurationColorTransformer { _ in .clear }
        rightCfg.background.visualEffect = nil
        rightCfg.baseForegroundColor = .label
        rightCfg.contentInsets = .init(top: 2, leading: 5, bottom: 2, trailing: 5)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 25, weight: .light, scale: .small)
        rightCfg.preferredSymbolConfigurationForImage = symbolConfig
        rightBtn.configuration = rightCfg
        let rightImage = UIImage(systemName: "speaker.wave.3.fill")?.withRenderingMode(.alwaysTemplate)
        let rightSelectedImage = UIImage(systemName: "speaker.slash.fill")?.withRenderingMode(.alwaysTemplate)
        rightBtn.setImage(rightImage, for: .normal)
        rightBtn.setImage(rightSelectedImage, for: .selected)
        rightBtn.addTarget(self, action: #selector(didRightButtonClick), for: .touchUpInside)
        rightItem = .init(customView: rightBtn)
    }
    
    var config: PreviewViewConfiguration.LivePhotoMark? {
        didSet {
            guard let config else { return }
            let flex = UIBarButtonItem.flexibleSpace()
            if config.allowShow, config.allowMutedShow {
                setItems([leftItem, flex, rightItem], animated: false)
            }else if config.allowShow {
                setItems([leftItem, flex], animated: false)
            }else if config.allowMutedShow {
                setItems([flex, rightItem], animated: false)
            }
        }
    }
    
    @objc
    func didLeftButtonClick() {
        mark_delegate?.livePhotoGlsasMarkView(didLeftClick: self)
    }
    
    @objc
    func didRightButtonClick() {
        mark_delegate?.livePhotoGlsasMarkView(didRightClick: self)
    }
}
