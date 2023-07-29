//
//  EditorMosaicToolView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/20.
//

import UIKit

protocol EditorMosaicToolViewDelegate: AnyObject {
    func mosaicToolView(
        _ mosaicToolView: EditorMosaicToolView,
        didChangedMosaicType type: EditorMosaicType
    )
    func mosaicToolView(
        didUndoClick mosaicToolView: EditorMosaicToolView
    )
}

class EditorMosaicToolView: UIView {
    weak var delegate: EditorMosaicToolViewDelegate?
    lazy var mosaicButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = "hx_editor_tool_mosaic_normal".image?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.setImage(image, for: .selected)
        button.addTarget(self, action: #selector(didMosaicClick(button:)), for: .touchUpInside)
        button.tintColor = .white
        button.isSelected = true
        button.imageView?.tintColor = selectedColor
        return button
    }()
    
    @objc func didMosaicClick(button: UIButton) {
        button.isSelected = true
        button.imageView?.tintColor = selectedColor
        smearButton.isSelected = false
        smearButton.imageView?.tintColor = nil
        delegate?.mosaicToolView(self, didChangedMosaicType: .mosaic)
    }
    lazy var smearButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = "hx_editor_tool_mosaic_color".image?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.setImage(image, for: .selected)
        button.addTarget(self, action: #selector(didSmearClick(button:)), for: .touchUpInside)
        button.tintColor = .white
        return button
    }()
    
    @objc func didSmearClick(button: UIButton) {
        button.isSelected = true
        button.imageView?.tintColor = selectedColor
        mosaicButton.isSelected = false
        mosaicButton.imageView?.tintColor = nil
        delegate?.mosaicToolView(self, didChangedMosaicType: .smear)
    }
    lazy var undoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage("hx_editor_brush_repeal".image, for: .normal)
        button.addTarget(self, action: #selector(didUndoClick(button:)), for: .touchUpInside)
        button.tintColor = .white
        button.isEnabled = false
        return button
    }()
    
    @objc func didUndoClick(button: UIButton) {
        delegate?.mosaicToolView(didUndoClick: self)
    }
    var canUndo: Bool = false {
        didSet {
            undoButton.isEnabled = canUndo
        }
    }
    var mosaicType: EditorMosaicType = .mosaic {
        didSet {
            if mosaicType == .mosaic {
                mosaicButton.isSelected = true
                mosaicButton.imageView?.tintColor = selectedColor
                smearButton.isSelected = false
                smearButton.imageView?.tintColor = nil
            }else {
                mosaicButton.isSelected = false
                mosaicButton.imageView?.tintColor = nil
                smearButton.isSelected = true
                smearButton.imageView?.tintColor = selectedColor
            }
        }
    }
    let selectedColor: UIColor
    init(selectedColor: UIColor) {
        self.selectedColor = selectedColor
        super.init(frame: .zero)
        addSubview(mosaicButton)
        addSubview(smearButton)
        addSubview(undoButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.isPortrait {
            let buttonWidth = (width - UIDevice.leftMargin - UIDevice.rightMargin - height) * 0.5
            mosaicButton.frame = CGRect(x: UIDevice.leftMargin, y: 0, width: buttonWidth, height: height)
            smearButton.frame = CGRect(x: mosaicButton.frame.maxX, y: 0, width: buttonWidth, height: height)
            undoButton.frame = CGRect(x: width - UIDevice.rightMargin - height, y: 0, width: height, height: height)
        }else {
            undoButton.frame = CGRect(x: 0, y: UIDevice.topMargin, width: width, height: 44)
            mosaicButton.frame = .init(
                x: 0,
                y: undoButton.frame.maxY,
                width: width,
                height: (height - undoButton.height) / 2
            )
            smearButton.frame = .init(
                x: 0,
                y: mosaicButton.frame.maxY,
                width: width,
                height: (height - undoButton.height) / 2
            )
        }
    }
}
