//
//  EditorCropConfirmView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

protocol EditorCropConfirmViewDelegate: NSObjectProtocol {
    func cropConfirmView(didFinishButtonClick cropConfirmView: EditorCropConfirmView)
    func cropConfirmView(didResetButtonClick cropConfirmView: EditorCropConfirmView)
    func cropConfirmView(didCancelButtonClick cropConfirmView: EditorCropConfirmView)
}
extension EditorCropConfirmViewDelegate {
    func cropConfirmView(didResetButtonClick cropConfirmView: EditorCropConfirmView) {}
}
class EditorCropConfirmView: UIView {
    weak var delegate: EditorCropConfirmViewDelegate?
    var config: CropConfirmViewConfiguration
    var showReset: Bool
    lazy var maskLayer: CAGradientLayer = {
        let layer = CAGradientLayer.init()
        layer.contentsScale = UIScreen.main.scale
        let blackColor = UIColor.black
        layer.colors = [blackColor.withAlphaComponent(0).cgColor,
                        blackColor.withAlphaComponent(0.15).cgColor,
                        blackColor.withAlphaComponent(0.35).cgColor,
                        blackColor.withAlphaComponent(0.6).cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 0, y: 1)
        layer.locations = [0.15, 0.35, 0.6, 0.9]
        layer.borderWidth = 0.0
        return layer
    }()
    lazy var cancelButton: UIButton = {
        let cancelButton = UIButton.init(type: .custom)
        cancelButton.setTitle("取消".localized, for: .normal)
        cancelButton.titleLabel?.font = UIFont.mediumPingFang(ofSize: 16)
        cancelButton.layer.cornerRadius = 3
        cancelButton.layer.masksToBounds = true
        cancelButton.addTarget(self, action: #selector(didCancelButtonClick(button:)), for: .touchUpInside)
        return cancelButton
    }()
    
    lazy var finishButton: UIButton = {
        let finishButton = UIButton.init(type: .custom)
        finishButton.setTitle("完成".localized, for: .normal)
        finishButton.titleLabel?.font = UIFont.mediumPingFang(ofSize: 16)
        finishButton.layer.cornerRadius = 3
        finishButton.layer.masksToBounds = true
        finishButton.addTarget(self, action: #selector(didFinishButtonClick(button:)), for: .touchUpInside)
        return finishButton
    }()
    
    lazy var resetButton: UIButton = {
        let resetButton = UIButton.init(type: .custom)
        resetButton.setTitle("还原".localized, for: .normal)
        resetButton.titleLabel?.font = UIFont.mediumPingFang(ofSize: 16)
        resetButton.layer.cornerRadius = 3
        resetButton.layer.masksToBounds = true
        resetButton.addTarget(self, action: #selector(didResetButtonClick(button:)), for: .touchUpInside)
        return resetButton
    }()
    @objc func didFinishButtonClick(button: UIButton) {
        delegate?.cropConfirmView(didFinishButtonClick: self)
    }
    @objc func didResetButtonClick(button: UIButton) {
        delegate?.cropConfirmView(didResetButtonClick: self)
    }
    @objc func didCancelButtonClick(button: UIButton) {
        delegate?.cropConfirmView(didCancelButtonClick: self)
    }
    init(config: CropConfirmViewConfiguration, showReset: Bool = false) {
        self.showReset = showReset
        self.config = config
        super.init(frame: .zero)
        layer.addSublayer(maskLayer)
        addSubview(finishButton)
        if showReset {
            addSubview(resetButton)
        }
        addSubview(cancelButton)
        configColor()
    }
    func configColor() {
        let isDark = PhotoManager.isDark
        finishButton.setTitleColor(isDark ? config.finishButtonTitleDarkColor : config.finishButtonTitleColor, for: .normal)
        finishButton.setBackgroundImage(UIImage.image(for: isDark ? config.finishButtonDarkBackgroundColor : config.finishButtonBackgroundColor, havingSize: .zero), for: .normal)
        if showReset {
            resetButton.setTitleColor(isDark ? config.resetButtonTitleDarkColor : config.resetButtonTitleColor, for: .normal)
            resetButton.setTitleColor(resetButton.titleColor(for: .normal)?.withAlphaComponent(0.4), for: .disabled)
            resetButton.setBackgroundImage(UIImage.image(for: isDark ? config.resetButtonDarkBackgroundColor : config.resetButtonBackgroundColor, havingSize: .zero), for: .normal)
        }
        cancelButton.setTitleColor(isDark ? config.cancelButtonTitleDarkColor : config.cancelButtonTitleColor, for: .normal)
        cancelButton.setBackgroundImage(UIImage.image(for: isDark ? config.cancelButtonDarkBackgroundColor : config.cancelButtonBackgroundColor, havingSize: .zero), for: .normal)
        if (isDark && config.cancelButtonDarkBackgroundColor == nil) ||
            (!isDark && config.cancelButtonBackgroundColor == nil) {
            cancelButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        }else {
            cancelButton.titleEdgeInsets = .zero
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.frame = CGRect(x: 0, y: showReset ? -70 : -10, width: width, height: height + (showReset ? 70 : 10))
        cancelButton.x = UIDevice.leftMargin + 12
        var cancelWidth = (cancelButton.currentTitle?.width(ofFont: cancelButton.titleLabel!.font, maxHeight: 33) ?? 0) + 20
        if cancelWidth < 60 {
            cancelWidth = 60
        }
        cancelButton.width = cancelWidth
        cancelButton.height = 33
        cancelButton.centerY = 25
        
        var finishWidth = (finishButton.currentTitle?.width(ofFont: finishButton.titleLabel!.font, maxHeight: 33) ?? 0) + 20
        if finishWidth < 60 {
            finishWidth = 60
        }
        finishButton.width = finishWidth
        finishButton.height = 33
        finishButton.x = width - finishButton.width - 12 - UIDevice.rightMargin
        finishButton.centerY = 25
        
        if showReset {
            var resetWidth = (resetButton.currentTitle?.width(ofFont: resetButton.titleLabel!.font, maxHeight: 33) ?? 0) + 20
            if resetWidth < 60 {
                resetWidth = 60
            }
            resetButton.size = CGSize(width: resetWidth, height: 33)
            resetButton.centerX = width * 0.5
            resetButton.centerY = 25
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
